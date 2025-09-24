{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  networking.hostName = "webkiosk";
  networking.wireless = {
    enable = true;
    networks."UAP-LR".psk = "myPSK";
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  };
  networking.networkmanager.enable = false;
  
  time.timeZone = "America/Los_Angeles";

  # SSH for remote updates
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Disable X11 - Wayland only
  services.xserver.enable = false;

  # Input method support for virtual keyboards
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
  };

  # Greetd auto-login into sway
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "kiosk";
        command = "${pkgs.sway}/bin/sway";
      };
    };
  };

  # Kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "video" "audio" ];
    packages = with pkgs; [
      # User-specific packages
      squeekboard
      wvkbd
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    sway
    swaylock
    swayidle
    waybar          # Status bar
    wofi            # Application launcher
    chromium
    firefox
    
    # Virtual keyboards
    squeekboard
    wvkbd
    
    # Wayland utilities
    wl-clipboard    # Clipboard utilities
    grim            # Screenshot tool
    slurp           # Screen area selection
    
    # System utilities
    libinput
    bash
    curl
    git
    htop
    vim
  ];

  # Configure sway system-wide
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      wofi
      waybar
      squeekboard
      wvkbd
    ];
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_ENABLE_WAYLAND=1
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
    '';
  };

  # Sway configuration
  environment.etc."sway/config".text = ''
    # HMIOS Sway Kiosk Configuration
    
    # Variables
    set $mod Mod4
    set $left h
    set $down j
    set $up k
    set $right l
    set $term foot
    set $menu wofi --show drun

    # Output configuration
    output * bg #000000 solid_color

    # Input configuration for touch devices
    input type:touchscreen {
        tap enabled
        natural_scroll enabled
        drag enabled
        dwt enabled
    }

    input type:keyboard {
        xkb_layout "us"
    }

    # Key bindings

    # Start a terminal (disabled for kiosk)
    # bindsym $mod+Return exec $term

    # Kill focused window (disabled for kiosk)
    # bindsym $mod+Shift+q kill

    # Start your launcher (disabled for kiosk)
    # bindsym $mod+d exec $menu

    # Drag floating windows by holding down $mod and left mouse button.
    floating_modifier $mod normal

    # Reload the configuration file
    bindsym $mod+Shift+c reload

    # Exit sway (disabled for kiosk)
    # bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway?' -b 'Yes, exit sway' 'swaymsg exit'

    # Layout stuff:
    
    # Remove window borders and titles
    default_border none
    default_floating_border none
    hide_edge_borders both

    # Status Bar (minimal)
    bar {
        position bottom
        status_command while date +'%Y-%m-%d %I:%M:%S %p'; do sleep 1; done
        
        colors {
            statusline #ffffff
            background #323232
            inactive_workspace #32323200 #32323200 #5c5c5c
        }
        height 30
    }

    # Auto-start applications
    exec --no-startup-id squeekboard &
    exec chromium --kiosk --touch-events=enabled --force-device-scale-factor=1.2 http://localhost:3000

    # Virtual keyboard toggle
    bindsym $mod+space exec pkill -f squeekboard || squeekboard &

    # Allow F5 for refresh
    bindsym F5 exec wtype -k F5

    # Emergency exit (Ctrl+Alt+Delete)
    bindsym Ctrl+Alt+Delete exec systemctl reboot
  '';

  # Systemd user services for virtual keyboard
  systemd.user.services.squeekboard = {
    description = "Squeekboard virtual keyboard";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.squeekboard}/bin/squeekboard";
      Restart = "always";
      RestartSec = "5";
    };
    environment = {
      WAYLAND_DISPLAY = "wayland-0";
      XDG_RUNTIME_DIR = "/run/user/1000";
    };
  };

  # Alternative: wvkbd service (comment out squeekboard above if using this)
  # systemd.user.services.wvkbd = {
  #   description = "wvkbd virtual keyboard";
  #   wantedBy = [ "graphical-session.target" ];
  #   after = [ "graphical-session.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.wvkbd}/bin/wvkbd-mobintl --hidden";
  #     Restart = "always";
  #     RestartSec = "5";
  #   };
  #   environment = {
  #     WAYLAND_DISPLAY = "wayland-0";
  #     XDG_RUNTIME_DIR = "/run/user/1000";
  #   };
  # };

  # Enable udev rules for input devices
  services.udev.packages = with pkgs; [ 
    squeekboard
  ];

  # Sudo without password for kiosk user
  security.sudo.extraRules = [{
    users = [ "kiosk" ];
    commands = [
      { command = "ALL"; options = [ "NOPASSWD" ]; }
    ];
  }];

  # Enable polkit for user session management
  security.polkit.enable = true;
  
  # Font configuration for touch interfaces
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Noto Sans Mono" ];
      };
    };
  };

  system.stateVersion = "25.05";
}
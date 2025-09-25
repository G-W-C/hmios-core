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
    wvkbd    
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
      wvkbd
    ];
   extraSessionCommands = ''
      export PATH=$PATH:/run/current-system/sw/bin
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
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
    bindsym $mod+Return exec $term

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
    #exec_always wvkbd --hidden &
    # Auto-start applications
    exec chromium --touch-events=enabled   --ozone-platform=wayland  --enable-features=UseOzonePlatform,TextInputV3,TouchEvents  --force-device-scale-factor=0.8 http://water.data https://cityworksonline.com

    # Virtual keyboard toggle
    bindsym $mod+space exec pkill -x wvkbd-mobintl || wvkbd-mobintl --hidden &

    # Allow F5 for refresh
    bindsym F5 exec wtype -k F5

    # Emergency exit (Ctrl+Alt+Delete)
    bindsym Ctrl+Alt+Delete exec systemctl reboot
  '';

  systemd.user.services.wvkbd = {
    description = "Wayland Virtual Keyboard";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "/run/current-system/sw/bin/wvkbd-mobintl --hidden";
      Restart = "always";
    };
    environment = {
      WAYLAND_DISPLAY = "wayland-0";
      XDG_RUNTIME_DIR = "/run/user/1000";
      PATH = "/run/current-system/sw/bin";
    };
  };  
  # Enable udev rules for input devices
  services.udev.packages = with pkgs; [ 
    wvkbd
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
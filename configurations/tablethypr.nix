{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;

  # Pick a theme (defaults to "spinner")
  boot.plymouth.theme = "spinner"; 

  
  networking.hostName = "webkiosk";
  networking.wireless = {
    enable = true;
    networks."UAP-LR".psk = "psk";
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
        command = "${pkgs.sway}/bin/hyprland";
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
    
    plymouth
    hyperland
    hyprlandPlugins.hyprgrass
    waybar          # Status bar
    wofi            # Application launcher
    chromium
    firefox
    foot
    
    # Virtual keyboards
    wvkbd
    #kb support?
    fcitx5
    # System utilities
    libinput
    bash
    curl
    git
    htop
    vim
  ];

  # Configure sway system-wide
  programs.hyperland = {
    enable = true;
    package = hyperland;
  };


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

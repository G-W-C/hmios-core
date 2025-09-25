{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "webkiosk";
  networking.wireless = {
    enable = true;
    networks."UAP-LR".psk = "myPSK";
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  };
  networking.networkmanager.enable = false;

  time.timeZone = "America/Los_Angeles";

  # SSH access (root login enabled)
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "yes";
    PasswordAuthentication = true;
  };

  # Disable X11 services (Wayland only)
  services.xserver.enable = false;

  # Enable SDDM for auto-login
  services.sddm.enable = true;
  services.sddm.autoLogin.enable = true;
  services.sddm.autoLogin.user = "kiosk";

  # Kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "video" "audio" ];
    packages = with pkgs; [
      wvkbd
      fcitx5
      chromium
      firefox
      plasma5.kdePlasma5
      plasma5.kdeFrameworks.kdeGraphics
      plasma5.kdeApplications.konsole
    ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    wvkbd
    fcitx5
    chromium
    firefox
    plasma5.kdePlasma5
    plasma5.kdeApplications.konsole
  ];

  # Enable Wayland input method support
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
  };

  # Auto-start applications for kiosk user
  services.xserver.windowManager.plasma5.enable = true;

  # wvkbd service (runs hidden, toggled with panel button)
  systemd.user.services.wvkbd = {
    description = "wvkbd virtual keyboard";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wvkbd}/bin/wvkbd-mobintl --hidden";
      Restart = "always";
    };
  };

  # Polkit
  security.polkit.enable = true;

  # Fonts for touchscreen
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" ];
      sansSerif = [ "Noto Sans" ];
      monospace = [ "Noto Sans Mono" ];
    };
  };

  # Chromium launcher script (Wayland + text-input-v3)
  environment.etc."xdg/autostart/kiosk-chromium.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Chromium Kiosk
    Exec=chromium --ozone-platform=wayland --wayland-text-input-version=3 --enable-wayland-ime --enable-features=UseOzonePlatform,TextInputV3,TouchEvents --force-device-scale-factor=0.8 http://water.data https://cityworksonline.com
    X-GNOME-Autostart-enabled=true
  '';

  # Sudo without password for kiosk user
  security.sudo.extraRules = [{
    users = [ "kiosk" ];
    commands = [
      { command = "ALL"; options = [ "NOPASSWD" ]; }
    ];
  }];

  system.stateVersion = "25.05";
}

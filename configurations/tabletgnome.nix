{ config, pkgs, ... }:

{
    # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


  # Enable GNOME desktop environment
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  fileSystems = {
    "/" = {
      device = "/dev/sda2";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };

    # SSH access (root login enabled)
  services.openssh.enable = true;
  services.openssh.settings = {
    PermitRootLogin = "yes";
    PasswordAuthentication = true;
  };

  # Auto-login user "kiosk"
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "kiosk";

  # Create kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" ]; # optional
  };
  
  # network
  networking.networkmanager.enable = false;
  networking.hostName = "webkiosk";
  networking.wireless = {
    enable = true;
    networks."UAP-LR".psk = "psk";
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  };

  # GNOME Kiosk session (forces full-screen Chromium)
#  services.gnome.gnome-shell-extensions = with pkgs.gnomeExtensions; [
    # This pulls in extensions but we’ll run Chromium manually too
#  ];

  # Start Chromium in kiosk mode
  systemd.user.services.chromium-kiosk = {
    description = "Chromium in kiosk mode";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.chromium}/bin/chromium --kiosk --incognito https://example.com";
      Restart = "always";
    };
  };

  # GNOME on-screen keyboard (auto-popup on text fields)
  services.gnome.core-os-services.enable = true;
 systemd.user.services.enable-osk = {
  description = "Enable GNOME on-screen keyboard for kiosk";
  after = [ "graphical-session.target" ];
  wantedBy = [ "graphical-session.target" ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = ''
      su kiosk -c "gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true"
    '';
  };
};

  # Optional: trim GNOME down (no background apps, no extras)
#  environment.gnome.excludePackages = with pkgs.gnome; [
 #   gnome-terminal
  #  gedit
   # nautilus
   # epiphany
 # ];

  environment.systemPackages = with pkgs; [
    chromium
  ];

 
 system.stateVersion = "25.05"; # match your NixOS version

}

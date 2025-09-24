{ config, pkgs, lib, ... }:
#sway config
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "webkiosk";
  networking.hostName = "webkiosk";
  networking.wireless = {
    enable = true;
    networks."UAP-LR".psk = "myPSK";
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
    # output ends up in /run/wpa_supplicant/wpa_supplicant.conf
  };
  networking.networkmanager.enable = false;


  time.timeZone = "America/Los_Angeles";

  # SSH for remote updates
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  services.openssh.passwordAuthentication = true;

  services.xserver.enable = false; # Wayland only

  # Greetd auto-login into sway
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "kiosk";
        command = ''
          sway -c /etc/sway/kiosk.sway
        '';
      };
    };
  };

  # Kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "input" "video" "wheel" ];
    password = "";  # set a strong password
  };

  # Environment packages
  environment.systemPackages = with pkgs; [
    sway
    chromium
    wvkbd
    libinput
    networkmanager
    bash
    curl
    gzip
    coreutils
    findutils
    git
  ];

  # Virtual keyboard auto-start
  systemd.user.services.wvkbd = {
    description = "Wayland Virtual Keyboard";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.wvkbd}/bin/wvkbd-mobintl";
      Restart = "always";
    };
  };

  # Prevent switching TTYs accidentally
  security.sysctl = {
    "kernel.sysrq" = 0;
  };

  # Optional: allow reboot/shutdown without password
  security.sudo.extraRules = [{
    users = [ "kiosk" ];
    commands = [
      { command = "ALL"; options = [ "NOPASSWD" ]; }
    ];
  }];
}

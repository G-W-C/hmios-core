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
    # output ends up in /run/wpa_supplicant/wpa_supplicant.conf
  };
  networking.networkmanager.enable = false;


  time.timeZone = "America/Los_Angeles";

  services.xserver.enable = false; # No X11
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.cage}/bin/cage -s -- ${pkgs.chromium}/bin/chromium --kiosk https://example.com";
        user = "kiosk";
      };
    };
  };

  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" ];
    password = "";
  };

  # Security: auto-login for kiosk
  security.pam.services.greetd.enable = true;

  environment.systemPackages = with pkgs; [
    cage
    chromium
    networkmanager
  ];

  # Optional: allow reboot/shutdown without password
  security.sudo.extraRules = [{
    users = [ "kiosk" ];
    commands = [
      { command = "ALL"; options = [ "NOPASSWD" ]; }
    ];
  }];

  # This value determines the NixOS release
  system.stateVersion = "25.05";
}
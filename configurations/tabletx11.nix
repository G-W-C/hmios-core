{ config, pkgs, ... }:

{
  ##########################
  # System Basics
  ##########################

  system.stateVersion = "23.05";  # Adjust to your NixOS version

  # Timezone, hostname, etc.
  time.timeZone = "America/Los_Angeles";
  networking.hostName = "nixos-kiosk";

  # Networking
  networking.hostName = "webkiosk";
  networking.wireless = {
    enable = true;
    networks."UAP-LR".psk = "myPSK";
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  };
  networking.networkmanager.enable = false;


  ##########################
  # Users
  ##########################
  users.users.kiosk = {
    isNormalUser = true;
    description = "Kiosk user";
    extraGroups = [ "wheel" ];  # for sudo if needed
    password = "";               # empty for auto-login
  };

  ##########################
  # X11 / Window Manager
  ##########################
  services.xserver = {
    enable = true;
    layout = "us";
    xserver.windowManager.openbox.enable = true;

    # Auto-login kiosk user
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "kiosk";

    # Disable DPMS/screensaver to prevent blank screen
    displayManager.sessionCommands = ''
      xset s off
      xset -dpms
      xset s noblank
    '';
  };

  ##########################
  # Touchscreen / Input
  ##########################
  hardware.input = {
    touchscreen.enable = true;
    evdev.enable = true;
  };

  ##########################
  # System Packages
  ##########################
  environment.systemPackages = with pkgs; [
    chromium        # Browser
    onboard         # On-screen keyboard
    xinput_calibrator  # Optional: touchscreen calibration
  ];

  ##########################
  # Environment Variables for OSK / IME
  ##########################
  environment.variables = {
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
  };

  ##########################
  # Openbox Autostart
  ##########################
  # Create ~/.config/openbox/autostart with these commands:
  # Make sure this file exists for the kiosk user
  # You can also use NixOS home-manager to deploy it declaratively
  environment.etc."xdg/openbox/autostart".text = ''
    # Start the on-screen keyboard
    onboard &

    # Start Chromium in kiosk mode
    chromium --kiosk --no-first-run --disable-translate "http://water.data" &
  '';

  ##########################
  # Optional: Lockdown tweaks
  ##########################
  # Prevent switching TTYs
  security.pam.services.login.extraConfig = ''
    auth required pam_securetty.so
  '';
}

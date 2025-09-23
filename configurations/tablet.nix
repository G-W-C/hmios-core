# NixOS Tablet Browser Kiosk Configuration for SCADA HMI
{ config, pkgs, lib, ... }:

{
  # Boot configuration optimized for tablets
  boot = {
    initrd.availableKernelModules = [ 
      "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" 
      "rtsx_pci_sdmmc" "i915" "amdgpu" "radeon" # Graphics drivers
    ];
    kernelModules = [ "kvm-intel" "kvm-amd" "i915" "amdgpu" ];
    
    # Support for various tablet hardware
    kernelParams = [
      "quiet"
      "splash"
      "i915.fastboot=1"        # Faster boot on Intel graphics
      "intel_idle.max_cstate=1" # Better tablet performance
      "processor.max_cstate=1"
      "intel_pstate=disable"    # Better for some tablet CPUs
    ];
    
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3;  # Quick boot
    };
  };

  # Hardware support for tablets
  hardware = {
    # Graphics acceleration
    opengl = {
      enable = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver  # Intel graphics
        vaapiIntel         # Intel VA-API
        vaapiVdpau
        libvdpau-va-gl
        amdvlk            # AMD Vulkan
      ];
    };
    
    # Audio (tablets often have speakers)
#    pulseaudio = {
#      enable = true;
#      support32Bit = true;
#    };
    
    # Bluetooth for peripherals
#    bluetooth = {
#      enable = true;
#      powerOnBoot = true;
#    };
    
    # Enable firmware updates
    enableRedistributableFirmware = true;
  };

  # Power management for battery devices
#  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";  # Extend battery life
  };

  # TLP for advanced power management
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      
      # Screen brightness
      INTEL_GPU_MIN_FREQ_ON_AC = 200;
      INTEL_GPU_MIN_FREQ_ON_BAT = 200;
      INTEL_GPU_MAX_FREQ_ON_AC = 1100;
      INTEL_GPU_MAX_FREQ_ON_BAT = 800;
      
      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      
      # USB autosuspend
      USB_AUTOSUSPEND = 1;
      
      # Aggressive power saving on battery
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  # Enable X11 with touch support
  services.xserver = {
    enable = true;
    
    displayManager = {
      lightdm = {
        enable = true;
        autoLogin = {
          enable = true;
          user = "kiosk";
        };
        greeters.gtk = {
          enable = true;
          theme.name = "Adwaita-dark";
          cursorTheme.name = "Vanilla-DMZ";
          cursorTheme.size = 24;  # Larger cursor for touch
        };
      };
    };
    
    windowManager.i3.enable = true;
    desktopManager.xterm.enable = false;
    
    # Touch and input configuration
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = false;  # Keep active for kiosk use
      };
      # Touch screen settings
#      touchscreen = {
#        naturalScrolling = true;
#        tapping = true;
#      };
    };
    
    # Auto-detect displays (tablets may have rotation)
    autoRepeatDelay = 200;
    autoRepeatInterval = 30;
    
    # DPI scaling for small tablet screens
    dpi = 120;  # Adjust based on tablet screen size
    
    # Video drivers for common tablet hardware
    videoDrivers = [ "modesetting" "intel" "amdgpu" "radeon" ];
  };

  # Create kiosk user optimized for touch
  users.users.kiosk = {
    isNormalUser = true;
    description = "Tablet Kiosk User";
    extraGroups = [ "audio" "video" "input" "plugdev" ];
    hashedPassword = null;
    shell = "${pkgs.bash}/bin/bash";
  };

  # Create admin user for maintenance
  users.users.admin = {
    isNormalUser = true;
    description = "Admin User for Tablet Maintenance";
    extraGroups = [ "wheel" "networkmanager" "systemd-journal" "audio" "video" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your-key@hostname"
    ];
  };

  # Enable sudo for admin user
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Install packages optimized for tablet use
  environment.systemPackages = with pkgs; [
    # Browser optimized for touch
    firefox                # Primary browser
    chromium              # Alternative browser
    
    # Window manager and utilities
    i3                    # Window manager
    i3lock                # Screen locking
    rofi                  # Application launcher
    
    # Display and input tools
    xorg.xrandr          # Display configuration
    xorg.xinput          # Input device configuration
    xorg.xset            # X settings
    xdotool              # X automation
    unclutter            # Hide mouse cursor
    
    # Touch-optimized keyboard
    onboard              # On-screen keyboard
    matchbox-keyboard    # Alternative keyboard
    
    # System tools
    brightnessctl        # Screen brightness control
    playerctl            # Media control
    pavucontrol          # Audio control
    
    # Maintenance tools
    htop                 # Process monitor
    vim                  # Text editor  
    git                  # Version control
    curl wget            # Network tools
    tmux                 # Terminal multiplexer
    rsync                # File sync
    nmap                 # Network diagnostics
    
    # Tablet-specific tools
    acpi                 # Battery status
    powertop             # Power monitoring
    iotop                # I/O monitoring
    
    # Network tools
    networkmanager       # Network management
    networkmanagerapplet # GUI network manager
    
    # Git deployment tools
    jq                   # JSON processor
    openssh              # SSH client
    
    # Touch calibration (if needed)
    xinput_calibrator    # Touch calibration utility
  ];

  # Configure i3 for tablet kiosk mode
  environment.etc."i3-tablet-config" = {
    text = ''
      # i3 configuration for tablet kiosk mode
      
      # Remove window decorations
      new_window none
      new_float none
      
      # Hide window borders
      for_window [class=".*"] border none
      
      # Disable focus follows mouse (important for touch)
      focus_follows_mouse no
      mouse_warping none
      
      # Font for better visibility on tablets
      font pango:DejaVu Sans Mono 12
      
      # Start applications
      exec --no-startup-id xset s off
      exec --no-startup-id xset -dpms
      exec --no-startup-id xset s noblank
      exec --no-startup-id unclutter -idle 3 -jitter 2
      
      # Screen rotation support
      exec --no-startup-id xrandr --output eDP-1 --rotate normal
      
      # Start on-screen keyboard daemon (hidden by default)
      exec --no-startup-id onboard --not-show-in=GNOME,KDE
      
      # Start Firefox in kiosk mode with touch optimizations
      exec --no-startup-id firefox \
        --kiosk \
        --new-instance \
        --profile /tmp/firefox-tablet \
        --preferences='{
          "browser.cache.disk.enable": false,
          "browser.cache.memory.enable": true,
          "browser.sessionstore.resume_from_crash": false,
          "browser.shell.checkDefaultBrowser": false,
          "browser.startup.homepage": "about:blank",
          "dom.disable_beforeunload": true,
          "full-screen-api.ignore-widgets": true,
          "media.autoplay.default": 0,
          "security.sandbox.content.level": 1,
          "toolkit.legacyUserProfileCustomizations.stylesheets": true
        }' \
        "http://localhost:3000/dashboards|http://localhost:8088/data/perspective/client/HMI|http://localhost:8080/system/gateway/StatusAndDiagnostics_Overview"
      
      # Touch-friendly keyboard shortcuts
      bindsym F5 exec --no-startup-id xdotool key F5
      bindsym F11 exec --no-startup-id xdotool key F11
      
      # Screen rotation (for tablets that support it)
      bindsym Mod4+r exec --no-startup-id xrandr --output eDP-1 --rotate right
      bindsym Mod4+l exec --no-startup-id xrandr --output eDP-1 --rotate left  
      bindsym Mod4+n exec --no-startup-id xrandr --output eDP-1 --rotate normal
      bindsym Mod4+i exec --no-startup-id xrandr --output eDP-1 --rotate inverted
      
      # Brightness controls
      bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +5%
      bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%-
      
      # Volume controls
      bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%
      bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%
      bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle
      
      # Show/hide on-screen keyboard
      bindsym Mod4+k exec --no-startup-id onboard
      bindsym Mod4+Shift+k exec --no-startup-id pkill onboard
      
      # Emergency exit and restart
      bindsym Control+Mod1+Delete restart
      bindsym Control+Mod1+End exec --no-startup-id i3lock
      
      # Tab navigation (touch-friendly)
      bindsym Control+Tab exec --no-startup-id xdotool key ctrl+Tab
      bindsym Control+Shift+Tab exec --no-startup-id xdotool key ctrl+shift+Tab
      bindsym Control+1 exec --no-startup-id xdotool key ctrl+1
      bindsym Control+2 exec --no-startup-id xdotool key ctrl+2
      bindsym Control+3 exec --no-startup-id xdotool key ctrl+3
      
      # Touch gestures simulation
      bindsym --whole-window button4 exec --no-startup-id xdotool key ctrl+plus
      bindsym --whole-window button5 exec --no-startup-id xdotool key ctrl+minus
      
      # Disable most other shortcuts for security
      bindsym Mod1+Tab exec /bin/true
      bindsym Mod4+d exec /bin/true
      
      # Status bar (minimal for tablets)
      bar {
        status_command i3status
        position top
        height 30
        
        colors {
          background #000000
          statusline #ffffff
          separator #666666
          
          focused_workspace  #4c7899 #285577 #ffffff
          active_workspace   #333333 #5f676a #ffffff
          inactive_workspace #333333 #222222 #888888
        }
      }
    '';
  };

  # i3status configuration for tablets
  environment.etc."i3status.conf" = {
    text = ''
      # i3status configuration for tablets
      general {
        colors = true
        interval = 5
        color_good = "#a3be8c"
        color_degraded = "#ebcb8b"  
        color_bad = "#bf616a"
      }
      
      order += "wireless _first_"
      order += "ethernet _first_"
      order += "battery all"
      order += "load"
      order += "memory"
      order += "tztime local"
      
      wireless _first_ {
        format_up = "📶 %quality %essid %ip"
        format_down = "📶 down"
      }
      
      ethernet _first_ {
        format_up = "🔌 %ip (%speed)"
        format_down = "🔌 down"
      }
      
      battery all {
        format = "%status %percentage %remaining"
        format_down = "No battery"
        status_chr = "⚡"
        status_bat = "🔋"
        status_unk = "?"
        status_full = "☻"
        path = "/sys/class/power_supply/BAT%d/uevent"
        low_threshold = 10
      }
      
      load {
        format = "💻 %1min"
        max_threshold = 2
      }
      
      memory {
        format = "🧠 %used/%available"
        threshold_degraded = "1G"
        format_degraded = "MEMORY < %available"
      }
      
      tztime local {
        format = "📅 %Y-%m-%d 🕐 %H:%M:%S"
      }
    '';
  };

  # Firefox profile optimized for tablets
  environment.etc."firefox-tablet-user.js" = {
    text = ''
      // Firefox tablet optimization preferences
      user_pref("browser.gesture.swipe.left", "");
      user_pref("browser.gesture.swipe.right", "");
      user_pref("browser.gesture.tap", true);
      user_pref("dom.w3c_touch_events.enabled", 1);
      user_pref("layout.css.touch_action.enabled", true);
      user_pref("apz.gtk.kinetic_scroll.enabled", true);
      user_pref("mousewheel.min_line_scroll_amount", 40);
      user_pref("general.smoothScroll", true);
      user_pref("general.smoothScroll.pages", true);
      user_pref("mousewheel.system_scroll_override_on_root_content.enabled", true);
      
      // Performance optimizations
      user_pref("browser.cache.memory.capacity", 65536);
      user_pref("network.http.max-connections", 48);
      user_pref("network.http.max-persistent-connections-per-server", 16);
      user_pref("browser.sessionhistory.max_total_viewers", 2);
      
      // Kiosk mode settings
      user_pref("browser.chrome.site_icons", false);
      user_pref("browser.chrome.favicons", false);
      user_pref("browser.urlbar.suggest.searches", false);
      user_pref("browser.urlbar.suggest.bookmark", false);
      user_pref("browser.urlbar.suggest.history", false);
      user_pref("browser.download.panel.shown", false);
      
      // Touch-friendly UI
      user_pref("browser.tabs.remote.autostart", true);
      user_pref("layers.acceleration.force-enabled", true);
      user_pref("webgl.force-enabled", true);
    '';
  };

  # Configure kiosk user's environment
  environment.etc."xinitrc-tablet" = {
    text = ''
      #!/bin/sh
      
      # Tablet-specific initialization
      export QT_SCALE_FACTOR=1.2  # Better scaling for small screens
      export GDK_SCALE=1.2
      export GDK_DPI_SCALE=1.0
      
      # Set up Firefox profile for tablet
      mkdir -p /tmp/firefox-tablet
      cp /etc/firefox-tablet-user.js /tmp/firefox-tablet/user.js
      
      # Touch calibration (run once if needed)
      # xinput_calibrator --device "Your Touch Device"
      
      # Adjust mouse sensitivity for touch
      xinput set-prop "pointer:USB OPTICAL MOUSE" "libinput Accel Speed" 0.8
      
      # Start i3 with tablet configuration
      exec i3 -c /etc/i3-tablet-config
    '';
    mode = "0755";
  };

  # Network configuration for tablets
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        powersave = true;  # Battery optimization
      };
    };
    wireless.enable = lib.mkForce false;  # Use NetworkManager instead
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 3000 8080 8088 ];
    };
    hostName = "tablet-scada-kiosk";
  };

  # SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = true;
      AllowUsers = [ "admin" "kiosk" ];
    };
    openFirewall = true;
  };

  # Tablet maintenance script
  environment.etc."tablet-maintenance.sh" = {
    text = ''
      #!/bin/bash
      # Tablet kiosk maintenance script
      
      case "$1" in
        restart-kiosk)
          sudo systemctl restart display-manager
          ;;
        restart-browser)
          pkill firefox || pkill chromium
          sleep 3
          sudo -u kiosk DISPLAY=:0 i3-msg restart
          ;;
        rotate-screen)
          case "$2" in
            normal|right|left|inverted)
              DISPLAY=:0 xrandr --output eDP-1 --rotate "$2"
              ;;
            *)
              echo "Usage: $0 rotate-screen {normal|right|left|inverted}"
              exit 1
              ;;
          esac
          ;;
        calibrate-touch)
          sudo -u kiosk DISPLAY=:0 xinput_calibrator
          ;;
        battery-status)
          echo "=== Battery Information ==="
          acpi -b
          echo "=== Power Consumption ==="
          cat /sys/class/power_supply/BAT*/power_now 2>/dev/null || echo "N/A"
          echo "=== CPU Temperature ==="
          sensors 2>/dev/null | grep -i temp || echo "Install lm-sensors"
          ;;
        tablet-status)
          echo "=== Tablet System Status ==="
          acpi -b
          echo "=== Screen Brightness ==="
          brightnessctl get
          echo "=== WiFi Status ==="
          nmcli dev wifi
          echo "=== Touch Devices ==="
          xinput list | grep -i touch
          echo "=== Browser Process ==="
          pgrep -fl "firefox\|chromium"
          ;;
        update-config)
          sudo nixos-rebuild switch
          ;;
        git-deploy)
          /etc/git-deploy.sh "$2"
          ;;
        check-status)
          echo "=== System Status ==="
          systemctl status display-manager
          echo "=== Browser Process ==="
          pgrep -fl "firefox\|chromium"
          echo "=== Network Status ==="
          nmcli connection show --active
          echo "=== Git Status ==="
          cd /etc/nixos && git status
          ;;
        logs)
          journalctl -u display-manager -n 50
          ;;
        *)
          echo "Usage: $0 {restart-kiosk|restart-browser|rotate-screen|calibrate-touch|battery-status|tablet-status|update-config|git-deploy|check-status|logs}"
          exit 1
          ;;
      esac
    '';
    mode = "0755";
  };

  # System configuration for tablet kiosk
  system.activationScripts.setupTabletKiosk = ''
    # Create kiosk user home directory
    mkdir -p /home/kiosk
    chown kiosk:users /home/kiosk
    chmod 755 /home/kiosk
    
    # Link tablet xinitrc
    ln -sf /etc/xinitrc-tablet /home/kiosk/.xinitrc
    chown kiosk:users /home/kiosk/.xinitrc
    
    # Create Firefox config directory
    mkdir -p /home/kiosk/.mozilla/firefox
    chown -R kiosk:users /home/kiosk/.mozilla
    
    # Set up brightness control permissions
    chmod 666 /sys/class/backlight/*/brightness 2>/dev/null || true
  '';

  # Git deployment script (same as other configs but with tablet considerations)
  environment.etc."git-deploy.sh" = {
    text = ''
      #!/bin/bash
      # Git deployment script for tablets
      
      set -e
      
      CONFIG_REPO="''${1:-/etc/nixos}"
      LOG_FILE="/var/log/git-deploy.log"
      BACKUP_DIR="/etc/nixos-backups"
      
      log() {
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
      }
      
      # Check battery level before major operations
      check_battery() {
          BATTERY_LEVEL=$(acpi -b | grep -oP '\d+(?=%)' | head -1)
          if [ "$BATTERY_LEVEL" -lt 20 ]; then
              log "Warning: Low battery ($BATTERY_LEVEL%). Consider plugging in charger."
              sleep 5
          fi
      }
      
      cd "$CONFIG_REPO" || exit 1
      
      case "''${2:-pull}" in
        pull)
          log "Starting Git deployment on tablet"
          check_battery
          
          # Standard deployment process with tablet considerations
          mkdir -p "$BACKUP_DIR"
          BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
          cp -r /etc/nixos "$BACKUP_DIR/$BACKUP_NAME"
          log "Backup created: $BACKUP_DIR/$BACKUP_NAME"
          
          git fetch origin
          
          CURRENT_COMMIT=$(git rev-parse HEAD)
          REMOTE_COMMIT=$(git rev-parse origin/main || git rev-parse origin/master)
          
          if [ "$CURRENT_COMMIT" = "$REMOTE_COMMIT" ]; then
              log "Already up to date"
              exit 0
          fi
          
          log "Updating tablet from $CURRENT_COMMIT to $REMOTE_COMMIT"
          git pull origin main || git pull origin master
          
          # Test configuration
          log "Testing new configuration (tablet may be slower)"
          if timeout 900 nixos-rebuild test; then  # 15 minute timeout for tablets
              log "Configuration test successful, applying changes"
              nixos-rebuild switch
              log "Tablet deployment completed successfully"
              
              systemctl restart display-manager
              log "Kiosk display restarted"
          else
              log "Configuration test failed, rolling back"
              git reset --hard "$CURRENT_COMMIT"
              exit 1
          fi
          ;;
        *)
          echo "Standard Git operations same as other platforms"
          ;;
      esac
    '';
    mode = "0755";
  };

  # Tablet site configuration
  environment.etc."nixos/site-config.nix" = {
    text = ''
      # Tablet-specific site configuration
      {
        site = {
          name = "tablet-kiosk";
          location = "Mobile Station";
          device_type = "tablet";
          
          # Tablet-optimized URLs with touch-friendly interfaces
          dashboards = {
            grafana = "http://localhost:3000/dashboards";
            ignition_hmi = "http://localhost:8088/data/perspective/client/TouchHMI";
            ignition_gateway = "http://localhost:8080/system/gateway/StatusAndDiagnostics_Overview";
          };
          
          # Network configuration
          network = {
            hostname = "tablet-scada-kiosk";
            prefer_wifi = true;
          };
          
          # Tablet display settings
          display = {
            dpi = 120;
            rotation = "normal";  # normal, right, left, inverted
            brightness = "auto";
          };
          
          # Touch and input settings
          input = {
            touch_enabled = true;
            virtual_keyboard = true;
            gesture_support = true;
          };
          
          # Power management
          power = {
            battery_optimization = true;
            auto_brightness = true;
            wifi_power_save = true;
          };
        };
      }
    '';
  };

  # Services configuration
  services.journald = {
    extraConfig = ''
      Storage=persistent
      MaxRetentionSec=3d
      SystemMaxUse=500M
    '';
  };

  # Auto-sync with longer intervals for battery life
  systemd.services.config-sync = {
    description = "Sync tablet configuration from Git";
    path = with pkgs; [ git nixos-rebuild coreutils acpi ];
    script = ''
      # Check battery before sync
      BATTERY_LEVEL=$(acpi -b | grep -oP '\d+(?=%)' | head -1)
      if [ "$BATTERY_LEVEL" -gt 30 ]; then
        /etc/git-deploy.sh /etc/nixos pull
      else
        echo "Skipping sync due to low battery ($BATTERY_LEVEL%)"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      TimeoutStartSec = "20min";
    };
  };

  systemd.timers.config-sync = {
    description = "Timer for tablet configuration sync";
    timerConfig = {
      OnCalendar = "*:0/180";  # Every 3 hours for battery life
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # Git configuration
  environment.etc."gitconfig" = {
    text = ''
      [user]
          name = NixOS Tablet Kiosk
          email = tablet-kiosk@company.local
      [pull]
          rebase = false
      [init]
          defaultBranch = main
      [safe]
          directory = /etc/nixos
    '';
    target = "gitconfig";
  };

  # Time zone and locale
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # This value determines the NixOS release
  system.stateVersion = "23.11";
}
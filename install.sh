#!/bin/bash
# HMIOS Installer v1.0.0
# The HMI Operating System - Bringing Linux to Industrial HMIs
# https://github.com/G-W-C/hmios-core

set -e

# Configuration
REPO_URL="https://raw.githubusercontent.com/G-W-C/hmios-core/main"
HMIOS_VERSION="1.0.0"
INSTALL_LOG="/tmp/hmios-install.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[HMIOS]${NC} $1" | tee -a "$INSTALL_LOG"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$INSTALL_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$INSTALL_LOG"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$INSTALL_LOG"
}

banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║                     HMIOS                          ║"
    echo "║            The HMI Operating System                ║"
    echo "║         Bringing Linux to Industrial HMIs          ║"
    echo "║                   v${HMIOS_VERSION}                ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    echo -e "${CYAN}Industrial Computing, Reimagined${NC}"
    echo
}

check_environment() {
    log "Checking installation environment..."
    
    # Check if we're in NixOS installer
    if ! command -v nixos-install &> /dev/null; then
        error "This script must be run from NixOS installer environment"
    fi
    
    # Check if running as root or with sudo access
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        error "This script requires root privileges. Run with sudo or as root."
    fi
    
    # Check if /mnt is mounted
    if ! mountpoint -q /mnt 2>/dev/null; then
        error "/mnt is not mounted. Please partition and mount your disk first."
    fi
    
    # Check network connectivity
    if ! curl -s --connect-timeout 10 https://github.com >/dev/null; then
        error "Network connectivity required for installation"
    fi
    
    log "✅ Environment checks passed"
}

show_disk_help() {
    echo
    echo -e "${YELLOW}💡 Quick disk setup guide:${NC}"
    echo "1. List disks: lsblk"
    echo "2. Partition disk: sudo fdisk /dev/sda"
    echo "   - Type 'g' for GPT table"
    echo "   - Type 'n' for new partition (boot): +512M, type 1 (EFI)"
    echo "   - Type 'n' for new partition (root): remaining space"
    echo "   - Type 'w' to write changes"
    echo "3. Format partitions:"
    echo "   sudo mkfs.fat -F 32 -n boot /dev/sda1"
    echo "   sudo mkfs.ext4 -L nixos /dev/sda2"
    echo "4. Mount filesystems:"
    echo "   sudo mount /dev/disk/by-label/nixos /mnt"
    echo "   sudo mkdir -p /mnt/boot"
    echo "   sudo mount /dev/disk/by-label/boot /mnt/boot"
    echo "5. Run installer again!"
    echo
}

select_hardware_profile() {
    log "Detecting hardware profile..."
    
    echo -e "${CYAN}Select your hardware type:${NC}"
    echo "1) 💻 x86 Desktop/Industrial PC (recommended)"
    echo "2) 📱 Tablet/Laptop with touch screen"
    echo "3) 🍓 Raspberry Pi 4"
    echo "4) ⚙️  Custom/Other hardware"
    echo
    
    while true; do
        read -p "Enter choice (1-4): " HW_CHOICE
        case $HW_CHOICE in
            1) HW_PROFILE="x86-industrial"; break ;;
            2) HW_PROFILE="tablet"; break ;;
            3) HW_PROFILE="raspberry-pi"; break ;;
            4) HW_PROFILE="custom"; break ;;
            *) warn "Invalid choice. Please enter 1-4." ;;
        esac
    done
    
    log "Selected hardware profile: $HW_PROFILE"
}

configure_site() {
    log "Configuring site-specific settings..."
    echo
    
    # Site identification
    read -p "🏭 Site name (e.g., factory-1, plant-a): " SITE_NAME
    SITE_NAME=${SITE_NAME:-"hmios-site"}
    
    read -p "🖥️  Hostname (e.g., hmios-kiosk-01): " HOSTNAME
    HOSTNAME=${HOSTNAME:-"hmios-kiosk"}
    
    # Dashboard URLs
    echo
    echo -e "${CYAN}Configure dashboard URLs:${NC}"
    
    read -p "📊 Grafana URL (default: http://localhost:3000): " GRAFANA_URL
    GRAFANA_URL=${GRAFANA_URL:-"http://localhost:3000"}
    
    read -p "🏭 Ignition HMI URL (default: http://localhost:8088): " IGNITION_URL  
    IGNITION_URL=${IGNITION_URL:-"http://localhost:8088"}
    
    read -p "⚙️  Additional dashboard URL (optional): " ADDITIONAL_URL
    
    # Network configuration
    echo
    echo -e "${CYAN}Network configuration:${NC}"
    echo "1) DHCP (automatic IP)"
    echo "2) Static IP"
    
    read -p "Select network mode (1-2, default: 1): " NET_MODE
    NET_MODE=${NET_MODE:-1}
    
    if [ "$NET_MODE" = "2" ]; then
        read -p "Static IP address: " STATIC_IP
        read -p "Gateway: " GATEWAY
        read -p "DNS server (default: 8.8.8.8): " DNS_SERVER
        DNS_SERVER=${DNS_SERVER:-"8.8.8.8"}
    fi
    
    log "✅ Site configuration completed"
}

install_hmios_base() {
    log "Installing HMIOS base configuration..."
    
    # Generate hardware configuration
    info "Generating hardware configuration..."
    nixos-generate-config --root /mnt
    
    # Backup original configuration
    if [ -f /mnt/etc/nixos/configuration.nix ]; then
        cp /mnt/etc/nixos/configuration.nix /mnt/etc/nixos/configuration.nix.backup
    fi
    
    # Download HMIOS base configuration
    info "Downloading HMIOS configuration for $HW_PROFILE..."
    
    # Create the basic HMIOS configuration
    cat > /mnt/etc/nixos/configuration.nix << 'EOF'
# HMIOS Configuration - The HMI Operating System
# Generated by HMIOS installer
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.hostName = "HOSTNAME_PLACEHOLDER";
  networking.networkmanager.enable = true;

  # Locale and timezone
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable X11 and display manager
  services.xserver = {
    enable = true;
    displayManager = {
      lightdm = {
        enable = true;
        autoLogin = {
          enable = true;
          user = "kiosk";
        };
      };
    };
    windowManager.i3.enable = true;
    desktopManager.xterm.enable = false;
  };

  # Create kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    description = "HMIOS Kiosk User";
    extraGroups = [ "audio" "video" "networkmanager" ];
    hashedPassword = null;
  };

  # Create admin user
  users.users.admin = {
    isNormalUser = true;
    description = "HMIOS Administrator";
    extraGroups = [ "wheel" "networkmanager" "systemd-journal" ];
  };

  # Enable sudo without password for wheel group
  security.sudo.wheelNeedsPassword = false;

  # System packages
  environment.systemPackages = with pkgs; [
    firefox-esr     # Browser for HMI
    git            # Version control
    vim            # Text editor
    htop           # System monitor
    curl           # Network tool
    wget           # File downloader
    tmux           # Terminal multiplexer
    rsync          # File sync
  ];

  # SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # Change after setup
      PermitRootLogin = "no";
      X11Forwarding = true;
    };
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 3000 8080 8088 ];
  };

  # HMIOS version info
  environment.etc."hmios-version".text = ''
    HMIOS_VERSION
    Installed: INSTALL_DATE
    Site: SITE_NAME
    Hardware: HW_PROFILE
  '';

  system.stateVersion = "23.11";
}
EOF
    
    log "✅ HMIOS configuration created"
}

customize_configuration() {
    log "Customizing configuration for your site..."
    
    # Replace placeholders in configuration
    sed -i "s/HOSTNAME_PLACEHOLDER/$HOSTNAME/g" /mnt/etc/nixos/configuration.nix
    sed -i "s/HMIOS_VERSION/$HMIOS_VERSION/g" /mnt/etc/nixos/configuration.nix
    sed -i "s/INSTALL_DATE/$(date -Iseconds)/g" /mnt/etc/nixos/configuration.nix
    sed -i "s/SITE_NAME/$SITE_NAME/g" /mnt/etc/nixos/configuration.nix
    sed -i "s/HW_PROFILE/$HW_PROFILE/g" /mnt/etc/nixos/configuration.nix
    
    # Create site-specific configuration
    mkdir -p /mnt/etc/hmios
    
    cat > /mnt/etc/hmios/site-config.json << EOF
{
  "version": "$HMIOS_VERSION",
  "site": {
    "name": "$SITE_NAME",
    "hostname": "$HOSTNAME",
    "hardware_profile": "$HW_PROFILE",
    "install_date": "$(date -Iseconds)"
  },
  "dashboards": {
    "grafana": "$GRAFANA_URL",
    "ignition": "$IGNITION_URL",
    "additional": "$ADDITIONAL_URL"
  },
  "network": {
    "mode": "$([ "$NET_MODE" = "2" ] && echo "static" || echo "dhcp")",
    "static_ip": "$STATIC_IP",
    "gateway": "$GATEWAY", 
    "dns": "$DNS_SERVER"
  }
}
EOF
    
    log "✅ Configuration customized for $SITE_NAME"
}

create_kiosk_config() {
    log "Creating kiosk browser configuration..."
    
    # Create i3 kiosk configuration
    mkdir -p /mnt/etc/hmios/i3
    
    cat > /mnt/etc/hmios/i3/config << 'EOF'
# HMIOS i3 Kiosk Configuration

# Remove window decorations
new_window none
new_float none
for_window [class=".*"] border none

# Disable focus follows mouse
focus_follows_mouse no

# Start applications
exec --no-startup-id xset s off
exec --no-startup-id xset -dpms  
exec --no-startup-id xset s noblank

# Start Firefox in kiosk mode
exec --no-startup-id firefox --kiosk GRAFANA_URL_PLACEHOLDER

# Disable most shortcuts for security
bindsym Mod1+Tab exec /bin/true
bindsym Mod4+d exec /bin/true

# Allow F5 for refresh and F11 for fullscreen
bindsym F5 exec --no-startup-id xdotool key F5
bindsym F11 exec --no-startup-id xdotool key F11

# Emergency exit (Ctrl+Alt+Del)
bindsym Control+Mod1+Delete restart
EOF
    
    # Replace dashboard URL
    sed -i "s|GRAFANA_URL_PLACEHOLDER|$GRAFANA_URL|g" /mnt/etc/hmios/i3/config
    
    log "✅ Kiosk configuration created"
}

install_system() {
    log "Installing NixOS with HMIOS configuration..."
    warn "This will take 10-30 minutes depending on network speed..."
    echo
    
    # Set a temporary root password
    info "Setting temporary root password..."
    echo -e "hmios123\nhmios123" | chroot /mnt passwd root
    
    # Install NixOS
    if nixos-install --no-root-passwd 2>&1 | tee -a "$INSTALL_LOG"; then
        log "✅ NixOS installation completed successfully"
    else
        error "❌ NixOS installation failed. Check $INSTALL_LOG for details"
    fi
}

create_management_tools() {
    log "Installing HMIOS management tools..."
    
    # Create HMIOS status script
    cat > /mnt/usr/local/bin/hmios-status << 'EOF'
#!/bin/bash
# HMIOS System Status Check

echo "=== HMIOS System Status ==="
echo "Version: $(cat /etc/hmios-version | head -1)"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"

echo
echo "=== Services ==="
systemctl is-active display-manager || echo "Display manager: INACTIVE"
systemctl is-active sshd || echo "SSH: INACTIVE"  
systemctl is-active NetworkManager || echo "Network: INACTIVE"

echo  
echo "=== Browser Process ==="
pgrep -fl firefox || echo "No Firefox process found"

echo
echo "=== Network ==="
ip -4 addr show | grep -E "inet.*global" || echo "No network interfaces"

echo
echo "=== Dashboard URLs ==="
if [ -f /etc/hmios/site-config.json ]; then
    grep -A 5 '"dashboards"' /etc/hmios/site-config.json
fi
EOF
    
    chmod +x /mnt/usr/local/bin/hmios-status
    
    # Create update script placeholder
    cat > /mnt/usr/local/bin/hmios-update << 'EOF'
#!/bin/bash
echo "HMIOS Update functionality coming soon!"
echo "For now, use: sudo nixos-rebuild switch"
EOF
    
    chmod +x /mnt/usr/local/bin/hmios-update
    
    log "✅ Management tools installed"
}

finalize_installation() {
    log "Finalizing HMIOS installation..."
    
    # Create first-boot setup script
    cat > /mnt/etc/hmios/first-boot.sh << 'EOF'
#!/bin/bash
# HMIOS First Boot Setup

clear
echo "🎉 Welcome to HMIOS - The HMI Operating System!"
echo
echo "Your industrial HMI system is ready!"
echo
echo "📋 First-time setup:"
echo "1. Set admin password: sudo passwd admin"
echo "2. Add SSH keys for secure access"
echo "3. Customize dashboard URLs in /etc/hmios/site-config.json"
echo
echo "💡 Useful commands:"
echo "  hmios-status     - Check system status"
echo "  sudo systemctl restart display-manager  - Restart kiosk"
echo
echo "🌐 Documentation: https://github.com/G-W-C/hmios-core"
echo

# Remove first-boot script after running
rm /etc/hmios/first-boot.sh
EOF
    
    chmod +x /mnt/etc/hmios/first-boot.sh
    
    # Add first-boot to admin user's profile
    echo '[ -f /etc/hmios/first-boot.sh ] && /etc/hmios/first-boot.sh' >> /mnt/home/admin/.bashrc
    
    log "✅ HMIOS installation finalized"
}

show_completion() {
    clear
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════╗"
    echo "║              HMIOS Installation Complete!          ║"
    echo "╚════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    echo -e "${CYAN}🎉 Your industrial HMI system is ready!${NC}"
    echo
    echo -e "${YELLOW}📋 Installation Summary:${NC}"
    echo "   Site: $SITE_NAME"
    echo "   Hostname: $HOSTNAME"
    echo "   Hardware: $HW_PROFILE"
    echo "   Primary Dashboard: $GRAFANA_URL"
    if [ -n "$IGNITION_URL" ]; then
        echo "   Ignition HMI: $IGNITION_URL"
    fi
    echo
    echo -e "${YELLOW}🚀 Next Steps:${NC}"
    echo "1. Remove USB drive and reboot"
    echo "2. Login as admin (initial password will be prompted)"
    echo "3. Set up SSH keys for secure access"
    echo "4. Access your dashboards - they'll load automatically!"
    echo
    echo -e "${YELLOW}💡 Useful Commands:${NC}"
    echo "   hmios-status                    - Check system status"
    echo "   sudo systemctl restart display-manager  - Restart kiosk"
    echo "   sudo nixos-rebuild switch --rollback    - Emergency rollback"
    echo
    echo -e "${YELLOW}🔧 Default Login:${NC}"
    echo "   Username: admin"
    echo "   Temporary root password: hmios123 (change immediately!)"
    echo
    echo -e "${YELLOW}🌐 Support & Documentation:${NC}"
    echo "   Repository: https://github.com/G-W-C/hmios-core"
    echo "   Issues: https://github.com/G-W-C/hmios-core/issues"
    echo
    echo -e "${PURPLE}Welcome to the future of industrial computing! 🏭⚡${NC}"
    echo
    
    read -p "Press Enter to continue..."
}

# Main installation flow
main() {
    # Check if help requested
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        banner
        echo "HMIOS Installer - The HMI Operating System"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "This installer transforms a minimal NixOS system into a"
        echo "complete industrial HMI kiosk with browser-based dashboards."
        echo
        echo "Prerequisites:"
        echo "1. Boot from NixOS minimal ISO"
        echo "2. Partition and mount disk to /mnt"
        echo "3. Ensure network connectivity"
        echo
        show_disk_help
        exit 0
    fi
    
    # Run installation
    banner
    
    # Check if disk is not mounted and offer help
    if ! mountpoint -q /mnt 2>/dev/null; then
        error "Disk not mounted to /mnt. Run with --help for setup instructions."
    fi
    
    check_environment
    select_hardware_profile
    configure_site
    install_hmios_base
    customize_configuration
    create_kiosk_config
    install_system
    create_management_tools
    finalize_installation
    show_completion
}

# Handle script interruption
trap 'echo -e "\n${RED}Installation interrupted!${NC}"; exit 1' INT

# Run the installer
main 
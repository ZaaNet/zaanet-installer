#!/bin/bash
set -e
# ============================================================
#  ZaaNet Captive Portal Auto-Installer (Bundled)
#  Generated build — Do not edit manually.
# ============================================================

#!/bin/bash
# ZaaNet Captive Portal Auto-Installer
# One-command setup for Raspberry Pi 4+
# curl -sSL https://get.zaanet.xyz | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Auto-Configuration (No user input required)
ZAANET_DIR="/opt/zaanet"
ZAANET_USER="zaanet"
GITHUB_REPO="https://github.com/ZaaNet/public-release-v1.0.0.git"

# Network Configuration (Works for all installations)
WIFI_SSID="ZaaNet-Portal"
PORTAL_IP="192.168.100.1"
DHCP_START="192.168.100.100"
DHCP_END="192.168.100.200"
DNS_SERVER="8.8.8.8"
PORTAL_DOMAIN="portal.zaanet.xyz"
PORTAL_PORT="80"
MAIN_SERVER_URL="https://www.zaanet.xyz"

# Determine script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="${SCRIPT_DIR}/functions"

# Source all function files
source_functions() {
    local functions_to_load=(
        "auto_detect_interfaces.sh"
        "check_device_compatibility.sh"
        "configure_auto_start.sh"
        "configure_network_services.sh"
        "create_management_commands.sh"
        "create_system_user.sh"
        "create_systemd_services.sh"
        "create_switcher_script.sh"      # New
        "create_firewall_script.sh"      # New
        "create_status_script.sh"        # New
        "get_essential_config.sh"
        "install_dependencies.sh"
        "set_permissions.sh"
        "setup_application.sh"
        "show_completion.sh"
    )
    
    log "Loading function modules..."
    
    for func_file in "${functions_to_load[@]}"; do
        local func_path="${FUNCTIONS_DIR}/${func_file}"
        if [[ -f "$func_path" ]]; then
            source "$func_path"
            log "✓ Loaded ${func_file}"
        else
            error "Function file not found: ${func_path}"
        fi
    done
    
    log "All function modules loaded successfully"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║  ███████╗ █████╗  █████╗ ███╗   ██╗███████╗████████╗        ║
║  ╚══███╔╝██╔══██╗██╔══██╗████╗  ██║██╔════╝╚══██╔══╝        ║
║    ███╔╝ ███████║███████║██╔██╗ ██║█████╗     ██║           ║
║   ███╔╝  ██╔══██║██╔══██║██║╚██╗██║██╔══╝     ██║           ║
║  ███████╗██║  ██║██║  ██║██║ ╚████║███████╗   ██║           ║
║  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝           ║
║                                                              ║
║             🚀 ZaaNet Auto-Installer v1.0.0 🚀              ║
║           Zero-Configuration Captive Portal Setup           ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}🎯 Automatic Setup for Raspberry Pi 4+${NC}"
    echo "   • No manual configuration required"
    echo "   • Complete captive portal in minutes"
    echo "   • Ready for production use"
    echo ""
}

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This installer must be run as root. Please use: curl -sSL https://get.zaanet.xyz | sudo bash"
    fi
}

# Verify all required function files exist
verify_function_files() {
    log "Verifying function files..."
    
    if [[ ! -d "$FUNCTIONS_DIR" ]]; then
        error "Functions directory not found: $FUNCTIONS_DIR"
    fi
    
       local required_functions=(
        "auto_detect_interfaces.sh"
        "check_device_compatibility.sh"
        "configure_auto_start.sh"
        "configure_network_services.sh"
        "create_management_commands.sh"
        "create_system_user.sh"
        "create_systemd_services.sh"
        "create_switcher_script.sh"      # Updated
        "create_firewall_script.sh"      # Updated
        "create_status_script.sh"        # Updated
        "get_essential_config.sh"
        "install_dependencies.sh"
        "set_permissions.sh"
        "setup_application.sh"
        "show_completion.sh"
    )
    
    local missing_functions=()
    
    for func_file in "${required_functions[@]}"; do
        if [[ ! -f "${FUNCTIONS_DIR}/${func_file}" ]]; then
            missing_functions+=("$func_file")
        fi
    done
    
    if [[ ${#missing_functions[@]} -gt 0 ]]; then
        error "Missing required function files: ${missing_functions[*]}"
    fi
    
    success "All required function files found"
}

# Main installation orchestrator
main() {
    show_banner
    check_root
    
    verify_function_files
    source_functions
    
    check_device_compatibility
    auto_detect_interfaces
    get_essential_config
    
    echo ""
    echo -e "${CYAN}🚀 Starting automated installation...${NC}"
    echo ""
    
    install_dependencies
    create_system_user
    setup_application
    configure_network_services
    
    # Create scripts individually
    create_switcher_script
    create_firewall_script
    create_status_script
    
    create_systemd_services
    create_management_commands
    set_permissions
    configure_auto_start
    
    show_completion
}

# Global error handling
trap 'error "Installation failed at line $LINENO. Check /var/log/zaanet-install.log for details."' ERR

# Create install log
exec > >(tee -a /var/log/zaanet-install.log)
exec 2>&1

# Start installation
main "$@"

# --- Included Functions ---

# >>> Including functions/auto_detect_interfaces.sh <<<
#!/bin/bash
# functions/auto_detect_interfaces.sh
# Auto-detect wireless and ethernet network interfaces

auto_detect_interfaces() {
    log "🔍 Auto-detecting network interfaces..."
    
    # Initialize variables
    WIRELESS_INTERFACE=""
    ETHERNET_INTERFACE=""
    
    # =============================================================================
    # WIRELESS INTERFACE DETECTION
    # =============================================================================
    
    log "Scanning for wireless interfaces..."
    
    # Method 1: Check common wireless interface names
    local wireless_patterns=(
        "wlan0"      # Most common on Raspberry Pi
        "wlp2s0"     # PCIe wireless cards
        "wlp3s0"     # Alternative PCIe slot
        "wlx*"       # USB wireless adapters (wildcard)
        "wlo1"       # Some laptops
        "wlp0s*"     # Another PCIe pattern
    )
    
    for pattern in "${wireless_patterns[@]}"; do
        # Handle wildcard patterns differently
        if [[ "$pattern" == *"*"* ]]; then
            # Use find for wildcard patterns
            local found_interfaces
            found_interfaces=$(find /sys/class/net -name "${pattern}" -type l -exec basename {} \; 2>/dev/null)
            if [[ -n "$found_interfaces" ]]; then
                WIRELESS_INTERFACE=$(echo "$found_interfaces" | head -1)
                log "Found wireless interface (wildcard): $WIRELESS_INTERFACE"
                break
            fi
        else
            # Direct check for exact names
            if ip link show "$pattern" >/dev/null 2>&1; then
                WIRELESS_INTERFACE="$pattern"
                log "Found wireless interface: $WIRELESS_INTERFACE"
                break
            fi
        fi
    done
    
    # Method 2: Use iw command to detect wireless interfaces
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        log "Trying iw command for wireless detection..."
        if command -v iw >/dev/null 2>&1; then
            WIRELESS_INTERFACE=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2; exit}')
            if [[ -n "$WIRELESS_INTERFACE" ]]; then
                log "Found wireless interface via iw: $WIRELESS_INTERFACE"
            fi
        fi
    fi
    
    # Method 3: Search in /sys/class/net for any wireless interface
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        log "Searching /sys/class/net for wireless interfaces..."
        WIRELESS_INTERFACE=$(find /sys/class/net -name "wl*" -type l -exec basename {} \; 2>/dev/null | head -1)
        if [[ -n "$WIRELESS_INTERFACE" ]]; then
            log "Found wireless interface in sysfs: $WIRELESS_INTERFACE"
        fi
    fi
    
    # Method 4: Check for any interface with wireless capabilities
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        log "Checking for wireless capabilities in all interfaces..."
        for interface in /sys/class/net/*/wireless; do
            if [[ -d "$interface" ]]; then
                WIRELESS_INTERFACE=$(basename "$(dirname "$interface")")
                log "Found interface with wireless capabilities: $WIRELESS_INTERFACE"
                break
            fi
        done
    fi
    
    # =============================================================================
    # ETHERNET INTERFACE DETECTION
    # =============================================================================
    
    log "Scanning for ethernet interfaces..."
    
    # Method 1: Check common ethernet interface names
    local ethernet_patterns=(
        "eth0"       # Traditional naming
        "enp1s0"     # Predictable network interface names
        "enp1s0f0"   # Multi-function cards
        "eno1"       # Onboard ethernet
        "end0"       # Some systems
        "enp0s*"     # PCIe ethernet (wildcard)
        "ens*"       # Some naming schemes
    )
    
    for pattern in "${ethernet_patterns[@]}"; do
        # Handle wildcard patterns
        if [[ "$pattern" == *"*"* ]]; then
            # Use shell globbing for wildcards
            for interface in /sys/class/net/${pattern}; do
                if [[ -L "$interface" ]]; then
                    ETHERNET_INTERFACE=$(basename "$interface")
                    log "Found ethernet interface (wildcard): $ETHERNET_INTERFACE"
                    break 2  # Break out of both loops
                fi
            done
        else
            # Direct check for exact names
            if ip link show "$pattern" >/dev/null 2>&1; then
                ETHERNET_INTERFACE="$pattern"
                log "Found ethernet interface: $ETHERNET_INTERFACE"
                break
            fi
        fi
    done
    
    # Method 2: Use ip command to find ethernet interfaces
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        log "Using ip command to detect ethernet interfaces..."
        ETHERNET_INTERFACE=$(ip link show | grep -oE 'eth[0-9]+|enp[0-9]+s[0-9]+[f0-9]*|eno[0-9]+|ens[0-9]+' | head -1)
        if [[ -n "$ETHERNET_INTERFACE" ]]; then
            log "Found ethernet interface via ip command: $ETHERNET_INTERFACE"
        fi
    fi
    
    # Method 3: Find any non-wireless, non-loopback interface
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        log "Looking for any wired network interface..."
        while IFS= read -r interface; do
            # Skip loopback, wireless, and virtual interfaces
            if [[ "$interface" != "lo" ]] && 
               [[ "$interface" != wl* ]] && 
               [[ "$interface" != docker* ]] && 
               [[ "$interface" != br-* ]] && 
               [[ "$interface" != virbr* ]] && 
               [[ -d "/sys/class/net/$interface" ]] && 
               [[ ! -d "/sys/class/net/$interface/wireless" ]]; then
                ETHERNET_INTERFACE="$interface"
                log "Found wired interface: $ETHERNET_INTERFACE"
                break
            fi
        done < <(ls /sys/class/net/)
    fi
    
    # =============================================================================
    # INTERFACE VALIDATION
    # =============================================================================
    
    validate_interfaces() {
        log "Validating detected interfaces..."
        
        # Validate wireless interface
        if [[ -n "$WIRELESS_INTERFACE" ]]; then
            if ip link show "$WIRELESS_INTERFACE" >/dev/null 2>&1; then
                # Check if it actually has wireless capabilities
                if [[ -d "/sys/class/net/$WIRELESS_INTERFACE/wireless" ]] || 
                   iw dev "$WIRELESS_INTERFACE" info >/dev/null 2>&1; then
                    success "✓ Wireless interface validated: $WIRELESS_INTERFACE"
                else
                    warning "Interface $WIRELESS_INTERFACE exists but may not have wireless capabilities"
                fi
            else
                warning "Detected wireless interface $WIRELESS_INTERFACE is not available"
                WIRELESS_INTERFACE=""
            fi
        fi
        
        # Validate ethernet interface
        if [[ -n "$ETHERNET_INTERFACE" ]]; then
            if ip link show "$ETHERNET_INTERFACE" >/dev/null 2>&1; then
                success "✓ Ethernet interface validated: $ETHERNET_INTERFACE"
            else
                warning "Detected ethernet interface $ETHERNET_INTERFACE is not available"
                ETHERNET_INTERFACE=""
            fi
        fi
    }
    
    validate_interfaces
    
    # =============================================================================
    # DISPLAY RESULTS
    # =============================================================================
    
    echo ""
    echo -e "${CYAN}🔍 Network Interface Detection Results:${NC}"
    echo "   📡 Wireless Interface: ${WIRELESS_INTERFACE:-${RED}Not detected${NC}}"
    echo "   🌐 Ethernet Interface: ${ETHERNET_INTERFACE:-${YELLOW}Not detected${NC}}"
    
    # Display interface details if found
    if [[ -n "$WIRELESS_INTERFACE" ]]; then
        local wifi_state
        wifi_state=$(ip link show "$WIRELESS_INTERFACE" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
        echo "   📡 Wireless State: ${wifi_state:-UNKNOWN}"
    fi
    
    if [[ -n "$ETHERNET_INTERFACE" ]]; then
        local eth_state
        eth_state=$(ip link show "$ETHERNET_INTERFACE" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
        echo "   🌐 Ethernet State: ${eth_state:-UNKNOWN}"
    fi
    
    # =============================================================================
    # REQUIREMENT VALIDATION
    # =============================================================================
    
    # Wireless interface is mandatory for captive portal
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        echo ""
        error "❌ No wireless interface detected. ZaaNet requires Wi-Fi capability for the captive portal."
        echo ""
        echo "Possible solutions:"
        echo "• Connect a USB Wi-Fi adapter"
        echo "• Enable Wi-Fi if disabled"
        echo "• Check if wireless drivers are installed"
        echo ""
        echo "To check wireless capability manually:"
        echo "  sudo iw dev"
        echo "  lsusb | grep -i wireless"
        echo "  lspci | grep -i wireless"
        exit 1
    fi
    
    # Ethernet is recommended but not mandatory
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        echo ""
        warning "⚠️  No ethernet interface detected."
        echo ""
        echo "This means:"
        echo "• No wired internet connection available"
        echo "• You'll need alternative internet source (USB tethering, Wi-Fi client mode)"
        echo "• Manual configuration may be required"
        echo ""
        
        # Give user option to continue
        read -p "Continue installation without ethernet? [y/N]: " -r CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled by user."
            exit 0
        fi
        
        # Set a default fallback for configuration files
        ETHERNET_INTERFACE="eth0"
        warning "Using fallback ethernet interface name: $ETHERNET_INTERFACE"
    fi
    
    # =============================================================================
    # EXPORT VARIABLES
    # =============================================================================
    
    # Export for use in other functions
    export WIRELESS_INTERFACE
    export ETHERNET_INTERFACE
    
    echo ""
    success "✅ Network interface detection completed"
    log "Wireless: $WIRELESS_INTERFACE | Ethernet: $ETHERNET_INTERFACE"
}
# >>> Including functions/check_device_compatibility.sh <<<
#!/bin/bash
# functions/check_device_compatibility.sh
# Check if device can run ZaaNet (hostapd + dnsmasq + iptables)

check_device_compatibility() {
    log "🔍 Checking ZaaNet compatibility..."
    
    local requirements_met=true
    local is_raspberry_pi=false
    
    # Check if this is a Raspberry Pi
    if [[ -f /proc/device-tree/model ]]; then
        local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
        if [[ "$model" =~ [Rr]aspberry.*[Pp]i ]]; then
            is_raspberry_pi=true
            log "✓ Raspberry Pi detected: $model"
        fi
    fi
    local is_raspberry_pi=false
    
    # Check if this is a Raspberry Pi
    if [[ -f /proc/device-tree/model ]]; then
        local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
        if [[ "$model" =~ [Rr]aspberry.*[Pp]i ]]; then
            is_raspberry_pi=true
            log "✓ Raspberry Pi detected: $model"
        fi
    fi
    
    # =============================================================================
    # ESSENTIAL REQUIREMENTS CHECK
    # =============================================================================
    
    # 1. Check for Wi-Fi capability (absolutely required)
    check_wifi() {
        log "Checking Wi-Fi capability..."
        
        # Check for wireless interfaces
        if iw dev 2>/dev/null | grep -q "Interface" || 
           ls /sys/class/net/*/wireless 2>/dev/null | grep -q wireless; then
            success "✓ Wi-Fi capability detected"
            return 0
        else
            error "❌ No Wi-Fi capability found. ZaaNet requires wireless AP functionality."
            return 1
        fi
    }
    
    # 2. Check if we can install required packages
    check_package_manager() {
        log "Checking package manager..."
        
        if command -v apt-get >/dev/null; then
            export PKG_MANAGER="apt"
            success "✓ APT package manager found"
        elif command -v yum >/dev/null; then
            export PKG_MANAGER="yum" 
            success "✓ YUM package manager found"
        elif command -v dnf >/dev/null; then
            export PKG_MANAGER="dnf"
            success "✓ DNF package manager found"
        elif command -v pacman >/dev/null; then
            export PKG_MANAGER="pacman"
            success "✓ Pacman package manager found"
        else
            error "❌ No supported package manager found (apt/yum/dnf/pacman)"
            return 1
        fi
    }
    
    # 3. Check for systemd (needed for services)
    check_systemd() {
        log "Checking systemd..."
        
        if systemctl --version >/dev/null 2>&1; then
            success "✓ systemd found"
            return 0
        else
            error "❌ systemd required for ZaaNet services"
            return 1
        fi
    }
    
    # 4. Check if we can install/use iptables
    check_iptables() {
        log "Checking iptables capability..."
        
        # Check if already installed
        if command -v iptables >/dev/null; then
            if iptables -L >/dev/null 2>&1; then
                success "✓ iptables already installed and accessible"
                return 0
            else
                warning "iptables installed but needs root access"
            fi
        fi
        
        # Check if we can install it
        case "$PKG_MANAGER" in
            "apt")
                if apt-cache show iptables >/dev/null 2>&1; then
                    success "✓ iptables available for installation"
                    return 0
                fi
                ;;
            "yum"|"dnf")
                if $PKG_MANAGER info iptables >/dev/null 2>&1; then
                    success "✓ iptables available for installation"
                    return 0
                fi
                ;;
            "pacman")
                if pacman -Si iptables >/dev/null 2>&1; then
                    success "✓ iptables available for installation"
                    return 0
                fi
                ;;
        esac
        
        error "❌ Cannot find iptables package"
        return 1
    }
    
    # 5. Check minimum resources
    check_resources() {
        log "Checking system resources..."
        
        # RAM check
        local ram_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
        if [[ "$ram_mb" -lt 256 ]]; then
            error "❌ Insufficient RAM: ${ram_mb}MB (minimum: 256MB)"
            return 1
        else
            success "✓ Sufficient RAM: ${ram_mb}MB"
        fi
        
        # Storage check  
        local storage_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
        if [[ "$storage_gb" -lt 1 ]]; then
            error "❌ Insufficient storage: ${storage_gb}GB (minimum: 1GB)"
            return 1
        else
            success "✓ Sufficient storage: ${storage_gb}GB"
        fi
        
        return 0
    }
    
    # =============================================================================
    # RUN ALL CHECKS
    # =============================================================================
    
    echo ""
    echo -e "${CYAN}📋 ZaaNet Compatibility Check${NC}"
    echo ""
    
    check_wifi || requirements_met=false
    check_package_manager || requirements_met=false  
    check_systemd || requirements_met=false
    check_iptables || requirements_met=false
    check_resources || requirements_met=false
    
    # =============================================================================
    # FINAL DECISION
    # =============================================================================
    
    echo ""
    if [[ "$requirements_met" == true ]]; then
        success "🎉 Device is compatible with ZaaNet!"
        log "Ready to install hostapd, dnsmasq, and configure captive portal"
        
        # Export for other functions
        export IS_RASPBERRY_PI="$is_raspberry_pi"
        
        return 0
    else
        error "❌ Device does not meet ZaaNet requirements"
        echo ""
        echo "Required for ZaaNet:"
        echo "• Wi-Fi adapter with AP mode support"
        echo "• Package manager (apt/yum/dnf/pacman)"
        echo "• systemd for service management"  
        echo "• iptables access for NAT/forwarding"
        echo "• Minimum 256MB RAM, 1GB storage"
        exit 1
    fi
}
# >>> Including functions/configure_auto_start.sh <<<
#!/bin/bash
# functions/configure_auto_start.sh
# Configure auto-start behavior for ZaaNet services

configure_auto_start() {
    log "🚀 Configuring auto-start behavior..."
    
    # =============================================================================
    # VALIDATE SERVICES EXIST
    # =============================================================================
    
    validate_services() {
        log "Validating systemd services..."
        
        local services=("zaanet-manager.service" "zaanet.service")
        local missing_services=()
        
        for service in "${services[@]}"; do
            if [[ -f "/etc/systemd/system/$service" ]]; then
                log "✓ Found: $service"
            else
                missing_services+=("$service")
                error "Missing service file: $service"
            fi
        done
        
        if [[ ${#missing_services[@]} -gt 0 ]]; then
            error "Cannot configure auto-start - missing services: ${missing_services[*]}"
        fi
    }
    
    # =============================================================================
    # CONFIGURE AUTO-START
    # =============================================================================
    
    if [[ "$AUTO_START" =~ ^[Yy] ]]; then
        log "Enabling auto-start on boot..."
        
        validate_services
        
        # Enable services
        if systemctl enable zaanet-manager; then
            success "✓ zaanet-manager enabled for auto-start"
        else
            error "Failed to enable zaanet-manager service"
        fi
        
        if systemctl enable zaanet; then
            success "✓ zaanet enabled for auto-start"
        else
            error "Failed to enable zaanet service"
        fi
        
        # Verify services are enabled
        if systemctl is-enabled --quiet zaanet-manager && systemctl is-enabled --quiet zaanet; then
            success "✅ ZaaNet will start automatically on boot"
        else
            warning "Auto-start may not be properly configured"
        fi
        
    else
        log "Auto-start disabled by user choice"
        
        # Ensure services are disabled if they exist
        if [[ -f "/etc/systemd/system/zaanet-manager.service" ]]; then
            systemctl disable zaanet-manager 2>/dev/null || true
        fi
        
        if [[ -f "/etc/systemd/system/zaanet.service" ]]; then
            systemctl disable zaanet 2>/dev/null || true
        fi
        
        log "Services will require manual start: sudo systemctl start zaanet-manager"
    fi
}
# >>> Including functions/configure_network_services.sh <<<
#!/bin/bash
# functions/configure_network_services.sh
# Configure hostapd and dnsmasq for captive portal

configure_network_services() {
    log "⚙️ Configuring network services..."
    
    # =============================================================================
    # BACKUP EXISTING CONFIGURATIONS
    # =============================================================================
    
    backup_configs() {
        log "Backing up existing configurations..."
        
        local backup_dir="$ZAANET_DIR/backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        [[ -f /etc/hostapd/hostapd.conf ]] && cp /etc/hostapd/hostapd.conf "$backup_dir/"
        [[ -f /etc/dnsmasq.conf ]] && cp /etc/dnsmasq.conf "$backup_dir/"
        
        log "✓ Configurations backed up to: $backup_dir"
    }
    
    # =============================================================================
    # DISABLE CONFLICTING SERVICES
    # =============================================================================
    
    disable_conflicts() {
        log "Disabling conflicting network services..."
        
        # Stop and disable NetworkManager on wireless interface
        if systemctl is-active --quiet NetworkManager 2>/dev/null; then
            log "Disabling NetworkManager management of $WIRELESS_INTERFACE..."
            nmcli device set "$WIRELESS_INTERFACE" managed no 2>/dev/null || true
            nmcli device disconnect "$WIRELESS_INTERFACE" 2>/dev/null || true
        fi
        
        # Stop wpa_supplicant on wireless interface
        systemctl stop wpa_supplicant@"$WIRELESS_INTERFACE" 2>/dev/null || true
        systemctl disable wpa_supplicant@"$WIRELESS_INTERFACE" 2>/dev/null || true
        
        # Kill any remaining processes that might interfere
        pkill -f "wpa_supplicant.*$WIRELESS_INTERFACE" 2>/dev/null || true
        pkill -f "dhclient.*$WIRELESS_INTERFACE" 2>/dev/null || true
        
        # Wait for interface to settle
        sleep 2
        
        success "Conflicting services disabled"
    }
    
    # =============================================================================
    # CONFIGURE HOSTAPD
    # =============================================================================
    
    configure_hostapd() {
        log "Configuring hostapd for $WIRELESS_INTERFACE..."
        
        mkdir -p /etc/hostapd
        
        cat > /etc/hostapd/hostapd.conf <<EOF
# ZaaNet Hostapd Configuration - Auto-generated
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

interface=$WIRELESS_INTERFACE
EOF

        # Add driver line conditionally
        if [[ "$IS_RASPBERRY_PI" == "true" ]]; then
            echo "# driver=nl80211  # Commented out for Raspberry Pi compatibility" >> /etc/hostapd/hostapd.conf
        else
            echo "driver=nl80211" >> /etc/hostapd/hostapd.conf
        fi

        cat >> /etc/hostapd/hostapd.conf <<EOF
ssid=$WIFI_SSID

# Basic Wi-Fi settings
hw_mode=g
channel=6
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0

# No encryption (open network for captive portal)
wpa=0

# Country code and regulatory
country_code=GH

# Minimal settings for maximum compatibility
max_num_sta=30

# Logging
logger_syslog=-1
logger_stdout=-1

# Auto-generated for:
# Wireless Interface: $WIRELESS_INTERFACE
# Portal IP: $PORTAL_IP
# SSID: $WIFI_SSID
EOF
        
        # Configure hostapd daemon
        if [[ -f /etc/default/hostapd ]]; then
            sed -i 's/^#*DAEMON_CONF=.*/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
        else
            echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd
        fi
        
        success "✓ hostapd configured"
    }
    
    # =============================================================================
    # CONFIGURE DNSMASQ
    # =============================================================================
    
    configure_dnsmasq() {
        log "Configuring dnsmasq..."
        
        # Backup original if exists
        [[ -f /etc/dnsmasq.conf ]] && cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
        
        cat > /etc/dnsmasq.conf <<EOF
# ZaaNet Dnsmasq Configuration - Auto-generated
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Interface binding
interface=$WIRELESS_INTERFACE
bind-interfaces
except-interface=lo

# Don't provide DHCP on ethernet
no-dhcp-interface=$ETHERNET_INTERFACE

# DHCP configuration
dhcp-range=$DHCP_START,$DHCP_END,255.255.255.0,12h
dhcp-option=3,$PORTAL_IP
dhcp-option=6,$PORTAL_IP
dhcp-authoritative

# DNS configuration
domain-needed
bogus-priv
no-resolv
server=$DNS_SERVER
expand-hosts

# Common connectivity check domains
address=/connectivitycheck.gstatic.com/$PORTAL_IP
address=/clients3.google.com/$PORTAL_IP
address=/captive.apple.com/$PORTAL_IP
address=/www.msftconnecttest.com/$PORTAL_IP

# Logging
log-queries
log-dhcp

# Configuration summary:
# Portal IP: $PORTAL_IP
# DHCP Range: $DHCP_START - $DHCP_END
# Wireless Interface: $WIRELESS_INTERFACE
# Internet Interface: $ETHERNET_INTERFACE
EOF
        
        # Create dhcp lease directory
        mkdir -p /var/lib/dhcp
        
        success "✓ dnsmasq configured"
    }
    
    # =============================================================================
    # VERIFY CONFIGURATIONS
    # =============================================================================
    
    verify_configs() {
        log "Verifying configurations..."
        
        # Check hostapd config file exists and has basic syntax
        if [[ -f /etc/hostapd/hostapd.conf ]] && grep -q "interface=" /etc/hostapd/hostapd.conf; then
            success "✓ hostapd configuration file created"
        else
            error "hostapd configuration file missing or invalid"
        fi
        
        # Check dnsmasq config file exists and has basic syntax
        if [[ -f /etc/dnsmasq.conf ]] && grep -q "interface=" /etc/dnsmasq.conf; then
            success "✓ dnsmasq configuration file created"
        else
            error "dnsmasq configuration file missing or invalid"
        fi
        
        log "Configuration verification completed (runtime testing skipped)"
    }
    
    # =============================================================================
    # RUN CONFIGURATION
    # =============================================================================
    
    backup_configs
    disable_conflicts
    configure_hostapd
    configure_dnsmasq
    verify_configs
    
    success "✅ Network services configured"
}

# >>> Including functions/create_firewall_script.sh <<<
#!/bin/bash
# functions/create_firewall_script.sh
create_firewall_script() {
    log "Creating firewall management script..."
   
    mkdir -p "$ZAANET_DIR/scripts"
   
    cat > "$ZAANET_DIR/scripts/zaanet-firewall.sh" <<'EOF'
#!/bin/bash
# ZaaNet Firewall Setup Script - Improved Version
# This script sets up a captive portal firewall for WiFi hotspot access control
# Configuration
LAN_IF="%WIRELESS_INTERFACE%"
WAN_IF="%ETHERNET_INTERFACE%"
PORTAL_IP="%PORTAL_IP%"
LAN_SUBNET="192.168.100.0/24"
PORTAL_PORT="80"
API_PORT="3001"
LOG_FILE="/var/log/zaanet-firewall.log"
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local color="$NC"
   
    case "$level" in
        ERROR) color="$RED" ;;
        SUCCESS) color="$GREEN" ;;
        WARNING) color="$YELLOW" ;;
    esac
   
    echo -e "${color}[$timestamp] [$level]${NC} $message"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
}
validate_environment() {
    log "INFO" "Validating environment..."
   
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
    for tool in iptables ip; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log "ERROR" "Required tool not found: $tool"
            exit 1
        fi
    done
    # Validate IP format
    if ! [[ $PORTAL_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        log "ERROR" "Invalid PORTAL_IP format: $PORTAL_IP"
        exit 1
    fi
    if ! ip link show "$LAN_IF" >/dev/null 2>&1; then
        log "ERROR" "LAN interface $LAN_IF not found"
        exit 1
    fi
    if ! ip link show "$WAN_IF" >/dev/null 2>&1; then
        log "WARNING" "WAN interface $WAN_IF not found, internet sharing may not work"
    fi
    log "SUCCESS" "Environment validation passed"
}
enable_ip_forwarding() {
    log "INFO" "Enabling IP forwarding..."
   
    echo 1 > /proc/sys/net/ipv4/ip_forward
   
    # Verify it's enabled
    if [[ $(cat /proc/sys/net/ipv4/ip_forward) -eq 1 ]]; then
        log "SUCCESS" "IP forwarding enabled"
    else
        log "ERROR" "Failed to enable IP forwarding"
        exit 1
    fi
   
    # Persist across reboots
    if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf > /dev/null
        log "SUCCESS" "IP forwarding persisted to /etc/sysctl.conf"
    fi
}
cleanup_rules() {
    log "INFO" "Cleaning up existing ZaaNet firewall rules..."
   
    # Remove jump rules first (so chains can be deleted)
    iptables -D FORWARD -j ZAANET_BLOCKED 2>/dev/null || true
    iptables -D FORWARD -i "$LAN_IF" -j ZAANET_AUTH_USERS 2>/dev/null || true
   
    # Flush custom chains
    iptables -F ZAANET_AUTH_USERS 2>/dev/null || true
    iptables -F ZAANET_BLOCKED 2>/dev/null || true
   
    # Delete custom chains
    iptables -X ZAANET_AUTH_USERS 2>/dev/null || true
    iptables -X ZAANET_BLOCKED 2>/dev/null || true
   
    # Clean up NAT rules for captive portal
    iptables -t nat -D PREROUTING -i "$LAN_IF" -p tcp --dport 80 -j DNAT --to-destination $PORTAL_IP:$PORTAL_PORT 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$LAN_IF" -p tcp --dport 443 -j DNAT --to-destination $PORTAL_IP:$PORTAL_PORT 2>/dev/null || true
   
    log "SUCCESS" "Cleanup completed"
}
setup_policies() {
    log "INFO" "Setting up iptables policies..."
   
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD DROP
   
    log "SUCCESS" "Policies set: INPUT=ACCEPT, OUTPUT=ACCEPT, FORWARD=DROP"
}
setup_nat() {
    log "INFO" "Configuring NAT rules..."
   
    # POSTROUTING: Masquerade outgoing traffic (internet sharing)
    if ip link show "$WAN_IF" >/dev/null 2>&1; then
        iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
        log "SUCCESS" "NAT masquerading configured via $WAN_IF"
    else
        log "WARNING" "No WAN interface available, internet sharing disabled"
    fi
   
    # PREROUTING: Redirect HTTP/HTTPS to captive portal
    # This catches all HTTP/HTTPS traffic and redirects to portal
    # Authenticated users will bypass this via RETURN rules added dynamically
    iptables -t nat -A PREROUTING -i "$LAN_IF" -p tcp --dport 80 \
        -j DNAT --to-destination $PORTAL_IP:$PORTAL_PORT
   
    iptables -t nat -A PREROUTING -i "$LAN_IF" -p tcp --dport 443 \
        -j DNAT --to-destination $PORTAL_IP:$PORTAL_PORT
   
    log "SUCCESS" "Captive portal redirection: HTTP/HTTPS → $PORTAL_IP:$PORTAL_PORT"
}
setup_basic_rules() {
    log "INFO" "Setting up basic firewall rules..."
   
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
   
    # Allow essential services to host (INPUT chain)
    iptables -A INPUT -i "$LAN_IF" -p udp --dport 53 -j ACCEPT # DNS
    iptables -A INPUT -i "$LAN_IF" -p tcp --dport 53 -j ACCEPT # DNS over TCP
    iptables -A INPUT -i "$LAN_IF" -p udp --dport 67:68 -j ACCEPT # DHCP
    iptables -A INPUT -i "$LAN_IF" -p tcp --dport $PORTAL_PORT -j ACCEPT # Portal
    iptables -A INPUT -i "$LAN_IF" -p tcp --dport 443 -j ACCEPT # HTTPS portal
    iptables -A INPUT -i "$LAN_IF" -p tcp --dport $API_PORT -j ACCEPT # API
   
    # Allow DNS forwarding for all users (so they can resolve domain names)
    # This allows portal detection and better UX
    iptables -A FORWARD -i "$LAN_IF" -p udp --dport 53 -j ACCEPT
    iptables -A FORWARD -i "$LAN_IF" -p tcp --dport 53 -j ACCEPT
   
    log "SUCCESS" "Basic rules configured (DNS, DHCP, Portal, API access)"
}

create_auth_chains() {
    log "INFO" "Creating authentication chains..."
   
    # Create custom chains
    iptables -N ZAANET_AUTH_USERS 2>/dev/null || true
    iptables -N ZAANET_BLOCKED 2>/dev/null || true
   
    # Remove any existing jumps to avoid duplicates
    while iptables -D FORWARD -j ZAANET_AUTH_USERS 2>/dev/null; do
        log "INFO" "Removed existing AUTH chain jump"
    done
    
    while iptables -D FORWARD -j ZAANET_BLOCKED 2>/dev/null; do
        log "INFO" "Removed existing BLOCKED chain jump"
    done
   
    # === FORWARD Chain Structure ===
    
    # 1. Check authentication FIRST (both directions for counting)
    # Inbound traffic (downloads): Internet → WiFi
    iptables -I FORWARD 1 -o "$LAN_IF" -j ZAANET_AUTH_USERS
    
    # Outbound traffic (uploads): WiFi → Internet
    iptables -I FORWARD 1 -i "$LAN_IF" -j ZAANET_AUTH_USERS
   
    # 2. Check if IP is explicitly blocked (only outgoing WiFi traffic)
    iptables -A FORWARD -i "$LAN_IF" -j ZAANET_BLOCKED
   
    # 3. Allow return traffic (internet → clients)
    iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
   
    # 4. Everything else hits DROP (policy)
   
    log "SUCCESS" "Authentication chains configured"
    log "INFO" "  FORWARD rule order:"
    log "INFO" "    1. AUTH inbound (Internet → WiFi)"
    log "INFO" "    2. AUTH outbound (WiFi → Internet)"
    log "INFO" "    3. BLOCKED check"
    log "INFO" "    4. ESTABLISHED/RELATED"
    log "INFO" "    5. DROP (policy)"
}

test_configuration() {
    log "INFO" "Testing firewall configuration..."
   
    local errors=0
   
    # Check if custom chains exist
    if ! iptables -L ZAANET_AUTH_USERS -n >/dev/null 2>&1; then
        log "ERROR" "ZAANET_AUTH_USERS chain not found"
        ((errors++))
    fi
   
    if ! iptables -L ZAANET_BLOCKED -n >/dev/null 2>&1; then
        log "ERROR" "ZAANET_BLOCKED chain not found"
        ((errors++))
    fi
   
    # Check if FORWARD policy is DROP
    if ! iptables -L FORWARD -n | grep -q "policy DROP"; then
        log "ERROR" "FORWARD policy is not DROP (security risk!)"
        ((errors++))
    fi
   
    # Check if NAT redirection exists
    if ! iptables -t nat -L PREROUTING -n | grep -q "DNAT.*$PORTAL_IP"; then
        log "WARNING" "NAT redirection to portal not found (users may not see portal)"
    fi
   
    # Check if IP forwarding is enabled
    if [[ $(cat /proc/sys/net/ipv4/ip_forward) -ne 1 ]]; then
        log "ERROR" "IP forwarding is not enabled"
        ((errors++))
    fi
   
    if [[ $errors -gt 0 ]]; then
        log "ERROR" "Configuration test failed with $errors error(s)"
        return 1
    fi
   
    log "SUCCESS" "All configuration tests passed"
    return 0
}
show_summary() {
    echo ""
    echo "=========================================="
    echo " ZaaNet Firewall Setup Complete"
    echo "=========================================="
    echo ""
    echo "Configuration:"
    echo " LAN Interface: $LAN_IF"
    echo " WAN Interface: $WAN_IF"
    echo " Portal IP: $PORTAL_IP:$PORTAL_PORT"
    echo " API Port: $API_PORT"
    echo " LAN Subnet: $LAN_SUBNET"
    echo ""
    echo "Firewall Status:"
    echo " Default Policy: FORWARD=DROP (secure)"
    echo " Auth Chain: ZAANET_AUTH_USERS"
    echo " Block Chain: ZAANET_BLOCKED"
    echo ""
    echo "Traffic Flow:"
    echo " 1. ✓ Blocked IPs dropped immediately"
    echo " 2. ✓ Authenticated users → Internet"
    echo " 3. ✓ Non-authenticated → Captive Portal"
    echo " 4. ✓ DNS allowed for all (portal detection)"
    echo ""
    echo "Next Steps:"
    echo " • Start your Node.js portal server"
    echo " • Start the TypeScript firewall service"
    echo " • Use API to authenticate users:"
    echo " POST http://localhost:$API_PORT/api/authenticate"
    echo ""
    echo "View Rules:"
    echo " iptables -L -n -v"
    echo " iptables -t nat -L -n -v"
    echo ""
    echo "Log File: $LOG_FILE"
    echo "=========================================="
}
show_current_rules() {
    echo ""
    echo "=== Current FORWARD Chain ==="
    iptables -L FORWARD -n -v --line-numbers
    echo ""
    echo "=== Auth Chain (ZAANET_AUTH_USERS) ==="
    iptables -L ZAANET_AUTH_USERS -n -v --line-numbers
    echo ""
    echo "=== NAT PREROUTING (Portal Redirection) ==="
    iptables -t nat -L PREROUTING -n -v --line-numbers
}
cleanup_and_exit() {
    log "INFO" "Performing cleanup before exit..."
    cleanup_rules
    log "INFO" "Cleanup complete. Exiting."
    exit 0
}
main() {
    local backup_file="/tmp/iptables-backup-$(date +%Y%m%d-%H%M%S).rules"
   
    log "INFO" "Starting ZaaNet Firewall Setup..."
    log "INFO" "Backup current iptables to: $backup_file"
    iptables-save > "$backup_file" 2>/dev/null || true
    # Validate environment before making changes
    validate_environment
   
    # Enable IP forwarding
    enable_ip_forwarding
   
    # Clean up any existing ZaaNet rules
    cleanup_rules
   
    # Setup firewall policies
    setup_policies
   
    # Configure NAT (internet sharing + portal redirection)
    setup_nat
   
    # Setup basic rules (DNS, DHCP, portal access)
    setup_basic_rules
   
    # Create authentication chains
    create_auth_chains
   
    # Test the configuration
    if ! test_configuration; then
        log "ERROR" "Configuration test failed!"
        log "INFO" "Restoring from backup: $backup_file"
        iptables-restore < "$backup_file" 2>/dev/null || true
        exit 1
    fi
   
    # Show summary
    show_summary
   
    # Optionally show current rules
    if [[ "${1:-}" == "--show-rules" ]]; then
        show_current_rules
    fi
   
    log "SUCCESS" "ZaaNet Firewall setup completed successfully!"
}
# Handle script arguments
case "${1:-}" in
    --cleanup)
        log "INFO" "Cleanup mode activated"
        cleanup_and_exit
        ;;
    --show-rules)
        main --show-rules
        ;;
    --help)
        echo "ZaaNet Firewall Setup Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo " (no args) Setup firewall"
        echo " --show-rules Setup and display current rules"
        echo " --cleanup Remove ZaaNet firewall rules"
        echo " --help Show this help message"
        echo ""
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
# Trap signals for graceful exit
trap 'log "WARNING" "Script interrupted"; exit 130' INT TERM
EOF
   
    # Replace placeholders
    sed -i "s|%WIRELESS_INTERFACE%|$WIRELESS_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    sed -i "s|%ETHERNET_INTERFACE%|$ETHERNET_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    sed -i "s|%PORTAL_IP%|$PORTAL_IP|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
   
    chmod +x "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    chown "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
   
    success "✓ Firewall script created"
}

# >>> Including functions/create_management_commands.sh <<<
#!/bin/bash
# functions/create_management_commands.sh
# Create user-friendly management commands

create_management_commands() {
    log "⚙️ Creating management commands..."
    
    # Create main zaanet command
    cat > /usr/local/bin/zaanet <<EOF
#!/bin/bash
# ZaaNet Management Command - Auto-generated

ZAANET_DIR="$ZAANET_DIR"
WIFI_SSID="$WIFI_SSID"
PORTAL_IP="$PORTAL_IP"
PORTAL_DOMAIN="$PORTAL_DOMAIN"
CONTRACT_ID="$CONTRACT_ID"

case "\$1" in
    start)
        echo "🚀 Starting ZaaNet Captive Portal..."
        echo "   📡 Wi-Fi: \$WIFI_SSID"
        echo "   🏠 Portal: \$PORTAL_IP"
        sudo systemctl start zaanet-manager
        sudo systemctl start zaanet
        echo ""
        echo "ZaaNet started successfully!"
        echo ""
        echo "📱 Next Steps:"
        echo "   1. Connect to Wi-Fi: \$WIFI_SSID"
        echo "   2. Open browser and visit any website"
        echo "   3. You'll be redirected to the captive portal"
        echo "   4. Or visit directly: http://\$PORTAL_DOMAIN"
        ;;
    stop)
        echo "🛑 Stopping ZaaNet..."
        sudo systemctl stop zaanet
        sudo systemctl stop zaanet-manager
        echo "ZaaNet stopped - normal internet mode restored"
        ;;
    status)
        echo "📊 ZaaNet Status:"
        echo "   📡 Wi-Fi SSID: \$WIFI_SSID"
        echo "   🏠 Portal IP: \$PORTAL_IP"
        echo "   📜 Contract: \$CONTRACT_ID"
        echo ""
        sudo \$ZAANET_DIR/scripts/zaanet-switcher.sh --status
        echo ""
        echo "Application Services:"
        if systemctl is-active --quiet zaanet; then
            echo "  📱 Portal App: Running"
        else
            echo "  📱 Portal App: ❌ Stopped"
        fi
        
        if systemctl is-active --quiet zaanet-manager; then
            echo "  🌐 Network: Active (Captive Portal Mode)"
        else
            echo "  🌐 Network: ❌ Inactive (Normal Internet Mode)"
        fi
        ;;
    restart)
        echo "🔄 Restarting ZaaNet..."
        sudo systemctl restart zaanet-manager
        sudo systemctl restart zaanet
        echo "ZaaNet restarted successfully!"
        ;;
    enable)
        echo "⚙️ Enabling auto-start on boot..."
        sudo systemctl enable zaanet-manager
        sudo systemctl enable zaanet
        echo "ZaaNet will now start automatically on boot"
        ;;
    disable)
        echo "⚙️ Disabling auto-start..."
        sudo systemctl disable zaanet-manager
        sudo systemctl disable zaanet
        echo "Auto-start disabled"
        ;;
    logs)
        echo "📋 ZaaNet Logs (Press Ctrl+C to exit):"
        journalctl -u zaanet -u zaanet-manager -f --no-hostname
        ;;
    firewall)
        case "\$2" in
            status)
                echo "🛡️ Firewall Status:"
                echo "   Authenticated users with internet access:"
                sudo iptables -L ZAANET_AUTH_USERS -n --line-numbers 2>/dev/null || echo "   No authenticated users"
                ;;
            allow)
                if [[ -n "\$3" ]]; then
                    echo "Granting internet access to IP: \$3"
                    sudo iptables -A ZAANET_AUTH_USERS -s "\$3" -j ACCEPT
                    echo "Done! Device \$3 now has internet access"
                else
                    echo "❌ Usage: zaanet firewall allow <ip_address>"
                    echo "💡 Example: zaanet firewall allow 192.168.100.105"
                fi
                ;;
            block)
                if [[ -n "\$3" ]]; then
                    echo "🚫 Removing internet access for IP: \$3"
                    sudo iptables -D ZAANET_AUTH_USERS -s "\$3" -j ACCEPT 2>/dev/null || echo "IP not found in authenticated list"
                    echo "Done! Device \$3 internet access revoked"
                else
                    echo "❌ Usage: zaanet firewall block <ip_address>"
                    echo "💡 Example: zaanet firewall block 192.168.100.105"
                fi
                ;;
            list)
                echo "🛡️ Firewall Rules:"
                echo ""
                echo "Authenticated Users (have internet access):"
                sudo iptables -L ZAANET_AUTH_USERS -n --line-numbers 2>/dev/null || echo "No authenticated users"
                echo ""
                echo "Blocked Users:"
                sudo iptables -L ZAANET_BLOCKED -n --line-numbers 2>/dev/null || echo "No specifically blocked users"
                ;;
            *)
                echo "🛡️ Firewall Commands:"
                echo "  zaanet firewall status        - Show authenticated users"
                echo "  zaanet firewall list          - Show all firewall rules"
                echo "  zaanet firewall allow <ip>    - Grant internet access"
                echo "  zaanet firewall block <ip>    - Revoke internet access"
                echo ""
                echo "💡 Users must authenticate through the portal first,"
                echo "   then their IP gets automatically added to the allow list."
                ;;
        esac
        ;;
    config)
        echo "⚙️ ZaaNet Configuration:"
        echo "   📡 Wi-Fi SSID: \$WIFI_SSID"
        echo "   🏠 Portal IP: \$PORTAL_IP"
        echo "   🌐 Portal Domain: \$PORTAL_DOMAIN"
        echo "   📜 Contract ID: \$CONTRACT_ID"
        echo ""
        echo "📁 File Locations:"
        echo "   📱 App Directory: \$ZAANET_DIR/app"
        echo "   📜 Scripts: \$ZAANET_DIR/scripts"
        echo "   📄 Environment: \$ZAANET_DIR/app/.env"
        echo "   📄 Logs: /var/log/zaanet*.log"
        echo ""
        echo "🔧 System Configuration:"
        echo "   📡 Hostapd: /etc/hostapd/hostapd.conf"
        echo "   🌐 Dnsmasq: /etc/dnsmasq.conf"
        ;;
    update)
        echo "📥 Updating ZaaNet..."
        cd \$ZAANET_DIR/app
        git pull
        npm install
        echo "🔄 Restarting services..."
        sudo systemctl restart zaanet
        echo "ZaaNet updated successfully!"
        ;;
    *)
        cat << 'BANNER'
╔══════════════════════════════════════════════════════════════╗
║                    ZaaNet Management                         ║
║                   Captive Portal System                     ║
╚══════════════════════════════════════════════════════════════╝
BANNER
        echo ""
        echo "🚀 Control Commands:"
        echo "  zaanet start      - Start captive portal mode"
        echo "  zaanet stop       - Stop and return to normal internet"
        echo "  zaanet restart    - Restart all services"
        echo "  zaanet status     - Show current status"
        echo ""
        echo "⚙️ Management:"
        echo "  zaanet enable     - Enable auto-start on boot"
        echo "  zaanet disable    - Disable auto-start"
        echo "  zaanet logs       - View live logs"
        echo "  zaanet config     - Show configuration"
        echo "  zaanet update     - Update to latest version"
        echo ""
        echo "🛡️ Firewall:"
        echo "  zaanet firewall status      - Show authenticated users"
        echo "  zaanet firewall list        - Show all firewall rules"
        echo "  zaanet firewall allow <ip>  - Grant internet access"
        echo "  zaanet firewall block <ip>  - Revoke internet access"
        echo ""
        echo "🌐 Current Configuration:"
        echo "  Wi-Fi SSID: \$WIFI_SSID"
        echo "  Portal IP: \$PORTAL_IP"
        echo "  Contract: \$CONTRACT_ID"
        echo ""
        echo "📚 Help: https://docs.zaanet.xyz"
        ;;
esac
EOF
    
    # Make command executable
    chmod +x /usr/local/bin/zaanet
    
    # Verify command was created
    if [[ ! -f /usr/local/bin/zaanet ]]; then
        error "Failed to create zaanet command"
    fi
    
    success "✅ Management commands created successfully"
}
# >>> Including functions/create_status_script.sh <<<
#!/bin/bash
# functions/create_status_script.sh
create_status_script() {
    log "Creating status monitoring script..."

    mkdir -p "$ZAANET_DIR/scripts"

    cat > "$ZAANET_DIR/scripts/zaanet-status.sh" <<'EOF'
#!/bin/bash
# ZaaNet Status Monitor
show_detailed_status() {
    echo "================================"
    echo " ZaaNet Status Report"
    echo "================================"
    echo ""
   
    # Service Status
    echo "🔧 Services:"
    printf " hostapd: %-10s " "$(systemctl is-active hostapd 2>/dev/null || echo 'inactive')"
    systemctl is-active --quiet hostapd && echo "✓" || echo "✗"
   
    printf " dnsmasq: %-10s " "$(systemctl is-active dnsmasq 2>/dev/null || echo 'inactive')"
    systemctl is-active --quiet dnsmasq && echo "✓" || echo "✗"
   
    echo ""
   
    # Network Status
    echo "📡 Network:"
    echo " Interface: %WIRELESS_INTERFACE%"
    echo " SSID: %WIFI_SSID%"
    echo " Portal IP: %PORTAL_IP%"
   
    if ip addr show "%WIRELESS_INTERFACE%" | grep -q "%PORTAL_IP%"; then
        echo " Status: IP configured ✓"
    else
        echo " Status: IP not configured ✗"
    fi
   
    echo ""
   
    # Connected Clients
    echo "👥 Connected Clients:"
    if [[ -f /var/lib/dhcp/dnsmasq.leases ]]; then
        local client_count=$(wc -l < /var/lib/dhcp/dnsmasq.leases)
        echo " Active leases: $client_count"
        if [[ $client_count -gt 0 ]]; then
            echo " Recent connections:"
            tail -5 /var/lib/dhcp/dnsmasq.leases | while read line; do
                local ip=$(echo "$line" | awk '{print $3}')
                local mac=$(echo "$line" | awk '{print $2}')
                echo " $ip ($mac)"
            done
        fi
    else
        echo " No lease file found"
    fi
   
    echo ""
   
    # Log Status
    echo "📋 Recent Activity:"
    if [[ -f /var/log/zaanet.log ]]; then
        echo " Last 3 log entries:"
        tail -3 /var/log/zaanet.log | sed 's/^/ /'
    else
        echo " No log file found"
    fi
}
case "${1:-}" in
    --detailed|-d)
        show_detailed_status
        ;;
    *)
        # Quick status
        if systemctl is-active --quiet hostapd && systemctl is-active --quiet dnsmasq; then
            echo "ZaaNet: ACTIVE ✓"
        else
            echo "ZaaNet: INACTIVE ✗"
        fi
        ;;
esac
EOF
   
    # Replace placeholders
    sed -i "s|%WIRELESS_INTERFACE%|$WIRELESS_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-status.sh"
    sed -i "s|%WIFI_SSID%|$WIFI_SSID|g" "$ZAANET_DIR/scripts/zaanet-status.sh"
    sed -i "s|%PORTAL_IP%|$PORTAL_IP|g" "$ZAANET_DIR/scripts/zaanet-status.sh"
   
    success "✓ Status script created"
}

# >>> Including functions/create_switcher_script.sh <<<
#!/bin/bash
# functions/create_switcher_script.sh
create_switcher_script() {
    log "Creating network switcher script..."
   
    cat > "$ZAANET_DIR/scripts/zaanet-switcher.sh" <<'EOF'
#!/bin/bash
# ZaaNet Network Mode Switcher - Auto-generated
# Configuration - Auto-detected values will be inserted here
INTERFACE="%WIRELESS_INTERFACE%"
IP_ADDRESS="%PORTAL_IP%/24"
DNS_SERVER="%DNS_SERVER%"
PORTAL_PORT="%PORTAL_PORT%"
FIREWALL_SCRIPT="%ZAANET_DIR%/scripts/zaanet-firewall.sh"
LOG_FILE="/var/log/zaanet.log"
# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo"
    exit 1
fi
# Logging function
log() {
    echo "$(date -u '+%Y-%m-%d %H:%M:%S') [ZaaNet] $1" | tee -a "$LOG_FILE"
}
# FUNCTION - NORMAL INTERNET MODE
to_normal_mode() {
    log "Switching to normal internet mode..."
   
    # Stop ZaaNet services
    sudo systemctl stop dnsmasq
    sudo systemctl stop hostapd
    sudo systemctl disable dnsmasq --quiet 2>/dev/null || true
    sudo systemctl disable hostapd --quiet 2>/dev/null || true
    sudo systemctl mask hostapd 2>/dev/null || true
   
    # Clear firewall rules
    sudo iptables -F ZAANET_AUTH_USERS 2>/dev/null || true
    sudo iptables -X ZAANET_AUTH_USERS 2>/dev/null || true
    sudo iptables -F ZAANET_BLOCKED 2>/dev/null || true
    sudo iptables -X ZAANET_BLOCKED 2>/dev/null || true
   
    # Remove ZaaNet IP address
    sudo ip addr del "$IP_ADDRESS" dev "$INTERFACE" 2>/dev/null || true
   
    # Re-enable NetworkManager if available
    if command -v nmcli >/dev/null 2>&1; then
        nmcli dev set "$INTERFACE" managed yes 2>/dev/null || true
        sudo systemctl restart NetworkManager 2>/dev/null || true
    fi
   
    # Bring interface up for normal use
    sudo ip link set "$INTERFACE" up
   
    log "Normal internet mode restored."
}
# FUNCTION - ZAANET MODE
to_zaanet_mode() {
    log "Switching to ZaaNet captive portal mode..."
   
    # Check if firewall script exists
    if [[ ! -x "$FIREWALL_SCRIPT" ]]; then
        log "Firewall script not found or not executable: $FIREWALL_SCRIPT"
        exit 1
    fi
   
    # Error handling
    trap 'log "Error occurred, reverting to normal mode..."; to_normal_mode; exit 1' ERR
   
    # Disable NetworkManager management if available
    if command -v nmcli >/dev/null 2>&1; then
        log "Preparing wireless interface..."
        nmcli device disconnect "$INTERFACE" 2>/dev/null || true
        nmcli dev set "$INTERFACE" managed no 2>/dev/null || true
        sleep 2
    fi
   
    # Validate interface exists
    if ! ip link show "$INTERFACE" >/dev/null 2>&1; then
        log "Interface $INTERFACE does not exist"
        exit 1
    fi
   
    # Configure interface
    sudo ip link set "$INTERFACE" down
    sleep 1
    sudo ip addr flush dev "$INTERFACE"
    sudo ip link set "$INTERFACE" up
    sudo ip addr add "$IP_ADDRESS" dev "$INTERFACE"
   
    # Start hostapd
    sudo systemctl unmask hostapd 2>/dev/null || true
    sudo systemctl enable hostapd --quiet
    if ! sudo systemctl start hostapd; then
        log "Failed to start hostapd. Check: systemctl status hostapd"
        exit 1
    fi
   
    # Start dnsmasq
    sudo systemctl enable dnsmasq --quiet
    if ! sudo systemctl restart dnsmasq; then
        log "Failed to start dnsmasq. Check: systemctl status dnsmasq"
        exit 1
    fi
   
    # Apply firewall rules
    log "Applying ZaaNet firewall rules..."
    if ! sudo "$FIREWALL_SCRIPT"; then
        log "Failed to apply firewall rules"
        exit 1
    fi
   
    log "ZaaNet captive portal mode activated."
}
# FUNCTION - STATUS CHECK
show_status() {
    echo "ZaaNet Status:"
    echo " Wi-Fi SSID: %WIFI_SSID%"
    echo " Portal IP: %PORTAL_IP%"
    echo " Interface: $INTERFACE"
    echo ""
   
    if systemctl is-active --quiet hostapd && systemctl is-active --quiet dnsmasq; then
        echo "Mode: ZaaNet Captive Portal Active"
        ip addr show "$INTERFACE" | grep inet || echo "No IP assigned"
    else
        echo "Mode: Normal Internet Mode"
    fi
   
    echo ""
    echo "Services:"
    echo " 📡 hostapd: $(systemctl is-active hostapd)"
    echo " 🌐 dnsmasq: $(systemctl is-active dnsmasq)"
    echo " 🔧 Network: $(ip link show "$INTERFACE" | grep "state UP" >/dev/null && echo "UP" || echo "DOWN")"
}
# Entry Point
case "$1" in
    --normal)
        to_normal_mode
        ;;
    --zaanet)
        to_zaanet_mode
        ;;
    --status)
        show_status
        ;;
    *)
        echo "Usage: $0 [--normal | --zaanet | --status]"
        echo ""
        echo "Commands:"
        echo " --zaanet Switch to captive portal mode"
        echo " --normal Switch to normal internet mode"
        echo " --status Show current status"
        exit 1
        ;;
esac
EOF
   
    # Replace placeholders with actual values
    sed -i "s|%WIRELESS_INTERFACE%|$WIRELESS_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-switcher.sh"
    sed -i "s|%PORTAL_IP%|$PORTAL_IP|g" "$ZAANET_DIR/scripts/zaanet-switcher.sh"
    sed -i "s|%DNS_SERVER%|$DNS_SERVER|g" "$ZAANET_DIR/scripts/zaanet-switcher.sh"
    sed -i "s|%PORTAL_PORT%|$PORTAL_PORT|g" "$ZAANET_DIR/scripts/zaanet-switcher.sh"
    sed -i "s|%ZAANET_DIR%|$ZAANET_DIR|g" "$ZAANET_DIR/scripts/zaanet-switcher.sh"
    sed -i "s|%WIFI_SSID%|$WIFI_SSID|g" "$ZAANET_DIR/scripts/zaanet-switcher.sh"
   
    success "✓ Network switcher script created"
}

# >>> Including functions/create_systemd_services.sh <<<
#!/bin/bash
# functions/create_systemd_services.sh
# Create systemd service files for ZaaNet

create_systemd_services() {
    log "🔧 Creating systemd services..."
    
    # Validate environment
    if [[ -z "$ZAANET_USER" ]]; then
        error "ZAANET_USER is empty!"
    fi
    
    if [[ -z "$ZAANET_DIR" ]]; then
        error "ZAANET_DIR is empty!"
    fi
    
    # Test write permissions
    if ! touch /etc/systemd/system/zaanet.service.test 2>/dev/null; then
        error "Cannot write to /etc/systemd/system/ - check permissions"
    fi
    rm -f /etc/systemd/system/zaanet.service.test
    
    # Create ZaaNet application service
    log "Creating zaanet.service..."
    
    cat > /etc/systemd/system/zaanet.service <<EOF
[Unit]
Description=ZaaNet Captive Portal Application
After=network.target zaanet-manager.service
Wants=network-online.target
Requires=zaanet-manager.service

[Service]
Type=simple
User=$ZAANET_USER
Group=$ZAANET_USER
WorkingDirectory=$ZAANET_DIR/app
ExecStart=/usr/bin/node server.js
Environment=NODE_ENV=production
Environment=ZAANET_DIR=$ZAANET_DIR
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=HOME=$ZAANET_DIR
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Verify zaanet.service
    if [[ ! -f /etc/systemd/system/zaanet.service || ! -s /etc/systemd/system/zaanet.service ]]; then
        error "zaanet.service file was not created properly"
    fi
    
    # Create ZaaNet network manager service
    log "Creating zaanet-manager.service..."
    
    cat > /etc/systemd/system/zaanet-manager.service <<EOF
[Unit]
Description=ZaaNet Network Manager
After=network.target
Before=zaanet.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$ZAANET_DIR/scripts/zaanet-switcher.sh --zaanet
ExecStop=$ZAANET_DIR/scripts/zaanet-switcher.sh --normal
TimeoutStartSec=120
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF
    
    # Verify zaanet-manager.service
    if [[ ! -f /etc/systemd/system/zaanet-manager.service || ! -s /etc/systemd/system/zaanet-manager.service ]]; then
        error "zaanet-manager.service file was not created properly"
    fi
    
    # Verify the switcher script exists
    if [[ ! -f "$ZAANET_DIR/scripts/zaanet-switcher.sh" ]]; then
        warning "⚠️ zaanet-switcher.sh not found at $ZAANET_DIR/scripts/zaanet-switcher.sh"
    else
        chmod +x "$ZAANET_DIR/scripts/zaanet-switcher.sh"
    fi
    
    # Reload systemd
    if ! systemctl daemon-reload; then
        error "Failed to reload systemd daemon"
    fi
    
    success "✅ Systemd services created successfully"
}
# >>> Including functions/create_system_user.sh <<<
#!/bin/bash
# functions/create_system_user.sh
# Create dedicated system user for ZaaNet

create_system_user() {
    log "👤 Creating ZaaNet system user..."
    
    # Check if user already exists
    if id "$ZAANET_USER" >/dev/null 2>&1; then
        log "User '$ZAANET_USER' already exists"
        return 0
    fi
    
    # Create system user
    useradd --system \
            --home-dir "$ZAANET_DIR" \
            --create-home \
            --shell /bin/false \
            --comment "ZaaNet Captive Portal Service" \
            "$ZAANET_USER"
    
    # Verify user creation
    if id "$ZAANET_USER" >/dev/null 2>&1; then
        success "✓ Created system user: $ZAANET_USER"
    else
        error "Failed to create user: $ZAANET_USER"
    fi
    
    # Set proper ownership
    chown -R "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR"
    
    success "✅ System user created successfully"
}
# >>> Including functions/get_essential_config.sh <<<
#!/bin/bash
# functions/get_essential_config.sh
# Get essential configuration from user

get_essential_config() {
    log "📝 Getting essential configuration..."
    
    echo ""
    echo -e "${CYAN}🔧 ZaaNet Configuration${NC}"
    echo ""
    
    # Contract ID (required)
    while [[ -z "$CONTRACT_ID" ]]; do
        read -p "Enter your contract/network ID: " CONTRACT_ID
        if [[ -z "$CONTRACT_ID" ]]; then
            echo -e "${RED}Contract ID is required!${NC}"
        fi
    done
    
    # Wi-Fi SSID (required)
    while [[ -z "$CUSTOM_SSID" ]]; do
        read -p "Enter Wi-Fi network name: " CUSTOM_SSID
        if [[ -z "$CUSTOM_SSID" ]]; then
            echo -e "${RED}Wi-Fi network name is required!${NC}"
        fi
    done
    WIFI_SSID="$CUSTOM_SSID"
    
    # Show summary
    echo ""
    echo -e "${CYAN}Configuration Summary:${NC}"
    echo "   Contract ID: $CONTRACT_ID"
    echo "   Wi-Fi SSID: $WIFI_SSID"
    echo "   Portal IP: $PORTAL_IP"
    echo "   Wireless Interface: $WIRELESS_INTERFACE"
    echo "   Internet Interface: $ETHERNET_INTERFACE"
    echo ""
    
    # Export variables
    export CONTRACT_ID
    export WIFI_SSID
    
    success "✅ Configuration complete"
}
# >>> Including functions/install_dependencies.sh <<<
#!/bin/bash
# functions/install_dependencies.sh

install_dependencies() {
    log "📦 Installing ZaaNet dependencies..."
    
    update_packages() {
        log "Updating package lists..."
        case "$PKG_MANAGER" in
            "apt") apt-get update -y ;;
            "yum") yum check-update || true ;;
            "dnf") dnf check-update || true ;;
            "pacman") pacman -Sy --noconfirm ;;
        esac
    }
    
    install_core_packages() {
    log "Installing core packages..."
    
    case "$PKG_MANAGER" in
        "apt")
            apt-get install -y \
                curl wget git unzip \
                build-essential \
                hostapd dnsmasq \
                iptables iptables-persistent \
                iw \
                systemd net-tools jq \
                python3 python3-pip python3-dev
            
            # Try libnetfilter-queue-dev (optional)
            apt-get install -y libnetfilter-queue-dev 2>/dev/null || \
            apt-get install -y libnetfilter-queue1 2>/dev/null || \
            log "libnetfilter-queue not available, continuing..."
            ;;
        "yum")
            yum install -y \
                curl wget git unzip \
                gcc gcc-c++ make \
                hostapd dnsmasq \
                iptables iptables-services \
                iw wireless-tools \
                systemd net-tools jq \
                python3 python3-pip python3-devel \
                libnetfilter_queue-devel
            ;;
        "dnf")
            dnf install -y \
                curl wget git unzip \
                gcc gcc-c++ make \
                hostapd dnsmasq \
                iptables iptables-services \
                iw wireless-tools \
                systemd net-tools jq \
                python3 python3-pip python3-devel \
                libnetfilter_queue-devel
            ;;
        "pacman")
            pacman -S --noconfirm \
                curl wget git unzip base-devel \
                hostapd dnsmasq iptables \
                iw wireless_tools \
                systemd net-tools jq \
                python python-pip \
                libnetfilter_queue
            ;;
    esac
}
    
    install_python_packages() {
        log "Installing Python packages for traffic monitoring..."
        
        # Install via pip
        if pip3 install netfilterqueue scapy 2>/dev/null; then
            success "✓ Python packages installed via pip"
        elif pip3 install --break-system-packages netfilterqueue scapy 2>/dev/null; then
            success "✓ Python packages installed via pip (with override)"
        else
            error "Failed to install Python packages"
            log "Manual fix: sudo apt install libnetfilter-queue-dev && sudo pip3 install --break-system-packages netfilterqueue scapy"
            exit 1
        fi
        
        # Verify
        if python3 -c "from netfilterqueue import NetfilterQueue; from scapy.all import IP" 2>/dev/null; then
            success "✓ Python packages verified"
        else
            error "Python package import failed"
            exit 1
        fi
    }
    
    install_nodejs() {
        if command -v node >/dev/null 2>&1; then
            log "Node.js already installed: $(node --version)"
            return 0
        fi
        
        log "Installing Node.js..."
        
        case "$PKG_MANAGER" in
            "apt")
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
                apt-get install -y nodejs
                ;;
            "yum"|"dnf")
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
                $PKG_MANAGER install -y nodejs
                ;;
            "pacman")
                pacman -S --noconfirm nodejs npm
                ;;
        esac
        
        command -v node >/dev/null 2>&1 && success "✓ Node.js installed: $(node --version)" || error "Failed to install Node.js"
    }
    
    install_pm2() {
        if command -v pm2 >/dev/null 2>&1; then
            log "PM2 already installed"
            return 0
        fi
        
        log "Installing PM2..."
        npm install -g pm2
        command -v pm2 >/dev/null 2>&1 && success "✓ PM2 installed" || error "Failed to install PM2"
    }
    
    verify_services() {
        log "Verifying critical services..."
        
        local services=("hostapd" "dnsmasq" "python3" "node")
        local missing=()
        
        for service in "${services[@]}"; do
            if command -v "$service" >/dev/null 2>&1; then
                success "✓ $service"
            else
                missing+=("$service")
                error "✗ $service not found"
            fi
        done
        
        [[ ${#missing[@]} -eq 0 ]] || { error "Missing: ${missing[*]}"; exit 1; }
    }
    
    # Execute
    update_packages
    install_core_packages
    install_python_packages
    install_nodejs
    install_pm2
    verify_services
    
    success "✅ All dependencies installed"
}

# >>> Including functions/set_permissions.sh <<<
#!/bin/bash
# functions/set_permissions.sh
# Set proper file permissions and ownership for ZaaNet

set_permissions() {
    log "🔒 Setting file permissions and ownership..."
    
    # =============================================================================
    # VALIDATE ENVIRONMENT
    # =============================================================================
    
    if [[ -z "$ZAANET_USER" ]]; then
        error "ZAANET_USER is not set"
    fi
    
    if [[ -z "$ZAANET_DIR" ]]; then
        error "ZAANET_DIR is not set"
    fi
    
    if [[ ! -d "$ZAANET_DIR" ]]; then
        error "ZaaNet directory does not exist: $ZAANET_DIR"
    fi
    
    # =============================================================================
    # SET DIRECTORY OWNERSHIP
    # =============================================================================
    
    log "Setting directory ownership..."
    
    # Set ownership of main directory
    if chown -R "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR"; then
        success "✓ Directory ownership set to $ZAANET_USER"
    else
        error "Failed to set directory ownership"
    fi
    
    # =============================================================================
    # SET SCRIPT PERMISSIONS
    # =============================================================================
    
    log "Setting script permissions..."
    
    # Make scripts executable
    if [[ -d "$ZAANET_DIR/scripts" ]]; then
        if chmod +x "$ZAANET_DIR/scripts"/*.sh 2>/dev/null; then
            success "✓ Scripts made executable"
        else
            warning "No script files found or permission setting failed"
        fi
    else
        warning "Scripts directory not found: $ZAANET_DIR/scripts"
    fi
    
    # =============================================================================
    # SET APPLICATION PERMISSIONS
    # =============================================================================
    
    log "Setting application file permissions..."
    
    # Application directory permissions
    if [[ -d "$ZAANET_DIR/app" ]]; then
        chmod 755 "$ZAANET_DIR/app"
        find "$ZAANET_DIR/app" -type f -name "*.js" -exec chmod 644 {} \;
        find "$ZAANET_DIR/app" -type d -exec chmod 755 {} \;
    fi
    
    # Configuration files (more restrictive)
    if [[ -f "$ZAANET_DIR/app/.env" ]]; then
        chmod 600 "$ZAANET_DIR/app/.env"
        log "✓ Environment file secured (600)"
    fi
    
    if [[ -d "$ZAANET_DIR/configs" ]]; then
        chmod 700 "$ZAANET_DIR/configs"
        find "$ZAANET_DIR/configs" -type f -exec chmod 600 {} \;
        log "✓ Configuration files secured"
    fi
    
    # =============================================================================
    # CREATE AND SET LOG FILE PERMISSIONS
    # =============================================================================
    
    log "Setting up log files..."
    
    # Create log files with proper permissions
    local log_files=(
        "/var/log/zaanet.log"
        "/var/log/zaanet-firewall.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if touch "$log_file"; then
            chown "$ZAANET_USER:$ZAANET_USER" "$log_file"
            chmod 644 "$log_file"
            log "✓ Created and configured: $(basename "$log_file")"
        else
            warning "Failed to create log file: $log_file"
        fi
    done
    
    # Create ZaaNet log directory if needed
    if [[ -d "$ZAANET_DIR/logs" ]]; then
        chmod 755 "$ZAANET_DIR/logs"
        chown "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR/logs"
    fi
    
    # =============================================================================
    # SET DATA DIRECTORY PERMISSIONS
    # =============================================================================
    
    log "Setting data directory permissions..."
    
    if [[ -d "$ZAANET_DIR/data" ]]; then
        chmod 700 "$ZAANET_DIR/data"
        log "✓ Data directory secured (700)"
    fi
    
    if [[ -d "$ZAANET_DIR/backups" ]]; then
        chmod 700 "$ZAANET_DIR/backups"
        log "✓ Backup directory secured (700)"
    fi
    
    # =============================================================================
    # SET SYSTEM PERMISSIONS FOR ZAANET OPERATIONS
    # =============================================================================
    
    configure_system_permissions() {
        log "Configuring system permissions for ZaaNet operations..."
        
        # Add zaanet user to sudoers for iptables access
        local sudoers_file="/etc/sudoers.d/zaanet"
        cat > "$sudoers_file" <<EOF
# ZaaNet user permissions for firewall management
# Allow zaanet user to run iptables without password
zaanet ALL=(ALL) NOPASSWD: /sbin/iptables, /usr/sbin/iptables, /bin/iptables, /usr/bin/iptables
zaanet ALL=(ALL) NOPASSWD: /sbin/ip6tables, /usr/sbin/ip6tables, /bin/ip6tables, /usr/bin/ip6tables
EOF
        chmod 440 "$sudoers_file"
        
        # Give Node.js capability to bind to privileged ports
        if command -v setcap >/dev/null 2>&1; then
            setcap 'cap_net_bind_service=+ep' /usr/bin/node
            log "✓ Node.js granted capability to bind to privileged ports"
        else
            warning "setcap not available - Node.js may not be able to bind to port 80"
        fi
        
        # Add zaanet user to network-related groups
        usermod -a -G netdev "$ZAANET_USER" 2>/dev/null || true
        usermod -a -G dialout "$ZAANET_USER" 2>/dev/null || true
        
        success "✓ System permissions configured"
    }
    
    verify_permissions() {
        log "Verifying permissions..."
        
        # Check if zaanet user owns the directory
        local owner=$(stat -c '%U' "$ZAANET_DIR" 2>/dev/null)
        if [[ "$owner" == "$ZAANET_USER" ]]; then
            success "✓ Directory ownership verified"
        else
            warning "Directory owner is '$owner', expected '$ZAANET_USER'"
        fi
        
        # Check script executability
        local script_count=0
        if [[ -d "$ZAANET_DIR/scripts" ]]; then
            script_count=$(find "$ZAANET_DIR/scripts" -name "*.sh" -executable | wc -l)
            if [[ $script_count -gt 0 ]]; then
                success "✓ Found $script_count executable scripts"
            fi
        fi
        
        # Check sensitive file permissions
        if [[ -f "$ZAANET_DIR/app/.env" ]]; then
            local env_perms=$(stat -c '%a' "$ZAANET_DIR/app/.env" 2>/dev/null)
            if [[ "$env_perms" == "600" ]]; then
                success "✓ Environment file properly secured"
            else
                warning "Environment file permissions: $env_perms (should be 600)"
            fi
        fi
    }
    
    # =============================================================================
    # RUN PERMISSION CONFIGURATION
    # =============================================================================
    
    configure_system_permissions
    verify_permissions
    
    success "✅ Permissions configured successfully"
}

# >>> Including functions/setup_application.sh <<<
#!/bin/bash
# functions/setup_application.sh
# Setup ZaaNet application and configuration

setup_application() {
    log "📱 Setting up ZaaNet application..."
    
    # =============================================================================
    # CREATE DIRECTORY STRUCTURE
    # =============================================================================
    
    create_directory_structure() {
        log "Creating directory structure..."
        
        local directories=(
            "$ZAANET_DIR"
            "$ZAANET_DIR/app"
            "$ZAANET_DIR/scripts"
            "$ZAANET_DIR/configs"
            "$ZAANET_DIR/logs"
            "$ZAANET_DIR/data"
            "$ZAANET_DIR/backups"
            "$ZAANET_DIR/tmp"
        )
        
        for dir in "${directories[@]}"; do
            if mkdir -p "$dir"; then
                log "✓ Created: $dir"
            else
                error "Failed to create directory: $dir"
            fi
        done
    }
    
    # =============================================================================
    # DOWNLOAD APPLICATION
    # =============================================================================
    
    download_application() {
        if [[ -d "$ZAANET_DIR/app/.git" ]]; then
            log "Updating existing ZaaNet application..."
            cd "$ZAANET_DIR/app" || error "Cannot access app directory"
            
            if git pull; then
                success "✓ Application updated"
            else
                warning "Failed to update application - continuing with current version"
            fi
        else
            log "Downloading ZaaNet application..."
            
            # Remove any existing files
            rm -rf "$ZAANET_DIR/app"/*
            
            if git clone "$GITHUB_REPO" "$ZAANET_DIR/app"; then
                success "✓ Application downloaded"
            else
                error "Failed to download ZaaNet application. Check internet connection and repository URL: $GITHUB_REPO"
            fi
        fi
    }
    
    # =============================================================================
    # INSTALL NODE DEPENDENCIES
    # =============================================================================
    
    install_node_dependencies() {
        log "Installing Node.js dependencies..."
        
        cd "$ZAANET_DIR/app" || error "Cannot access app directory"
        
        # Check if package.json exists
        if [[ ! -f "package.json" ]]; then
            error "package.json not found in application directory"
        fi
        
        # Install dependencies
        if npm install --production; then
            success "✓ Node.js dependencies installed"
        else
            error "Failed to install Node.js dependencies"
        fi
    }
    
    # =============================================================================
    # CREATE ENVIRONMENT CONFIGURATION
    # =============================================================================
    
    create_environment_config() {
        log "Creating environment configuration..."
        
        local env_file="$ZAANET_DIR/app/.env"
        
        cat > "$env_file" <<EOF
# ZaaNet Configuration - Auto-generated by installer
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
PORTAL_IP=$PORTAL_IP
PORTAL_PORT=$PORTAL_PORT
PORTAL_DOMAIN=$PORTAL_DOMAIN
WIRELESS_INTERFACE=$WIRELESS_INTERFACE
ETHERNET_INTERFACE=$ETHERNET_INTERFACE
DNS_SERVER=$DNS_SERVER

# =============================================================================
# WIFI HOTSPOT SETTINGS
# =============================================================================
WIFI_SSID=$WIFI_SSID
DHCP_START=$DHCP_START
DHCP_END=$DHCP_END

# =============================================================================
# SERVICE CONFIGURATION
# =============================================================================
CONTRACT_ID=$CONTRACT_ID
MAIN_SERVER_URL=$MAIN_SERVER_URL
NODE_ENV=production

# =============================================================================
# SYSTEM INFORMATION
# =============================================================================
INSTALLER_VERSION=1.0.0
INSTALL_DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
DEVICE_MODEL=${DEVICE_MODEL:-Unknown}
DEVICE_TYPE=${DEVICE_TYPE:-Unknown}

# =============================================================================
# PATHS
# =============================================================================
ZAANET_DIR=$ZAANET_DIR
LOG_DIR=$ZAANET_DIR/logs
DATA_DIR=$ZAANET_DIR/data
CONFIG_DIR=$ZAANET_DIR/configs
EOF
        
        # Set proper permissions
        chmod 600 "$env_file"
        
        success "✓ Environment configuration created"
    }
    
    # =============================================================================
    # CREATE APPLICATION CONFIG
    # =============================================================================
    
    create_app_config() {
        log "Creating application configuration..."
        
        local config_file="$ZAANET_DIR/configs/zaanet.json"
        
        cat > "$config_file" <<EOF
{
  "version": "1.0.0",
  "contract_id": "$CONTRACT_ID",
  "network": {
    "ssid": "$WIFI_SSID",
    "portal_ip": "$PORTAL_IP",
    "portal_port": $PORTAL_PORT,
    "portal_domain": "$PORTAL_DOMAIN",
    "wireless_interface": "$WIRELESS_INTERFACE",
    "ethernet_interface": "$ETHERNET_INTERFACE",
    "dhcp_range": {
      "start": "$DHCP_START",
      "end": "$DHCP_END"
    },
    "dns_server": "$DNS_SERVER"
  },
  "server": {
    "main_url": "$MAIN_SERVER_URL"
  },
  "system": {
    "install_date": "$(date -u '+%Y-%m-%d %H:%M:%S UTC')",
    "device_type": "${DEVICE_TYPE:-Unknown}",
    "auto_start": "${AUTO_START:-yes}"
  },
  "paths": {
    "app_dir": "$ZAANET_DIR/app",
    "log_dir": "$ZAANET_DIR/logs",
    "data_dir": "$ZAANET_DIR/data",
    "config_dir": "$ZAANET_DIR/configs"
  }
}
EOF
        
        success "✓ Application configuration created"
    }
    
    # =============================================================================
    # VERIFY APPLICATION
    # =============================================================================
    
    verify_application() {
        log "Verifying application setup..."
        
        local required_files=(
            "$ZAANET_DIR/app/package.json"
            "$ZAANET_DIR/app/.env"
            "$ZAANET_DIR/configs/zaanet.json"
        )
        
        for file in "${required_files[@]}"; do
            if [[ -f "$file" ]]; then
                log "✓ Found: $(basename "$file")"
            else
                error "Missing required file: $file"
            fi
        done
        
        # Test Node.js app can start
        cd "$ZAANET_DIR/app" || error "Cannot access app directory"
        
        if [[ -f "app.js" ]] || [[ -f "index.js" ]] || [[ -f "server.js" ]]; then
            success "✓ Application entry point found"
        else
            warning "No standard entry point found (app.js, index.js, server.js)"
        fi
    }
    
    # =============================================================================
    # RUN SETUP STEPS
    # =============================================================================
    
    create_directory_structure
    download_application
    install_node_dependencies
    create_environment_config
    create_app_config
    verify_application
    
    success "✅ ZaaNet application setup completed"
}
# >>> Including functions/show_completion.sh <<<
#!/bin/bash
# functions/show_completion.sh
# Display installation completion message and instructions

show_completion() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║            ZaaNet Installation Complete!                     ║
║                Ready for Production Use                      ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    
    # =============================================================================
    # CONFIGURATION SUMMARY
    # =============================================================================
    
    echo -e "${CYAN}Configuration Summary:${NC}"
    echo "   Wi-Fi Network: $WIFI_SSID"
    echo "   Portal IP: $PORTAL_IP"
    echo "   Wireless Interface: $WIRELESS_INTERFACE"
    echo "   Internet Interface: $ETHERNET_INTERFACE"
    echo "   Contract ID: $CONTRACT_ID"
    echo ""
    
    # =============================================================================
    # QUICK START INSTRUCTIONS
    # =============================================================================
    
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "   sudo zaanet start"
    echo ""
    
    # =============================================================================
    # USER CONNECTION STEPS
    # =============================================================================
    
    echo -e "${YELLOW}For Users to Connect:${NC}"
    echo "   1. Connect to Wi-Fi: '$WIFI_SSID'"
    echo "   2. Open any website in browser"
    echo "   3. Get redirected to captive portal"
    echo "   4. Complete authentication"
    echo "   5. Enjoy internet access"
    echo ""
    
    # =============================================================================
    # MANAGEMENT COMMANDS
    # =============================================================================
    
    echo -e "${YELLOW}Management Commands:${NC}"
    echo "   zaanet status      # Check current status"
    echo "   zaanet stop        # Return to normal internet"
    echo "   zaanet restart     # Restart services"
    echo "   zaanet logs        # View live logs"
    echo "   zaanet config      # Show configuration"
    echo "   zaanet firewall    # Manage user access"
    echo ""
    
    # =============================================================================
    # AUTO-START STATUS
    # =============================================================================
    
    echo -e "${BLUE}Auto-start Configuration:${NC}"
    if [[ "$AUTO_START" =~ ^[Yy] ]]; then
        echo "   Auto-start enabled - portal will start on boot"
    else
        echo "   Auto-start disabled"
        echo "   To enable: sudo zaanet enable"
    fi
    echo ""
    
    # =============================================================================
    # IMPORTANT FILE LOCATIONS
    # =============================================================================
    
    echo -e "${BLUE}Important Locations:${NC}"
    echo "   Application: $ZAANET_DIR/app"
    echo "   Configuration: $ZAANET_DIR/app/.env"
    echo "   Scripts: $ZAANET_DIR/scripts"
    echo "   Logs: /var/log/zaanet*.log"
    echo ""
    
    # =============================================================================
    # TESTING INSTRUCTIONS
    # =============================================================================
    
    echo -e "${PURPLE}Test Your Installation:${NC}"
    echo "   1. Start the portal: sudo zaanet start"
    echo "   2. Check status: zaanet status"
    echo "   3. Connect a device to '$WIFI_SSID'"
    echo "   4. Open browser - should redirect to portal"
    echo "   5. View logs: zaanet logs"
    echo ""
    
    # =============================================================================
    # TROUBLESHOOTING TIPS
    # =============================================================================
    
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "   Service issues: systemctl status zaanet zaanet-manager"
    echo "   Network issues: ip addr show $WIRELESS_INTERFACE"
    echo "   Firewall issues: iptables -L"
    echo "   Application logs: journalctl -u zaanet"
    echo ""
    
    # =============================================================================
    # NEXT STEPS
    # =============================================================================
    
    echo -e "${GREEN}Next Steps:${NC}"
    echo "   1. Test the installation with a device"
    echo "   2. Configure user authentication flow"
    echo ""
    
    echo -e "${GREEN}Documentation: https://docs.zaanet.xyz${NC}"
    echo ""
}
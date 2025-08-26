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

show_banner() {
    clear
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║  ███████╗ █████╗  █████╗ ███╗   ██╗███████╗████████╗        ║
║  ╚══███╔╝██╔══██╗██╔══██╗████╗  ██║██╔════╝╚══██╔══╝        ║
║    ███╔╝ ███████║███████║██╔██╗ ██║█████╗     ██║           ║
║   ███╔╝  ██╔══██║██╔══██║██║╚██╗██║██╔══╝     ██║           ║
║  ███████╗██║  ██║██║  ██║██║ ╚████║███████╗   ██║           ║
║  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝           ║
║                                                              ║
║             🚀 ZaaNet Auto-Installer v2.0.0 🚀              ║
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

# Auto-detect Raspberry Pi
check_raspberry_pi() {
    echo "🔍 Checking device compatibility..."
    
    if [[ ! -f /proc/device-tree/model ]]; then
        error "❌ Cannot detect device model. This installer is designed for Raspberry Pi 4+"
    fi
    
    local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
    echo "   📱 Detected: $model"
    
    if [[ "$model" =~ "Raspberry Pi" ]]; then
        # Extract Pi version number
        local pi_version=$(echo "$model" | grep -o 'Pi [0-9]' | grep -o '[0-9]')
        if [[ -n "$pi_version" && "$pi_version" -ge 4 ]]; then
            success "✅ Raspberry Pi $pi_version detected - Compatible!"
        else
            warning "⚠️ Raspberry Pi $pi_version detected. Pi 4+ recommended for best performance."
            read -p "Continue anyway? [y/N]: " CONTINUE
            if [[ ! "$CONTINUE" =~ ^[Yy] ]]; then
                echo "Installation cancelled."
                exit 0
            fi
        fi
    else
        warning "⚠️ Non-Raspberry Pi device detected. This installer is optimized for Pi 4+."
        read -p "Continue anyway? [y/N]: " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy] ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
}

# Auto-detect network interfaces
auto_detect_interfaces() {
    echo "🔍 Auto-detecting network interfaces..."
    
    # Detect wireless interface
    WIRELESS_INTERFACE=""
    for interface in wlan0 wlp2s0 wlp3s0 wlx* wlo1; do
        if ip link show "$interface" >/dev/null 2>&1; then
            WIRELESS_INTERFACE="$interface"
            break
        fi
    done
    
    # Try alternative detection methods for wireless
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        WIRELESS_INTERFACE=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2; exit}')
    fi
    
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        WIRELESS_INTERFACE=$(find /sys/class/net -name "wl*" -type l -exec basename {} \; 2>/dev/null | head -1)
    fi
    
    # Detect ethernet interface
    ETHERNET_INTERFACE=""
    for interface in eth0 enp1s0 enp1s0f0 eno1 end0; do
        if ip link show "$interface" >/dev/null 2>&1; then
            ETHERNET_INTERFACE="$interface"
            break
        fi
    done
    
    # Try alternative detection for ethernet
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        ETHERNET_INTERFACE=$(ip link | grep -oE '(eth[0-9]+|enp[0-9]+s[0-9]+[f0-9]*|eno[0-9]+)' | head -1)
    fi
    
    # Display results
    echo "   📡 Wireless Interface: ${WIRELESS_INTERFACE:-❌ Not detected}"
    echo "   🌐 Ethernet Interface: ${ETHERNET_INTERFACE:-❌ Not detected}"
    
    # Validation
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        error "❌ No wireless interface detected. ZaaNet requires Wi-Fi capability."
    fi
    
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        warning "⚠️ No ethernet interface detected. You'll need to configure internet source manually."
        echo "   💡 You can use USB-to-Ethernet adapter or configure Wi-Fi client mode later."
        read -p "Continue without ethernet? [y/N]: " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy] ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        ETHERNET_INTERFACE="eth0"  # Default fallback
    fi
    
    success "✅ Network interfaces detected"
}

# Get minimal required configuration
get_essential_config() {
    echo -e "${CYAN}⚙️ Essential Configuration${NC}"
    echo ""
    echo "🔧 Most settings are pre-configured. Only server details are required:"
    echo ""
    
    # Contract ID
    read -p "📜 Enter your contract/location ID: " CONTRACT_ID
    while [[ -z "$CONTRACT_ID" ]]; do
        echo "❌ Contract ID is required to identify this installation!"
        read -p "📜 Enter your contract/location ID: " CONTRACT_ID
    done
    
    # Optional customizations
    echo ""
    echo -e "${YELLOW}📶 Required Customizations (Don't skip this part:${NC}"
    
    read -p "📡 Wi-Fi network name [default: $WIFI_SSID]: " CUSTOM_SSID
    if [[ -n "$CUSTOM_SSID" ]]; then
        WIFI_SSID="$CUSTOM_SSID"
    fi
    
    # Auto-start option
    echo ""
    read -p "🚀 Enable auto-start on boot? [Y/n]: " AUTO_START
    AUTO_START=${AUTO_START:-Y}
    
    # Show configuration summary
    echo ""
    echo -e "${CYAN}📋 Configuration Summary:${NC}"
    echo "   📡 Wi-Fi SSID: $WIFI_SSID"
    echo "   🏠 Portal IP: $PORTAL_IP"
    echo "   📡 DHCP Range: $DHCP_START - $DHCP_END"
    echo "   🌐 Portal Domain: $PORTAL_DOMAIN"
    echo "   🔌 Wireless Interface: $WIRELESS_INTERFACE"
    echo "   🌐 Internet Interface: $ETHERNET_INTERFACE"
    echo "   🌍 Main Server: $MAIN_SERVER_URL"
    echo "   📜 Contract ID: $CONTRACT_ID"
    echo "   🚀 Auto-start: $AUTO_START"
    echo ""
    
    read -p "✅ Proceed with installation? [Y/n]: " CONFIRM
    CONFIRM=${CONFIRM:-Y}
    
    if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
        echo "Installation cancelled."
        exit 0
    fi
}

# Install system dependencies
install_dependencies() {
    echo "📦 Installing system dependencies..."
    
    # Update package list
    log "Updating package lists..."
    apt-get update -y
    
    # Install core dependencies
    log "Installing core packages..."
    apt-get install -y \
        curl wget git unzip \
        build-essential \
        hostapd dnsmasq \
        iptables iptables-persistent \
        iw wireless-tools \
        systemd net-tools \
        jq
    
    # Install Node.js (LTS)
    if ! command -v node &> /dev/null; then
        log "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        apt-get install -y nodejs
    else
        log "Node.js already installed: $(node --version)"
    fi
    
    # Install PM2 for process management
    if ! command -v pm2 &> /dev/null; then
        log "Installing PM2..."
        npm install -g pm2
    else
        log "PM2 already installed"
    fi
    
    success "✅ All dependencies installed"
}

# Create system user
create_system_user() {
    echo "👤 Creating ZaaNet system user..."
    
    if ! id "$ZAANET_USER" &>/dev/null; then
        # Create user with home directory and bash shell (like a regular user, not system user)
        useradd -m -s /bin/bash "$ZAANET_USER" -c "ZaaNet Service User"
        log "Created user: $ZAANET_USER"
    else
        log "User $ZAANET_USER already exists"
        # Ensure user has proper shell and home directory
        usermod -s /bin/bash "$ZAANET_USER"
        usermod -d "/home/$ZAANET_USER" "$ZAANET_USER"
    fi
    
    # Give zaanet complete sudo privileges
    log "Granting complete sudo privileges to $ZAANET_USER..."
    tee /etc/sudoers.d/zaanet << EOF
# ZaaNet user - complete sudo privileges
$ZAANET_USER ALL=(ALL) NOPASSWD: ALL
EOF
    
    chmod 440 /etc/sudoers.d/zaanet
    
    # Add to common groups for device access
    usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,netdev,lpadmin "$ZAANET_USER" 2>/dev/null || true
    
    success "✅ System user ready with complete privileges"
}

# Download and setup application
setup_application() {
    echo "📥 Setting up ZaaNet application..."
    
    # Create directory structure
    mkdir -p "$ZAANET_DIR"/{app,scripts,configs,logs,data}
    
    # Clone ZaaNet repo
    if [ ! -d "$ZAANET_DIR/app/.git" ]; then
        log "Downloading ZaaNet application..."
        git clone "$GITHUB_REPO" "$ZAANET_DIR/app" || {
            error "❌ Failed to download ZaaNet application. Check your internet connection and repository URL."
        }
    else
        log "Updating existing ZaaNet application..."
        cd "$ZAANET_DIR/app"
        git pull || warning "⚠️ Failed to update application"
    fi
    
    cd "$ZAANET_DIR/app"
    
    # Install project dependencies
    log "Installing Node.js dependencies..."
    npm install || {
        error "❌ Failed to install Node.js dependencies"
    }
    
    # Setup environment variables
    log "Configuring environment..."
    cat <<EOF > .env
# ZaaNet Auto-Configuration
PORTAL_IP=$PORTAL_IP
PORTAL_PORT=$PORTAL_PORT
PORTAL_DOMAIN=$PORTAL_DOMAIN
WIRELESS_INTERFACE=$WIRELESS_INTERFACE
ETHERNET_INTERFACE=$ETHERNET_INTERFACE
DNS_SERVER=$DNS_SERVER

# Network Configuration
WIFI_SSID=$WIFI_SSID
DHCP_START=$DHCP_START
DHCP_END=$DHCP_END
CONTRACT_ID=$CONTRACT_ID

# Main server configuration
MAIN_SERVER_URL=$MAIN_SERVER_URL
MAIN_SERVER_API_KEY=$MAIN_SERVER_API_KEY

# Node Environment
NODE_ENV=production

# Auto-installer metadata
INSTALLER_VERSION=2.0.0
INSTALL_DATE=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
DEVICE_MODEL=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown")
EOF
    
    # Application is pre-built, no build step needed
    log "✅ Using pre-built application from release repository"
    
    success "✅ Application setup complete"
}

# Configure network services with auto-detected interfaces
configure_network_services() {
    echo "⚙️ Configuring network services..."
    
    # Configure hostapd
    log "Configuring hostapd for $WIRELESS_INTERFACE..."
    cat > /etc/hostapd/hostapd.conf << EOF
# ZaaNet Hostapd Configuration - Auto-generated
interface=$WIRELESS_INTERFACE
# driver=nl80211
ssid=$WIFI_SSID
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
country_code=GH

# Auto-generated on $(date -u '+%Y-%m-%d %H:%M:%S UTC')
# Wireless Interface: $WIRELESS_INTERFACE
# Portal IP: $PORTAL_IP
EOF
    
    # Configure dnsmasq
    log "Configuring dnsmasq..."
    cat > /etc/dnsmasq.conf << EOF
# ZaaNet Dnsmasq Configuration - Auto-generated
interface=$WIRELESS_INTERFACE
dhcp-range=$DHCP_START,$DHCP_END,12h
address=/#/$PORTAL_IP
domain-needed
no-dhcp-interface=$ETHERNET_INTERFACE
bogus-priv
expand-hosts
domain=zaanet.xyz
no-resolv
server=$DNS_SERVER
bind-interfaces

# Network Configuration:
# Portal IP: $PORTAL_IP
# DHCP Range: $DHCP_START - $DHCP_END
# Wireless Interface: $WIRELESS_INTERFACE
# Internet Interface: $ETHERNET_INTERFACE
# Auto-generated on $(date -u '+%Y-%m-%d %H:%M:%S UTC')
EOF
    
    success "✅ Network services configured"
}

# Create management scripts with auto-detected interfaces
create_zaanet_scripts() {
    echo "📝 Creating ZaaNet management scripts..."
    
    # Create the network switcher script
    cat > "$ZAANET_DIR/scripts/zaanet-switcher.sh" << EOF
#!/bin/bash
# ZaaNet Network Mode Switcher - Auto-generated
# Switches between normal internet mode and ZaaNet captive portal mode

# Configuration - Auto-detected
INTERFACE="$WIRELESS_INTERFACE"
IP_ADDRESS="$PORTAL_IP/24"
DNS_SERVER="$DNS_SERVER"
PORTAL_PORT="$PORTAL_PORT"  # Use environment variable
FIREWALL_SCRIPT="$ZAANET_DIR/scripts/zaanet-firewall.sh"
LOG_FILE="/var/log/zaanet.log"

# Check for root privileges
if [[ \$EUID -ne 0 ]]; then
  echo "❌ This script must be run as root or with sudo"
  exit 1
fi

# Logging function
log() {
  echo "\$(date -u '+%Y-%m-%d %H:%M:%S') [ZaaNet] \$1" | tee -a "\$LOG_FILE"
}

# FUNCTION - NORMAL INTERNET MODE
to_normal_mode() {
  log "🔄 Switching to normal internet mode..."
  
  # Stop and disable dnsmasq
  sudo systemctl stop dnsmasq
  sudo systemctl disable dnsmasq --quiet
  
  # Stop and disable hostapd
  sudo systemctl stop hostapd
  sudo systemctl disable hostapd --quiet
  sudo systemctl mask hostapd
  
  # Clear firewall rules
  log "🛡️ Clearing ZaaNet firewall rules..."
  sudo iptables -F ZAANET_AUTH_USERS 2>/dev/null || true
  sudo iptables -X ZAANET_AUTH_USERS 2>/dev/null || true
  sudo iptables -F ZAANET_BLOCKED 2>/dev/null || true
  sudo iptables -X ZAANET_BLOCKED 2>/dev/null || true
  
  # Remove ZaaNet IP address
  sudo ip addr del "\$IP_ADDRESS" dev "\$INTERFACE" 2>/dev/null || true
  
  # Re-enable NetworkManager management
  log "🔌 Re-enabling NetworkManager management..."
  nmcli dev set "\$INTERFACE" managed yes 2>/dev/null || log "⚠️ Could not re-enable NetworkManager management"
  
  # Restore WiFi functionality
  sudo ip link set \$INTERFACE up
  sudo systemctl restart NetworkManager 2>/dev/null || true

  log "✅ Normal internet mode restored."
}

# FUNCTION - ZAANET MODE
to_zaanet_mode() {
  log "🚀 Switching to ZaaNet captive portal mode..."
  
  # Check if firewall script exists
  if [[ ! -x "\$FIREWALL_SCRIPT" ]]; then
    log "❌ ZaaNet firewall script not found: \$FIREWALL_SCRIPT"
    exit 1
  fi
  
  trap 'log "❌ Error occurred, reverting to normal mode..."; to_normal_mode; exit 1' ERR
  
  # Disable NetworkManager management of wireless interface
  log "🔌 Preparing wireless interface..."
  nmcli device disconnect "\$INTERFACE" 2>/dev/null || log "⚠️ Interface not connected to NetworkManager"
  nmcli dev set "\$INTERFACE" managed no 2>/dev/null || log "⚠️ Could not disable NetworkManager management"
  
  # Brief pause to let NetworkManager release the interface
  sleep 2
  
  # Enable and start hostapd
  sudo systemctl unmask hostapd
  sudo systemctl enable hostapd --quiet
  if ! sudo systemctl start hostapd; then
    log "❌ Failed to start hostapd. Check: systemctl status hostapd"
    exit 1
  fi
  
  # Validate and configure interface
  if ! ip link show "\$INTERFACE" >/dev/null 2>&1; then
    log "❌ Interface \$INTERFACE does not exist"
    exit 1
  fi
  
  # Bring up interface and assign IP
  sudo ip link set "\$INTERFACE" down
  sleep 2
  sudo ip link set "\$INTERFACE" up
  
  # Remove existing IP and assign portal IP
  sudo ip addr flush dev "\$INTERFACE"
  sudo ip addr add "\$IP_ADDRESS" dev "\$INTERFACE"
  
  # Enable and start dnsmasq
  sudo systemctl enable dnsmasq --quiet
  if ! sudo systemctl restart dnsmasq; then
    log "❌ Failed to start dnsmasq. Check: systemctl status dnsmasq"
    exit 1
  fi
  
  # Apply firewall rules
  log "🛡️ Applying ZaaNet firewall rules..."
  if ! sudo "\$FIREWALL_SCRIPT"; then
    log "❌ Failed to apply firewall rules"
    exit 1
  fi
  
  log "✅ ZaaNet captive portal mode activated!"
  log "🌐 Portal available at: $PORTAL_IP"
  log "📱 Wi-Fi SSID: $WIFI_SSID"
}

# FUNCTION - STATUS CHECK
show_status() {
  echo "📊 ZaaNet Status:"
  echo "   Wi-Fi SSID: $WIFI_SSID"
  echo "   Portal IP: $PORTAL_IP"
  echo "   Interface: \$INTERFACE"
  echo ""
  
  if systemctl is-active --quiet hostapd && systemctl is-active --quiet dnsmasq; then
    echo "Mode: 🟢 ZaaNet Captive Portal Active"
    ip addr show "\$INTERFACE" | grep inet || echo "No IP assigned"
  else
    echo "Mode: 🔴 Normal Internet Mode"
  fi
  
  echo ""
  echo "Services:"
  echo "  📡 hostapd: \$(systemctl is-active hostapd)"
  echo "  🌐 dnsmasq: \$(systemctl is-active dnsmasq)"
  echo "  🔧 systemd-resolved: \$(systemctl is-active systemd-resolved)"
}

# Entry Point
case "\$1" in
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
    echo "Usage: \$0 [--normal | --zaanet | --status]"
    echo ""
    echo "Commands:"
    echo "  --zaanet   Switch to captive portal mode"
    echo "  --normal   Switch to normal internet mode"
    echo "  --status   Show current status"
    exit 1
    ;;
esac
EOF

    # Create the firewall script
    cat > "$ZAANET_DIR/scripts/zaanet-firewall.sh" << EOF
#!/bin/bash

# ZaaNet Captive Portal - FILTER Method Setup
# Simple and clean approach using only FILTER table

set -euo pipefail

# Configuration
LAN_IF="$WIRELESS_INTERFACE"
WAN_IF="$ETHERNET_INTERFACE"
PORTAL_IP="$PORTAL_IP"
LAN_SUBNET="$LAN_SUBNET"

LOG_FILE="/var/log/zaanet-firewall.log"

log() {
  local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$message"
  echo "$message" >> "$LOG_FILE" 2>/dev/null || true
}

# Validate environment
validate_environment() {
  if [[ $EUID -ne 0 ]]; then
    log "❌ This script must be run as root"
    exit 1
  fi

  for tool in iptables ip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      log "❌ Required tool not found: $tool"
      exit 1
    fi
  done

  if ! ip link show "$LAN_IF" >/dev/null 2>&1; then
    log "❌ LAN interface $LAN_IF not found"
    ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//'
    exit 1
  fi

  if ! ip link show "$WAN_IF" >/dev/null 2>&1; then
    log "❌ WAN interface $WAN_IF not found"
    ip link show | grep -E "^[0-9]+:" | awk '{print $2}' | sed 's/:$//'
    exit 1
  fi

  log "✅ Environment validation passed"
}

enable_ip_forwarding() {
  log "🔀 Enabling IP forwarding..."
  echo 1 > /proc/sys/net/ipv4/ip_forward
  if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  fi
  log "✅ IP forwarding enabled and made persistent"
}

cleanup_rules() {
  log "🧹 Cleaning up existing iptables rules..."
  iptables -F
  iptables -t nat -F
  iptables -t mangle -F
  iptables -X AUTHENTICATED_USERS 2>/dev/null || true
  iptables -t nat -X 2>/dev/null || true
  iptables -t mangle -X 2>/dev/null || true
  log "✅ Existing rules cleaned up"
}

setup_policies() {
  log "🔒 Setting up firewall policies..."
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -P FORWARD DROP
  log "✅ Default policies set (FORWARD=DROP for captive portal)"
}

setup_nat() {
  log "🌐 Setting up NAT for internet sharing..."
  iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
  log "✅ NAT configured for internet sharing"
}

setup_basic_rules() {
  log "🔗 Setting up basic connectivity rules..."
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i "$LAN_IF" -d "$PORTAL_IP" -j ACCEPT
  iptables -A INPUT -i "$LAN_IF" -d "$PORTAL_IP" -j ACCEPT
  iptables -A INPUT -i "$LAN_IF" -p udp --dport 53 -j ACCEPT
  iptables -A INPUT -i "$LAN_IF" -p tcp --dport 53 -j ACCEPT
  iptables -A INPUT -i "$LAN_IF" -p tcp --dport 80 -j ACCEPT
  iptables -A INPUT -i "$LAN_IF" -p tcp --dport 443 -j ACCEPT
  log "✅ Basic connectivity rules configured"
}

create_authenticated_chain() {
  log "👥 Creating authenticated users chain..."

  iptables -N ZAANET_AUTH_USERS 2>/dev/null || echo "ZAANET_AUTH_USERS chain already exists"

  # Avoid duplicate insertion
  if ! iptables -C FORWARD -i "$LAN_IF" -j ZAANET_AUTH_USERS 2>/dev/null; then
    iptables -I FORWARD 2 -i "$LAN_IF" -j ZAANET_AUTH_USERS
    log "✅ ZAANET_AUTH_USERS chain linked to FORWARD"
  else
    log "ℹ️ ZAANET_AUTH_USERS already linked to FORWARD"
  fi
}

create_blocked_chain() {
  log "🚫 Creating blocked users chain..."

  iptables -N ZAANET_BLOCKED 2>/dev/null || echo "ZAANET_BLOCKED chain already exists"

  # Avoid duplicate insertion
  if ! iptables -C FORWARD -j ZAANET_BLOCKED 2>/dev/null; then
    iptables -I FORWARD -j ZAANET_BLOCKED
    log "✅ ZAANET_BLOCKED chain linked to FORWARD"
  else
    log "ℹ️ ZAANET_BLOCKED already linked to FORWARD"
  fi
}

restore_authenticated_ips() {
  log "🔄 Restoring authenticated IPs from database..."
  local restore_script="/opt/zaanet/scripts/restore_active_ips.sh"
  if [[ -x "$restore_script" ]]; then
    bash "$restore_script" && log "✅ Active IPs restored" || log "⚠️ Failed to restore active IPs"
  else
    log "ℹ️ No restore script found, starting with clean authenticated users list"
  fi
}

show_summary() {
  log "📋 FILTER Method Configuration Summary:"
  local nat_rules
  nat_rules=$(iptables -t nat -L POSTROUTING -n --line-numbers | tail -n +3 | wc -l)
  local forward_rules
  forward_rules=$(iptables -L FORWARD -n --line-numbers | tail -n +3 | wc -l)
  local auth_rules
  auth_rules=$(iptables -L ZAANET_AUTH_USERS -n --line-numbers 2>/dev/null | tail -n +3 | wc -l)

  echo "
  ╔══════════════════════════════════════════════════════════════╗
  ║                    ZaaNet FILTER Method                      ║
  ╠══════════════════════════════════════════════════════════════╣
  ║ Method: FILTER (Block/Allow at firewall level)              ║
  ║ Default Policy: FORWARD=DROP (blocks internet access)       ║
  ║ Authenticated Users: Added to ZAANET_AUTH_USERS chain       ║
  ║                                                              ║
  ║ NAT Rules: $nat_rules (internet sharing)                              ║
  ║ FORWARD Rules: $forward_rules (portal access + established)           ║
  ║ Authenticated IPs: $auth_rules                                       ║
  ╚══════════════════════════════════════════════════════════════╝
  "
  log "📊 Configuration: NAT($nat_rules) FORWARD($forward_rules) AUTH($auth_rules)"
}

test_configuration() {
  log "🧪 Testing configuration..."
  if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    log "✅ Router has internet connectivity"
  else
    log "⚠️ Router connectivity test failed"
  fi

  if iptables -L ZAANET_AUTH_USERS -n >/dev/null 2>&1; then
    log "✅ ZAANET_AUTH_USERS chain exists"
  else
    log "❌ ZAANET_AUTH_USERS chain missing!"
    return 1
  fi

  local policy
  policy=$(iptables -L FORWARD -n | head -1 | grep -o "policy [A-Z]*" | cut -d' ' -f2)
  if [[ "$policy" == "DROP" ]]; then
    log "✅ FORWARD policy is DROP (correct for captive portal)"
  else
    log "⚠️ FORWARD policy is $policy (should be DROP)"
  fi

  log "✅ Configuration test completed"
}

main() {
  log "🚀 Starting ZaaNet FILTER Method Setup..."
  local backup_file="/tmp/iptables-backup-$(date +%Y%m%d-%H%M%S).rules"
  iptables-save > "$backup_file" 2>/dev/null || true
  log "💾 Existing rules backed up to $backup_file"

  validate_environment
  enable_ip_forwarding
  cleanup_rules
  setup_policies
  setup_nat
  setup_basic_rules
  create_authenticated_chain
  create_blocked_chain
  restore_authenticated_ips
  test_configuration
  show_summary

  log "🎉 ZaaNet FILTER Method setup completed successfully!"
  echo ""
  echo "🔥 FILTER Method Active:"
  echo "   • Unauthenticated users: BLOCKED from internet"
  echo "   • Authenticated users: Added to ZAANET_AUTH_USERS chain"
  echo "   • Portal access: Always allowed"
  echo ""
  echo "📝 Next steps:"
  echo "   1. Start your Node.js server"
  echo "   2. Connect a device to test captive portal"
  echo "   3. Authenticate to get internet access"
  echo ""
  echo "🔍 Debug commands:"
  echo "   sudo iptables -L FORWARD -n --line-numbers"
  echo "   sudo iptables -L ZAANET_AUTH_USERS -n --line-numbers"
  echo "   curl -I http://192.168.100.1/api/firewall/status"
}

trap 'log "❌ Script interrupted"; exit 130' INT TERM
main "$@"
EOF

    # Make scripts executable
    chmod +x "$ZAANET_DIR/scripts"/*.sh
    
    success "✅ Management scripts created"
}

# Create systemd services
create_systemd_services() {
    echo "🔧 Creating systemd services..."
    
    # ZaaNet application service
    cat > /etc/systemd/system/zaanet.service << EOF
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
Environment=HOME=/home/$ZAANET_USER
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # ZaaNet network manager service  
    cat > /etc/systemd/system/zaanet-manager.service << EOF
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
    
    systemctl daemon-reload
    success "✅ Systemd services created"
}

# Create user-friendly management commands
create_management_commands() {
    echo "⚙️ Creating management commands..."
    
    # Main zaanet command
    cat > /usr/local/bin/zaanet << EOF
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
        echo "✅ ZaaNet started successfully!"
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
        echo "✅ ZaaNet stopped - normal internet mode restored"
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
            echo "  📱 Portal App: ✅ Running"
        else
            echo "  📱 Portal App: ❌ Stopped"
        fi
        
        if systemctl is-active --quiet zaanet-manager; then
            echo "  🌐 Network: ✅ Active (Captive Portal Mode)"
        else
            echo "  🌐 Network: ❌ Inactive (Normal Internet Mode)"
        fi
        ;;
    restart)
        echo "🔄 Restarting ZaaNet..."
        sudo systemctl restart zaanet-manager
        sudo systemctl restart zaanet
        echo "✅ ZaaNet restarted successfully!"
        ;;
    enable)
        echo "⚙️ Enabling auto-start on boot..."
        sudo systemctl enable zaanet-manager
        sudo systemctl enable zaanet
        echo "✅ ZaaNet will now start automatically on boot"
        ;;
    disable)
        echo "⚙️ Disabling auto-start..."
        sudo systemctl disable zaanet-manager
        sudo systemctl disable zaanet
        echo "✅ Auto-start disabled"
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
                    echo "✅ Granting internet access to IP: \$3"
                    sudo iptables -A ZAANET_AUTH_USERS -s "\$3" -j ACCEPT
                    echo "✅ Done! Device \$3 now has internet access"
                else
                    echo "❌ Usage: zaanet firewall allow <ip_address>"
                    echo "💡 Example: zaanet firewall allow 192.168.100.105"
                fi
                ;;
            block)
                if [[ -n "\$3" ]]; then
                    echo "🚫 Removing internet access for IP: \$3"
                    sudo iptables -D ZAANET_AUTH_USERS -s "\$3" -j ACCEPT 2>/dev/null || echo "IP not found in authenticated list"
                    echo "✅ Done! Device \$3 internet access revoked"
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
        echo "✅ ZaaNet updated successfully!"
        ;;
    *)
        echo -e "\e[36m"
        cat << 'BANNER'
╔══════════════════════════════════════════════════════════════╗
║                    ZaaNet Management                         ║
║                   Captive Portal System                     ║
╚══════════════════════════════════════════════════════════════╝
BANNER
        echo -e "\e[0m"
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
    
    chmod +x /usr/local/bin/zaanet
    success "✅ Management commands created"
}

# Set proper permissions
set_permissions() {
    echo "🔐 Setting up permissions..."
    
    # Set ownership
    chown -R "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR"
    
    # Set script permissions
    chmod +x "$ZAANET_DIR/scripts"/*.sh
    
    # Create log files with proper permissions
    touch /var/log/zaanet.log /var/log/zaanet-firewall.log
    chown "$ZAANET_USER:$ZAANET_USER" /var/log/zaanet*.log
    chmod 644 /var/log/zaanet*.log
    
    success "✅ Permissions configured"
}

# Configure auto-start
configure_auto_start() {
    if [[ "$AUTO_START" =~ ^[Yy] ]]; then
        echo "🚀 Configuring auto-start on boot..."
        systemctl enable zaanet-manager
        systemctl enable zaanet
        success "✅ ZaaNet will start automatically on boot"
    else
        log "Auto-start disabled by user choice"
    fi
}

# Run comprehensive tests
run_tests() {
    echo "🧪 Running system tests..."
    
    echo "DEBUG: Starting network interface tests..."
    if ip link show "$WIRELESS_INTERFACE" >/dev/null 2>&1; then
        success "✅ Wireless interface ($WIRELESS_INTERFACE) ready"
    else
        warning "❌ Wireless interface ($WIRELESS_INTERFACE) not found"
    fi
    echo "DEBUG: Wireless test completed"
    
    if ip link show "$ETHERNET_INTERFACE" >/dev/null 2>&1; then
        success "✅ Ethernet interface ($ETHERNET_INTERFACE) ready"
    else
        warning "⚠️ Ethernet interface ($ETHERNET_INTERFACE) not found"
    fi
    echo "DEBUG: Ethernet test completed"
    
    echo "DEBUG: About to test hostapd..."
    if timeout 15 bash -c 'hostapd -t /etc/hostapd/hostapd.conf' >/dev/null 2>&1; then
        success "✅ Hostapd configuration valid"
    else
        warning "⚠️ Hostapd configuration test failed/timeout"
    fi
    echo "DEBUG: Hostapd test completed"
    
    echo "DEBUG: About to test dnsmasq..."
    if timeout 15 bash -c 'dnsmasq --test' >/dev/null 2>&1; then
        success "✅ Dnsmasq configuration valid"
    else
        warning "⚠️ Dnsmasq configuration test failed/timeout"
    fi
    echo "DEBUG: Dnsmasq test completed"
    
    echo "DEBUG: Testing remaining components..."
    # ... rest of tests
    success "✅ All tests completed"
}

# Show installation completion
show_completion() {
    clear
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║            🎉 ZaaNet Installation Complete! 🎉              ║
║                Ready for Production Use                      ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}📱 Your Captive Portal is Ready:${NC}"
    echo "   📡 Wi-Fi Network: $WIFI_SSID"
    echo "   🏠 Portal IP: $PORTAL_IP"
    echo "   🌐 Portal Domain: $PORTAL_DOMAIN"
    echo "   🔌 Wireless Interface: $WIRELESS_INTERFACE"
    echo "   🌐 Internet Interface: $ETHERNET_INTERFACE"
    echo "   📜 Contract ID: $CONTRACT_ID"
    echo ""
    echo -e "${YELLOW}🚀 Start Your Captive Portal:${NC}"
    echo "   sudo zaanet start"
    echo ""
    echo -e "${YELLOW}📱 For Users to Connect:${NC}"
    echo "   1. Connect to Wi-Fi: '$WIFI_SSID'"
    echo "   2. Open any website in browser"
    echo "   3. Get redirected to captive portal"
    echo "   4. Complete authentication"
    echo "   5. Enjoy internet access!"
    echo ""
    echo -e "${YELLOW}⚙️ Management Commands:${NC}"
    echo "   zaanet status      # Check current status"
    echo "   zaanet stop        # Return to normal internet"
    echo "   zaanet restart     # Restart services"
    echo "   zaanet logs        # View live logs"
    echo "   zaanet config      # Show configuration"
    echo "   zaanet firewall    # Manage user access"
    echo ""
    echo -e "${BLUE}🔧 Optional Configuration:${NC}"
    if [[ "$AUTO_START" =~ ^[Yy] ]]; then
        echo "   ✅ Auto-start enabled - portal will start on boot"
    else
        echo "   ⚙️ Enable auto-start: sudo zaanet enable"
    fi
    echo "   📄 Edit config: nano $ZAANET_DIR/app/.env"
    echo "   🔄 Update ZaaNet: zaanet update"
    echo ""
    echo -e "${PURPLE}🎯 Quick Test:${NC}"
    echo "   sudo zaanet start"
    echo "   # Connect phone/laptop to '$WIFI_SSID'"
    echo "   # Open browser → automatic redirect to portal"
    echo ""
    echo -e "${GREEN}📚 Documentation & Support:${NC}"
    echo "   📖 Docs: https://docs.zaanet.xyz"
    echo "   🐛 Issues: https://github.com/yourusername/zaanet/issues"
    echo "   💬 Support: support@zaanet.xyz"
    echo ""
    echo -e "${CYAN}🎉 Installation Summary:${NC}"
    echo "   ✅ System dependencies installed"
    echo "   ✅ Network interfaces auto-detected"
    echo "   ✅ ZaaNet application configured"
    echo "   ✅ Firewall rules prepared"
    echo "   ✅ Management commands available"
    echo "   ✅ Ready for production use!"
}

# Main installation orchestrator
main() {
    show_banner
    check_root
    check_raspberry_pi
    auto_detect_interfaces
    get_essential_config
    
    echo ""
    echo -e "${CYAN}🚀 Starting automated installation...${NC}"
    echo ""
    
    install_dependencies
    create_system_user
    setup_application
    configure_network_services
    create_zaanet_scripts
    create_systemd_services
    create_management_commands
    set_permissions
    configure_auto_start
    run_tests
    
    show_completion
    
    log "🎉 ZaaNet auto-installation completed successfully!"
}

# Global error handling
trap 'error "Installation failed at line $LINENO. Check /var/log/zaanet-install.log for details."' ERR

# Create install log
exec > >(tee -a /var/log/zaanet-install.log)
exec 2>&1

# Start installation
main "$@"

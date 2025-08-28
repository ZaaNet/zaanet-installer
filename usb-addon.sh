#!/bin/bash
# ZaaNet USB WiFi Dongle Addon Script
# Adds AC-1200 USB WiFi dongles to existing ZaaNet installation
# curl -sSL https://get.zaanet.xyz/usb-addon | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ZAANET_DIR="/opt/zaanet"
USB_ADDON_LOG="/var/log/zaanet-usb-addon.log"

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
║             USB WiFi Dongle Addon v1.0.0                    ║
║           Expand Your Captive Portal Capacity               ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}Add USB WiFi dongles to your existing ZaaNet setup${NC}"
    echo "   • Supports AC-1200 and similar dongles"
    echo "   • Automatic driver installation"
    echo "   • Doubles your connection capacity"
    echo ""
}

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$USB_ADDON_LOG"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$USB_ADDON_LOG"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "[WARNING $(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$USB_ADDON_LOG"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "[SUCCESS $(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$USB_ADDON_LOG"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This addon must be run as root. Please use: curl -sSL https://get.zaanet.xyz/usb-addon | sudo bash"
    fi
}

# Check if ZaaNet is already installed
check_zaanet_installation() {
    echo "Checking for existing ZaaNet installation..."
    
    if [[ ! -d "$ZAANET_DIR" ]]; then
        error "ZaaNet not found. Please install ZaaNet first using: curl -sSL https://get.zaanet.xyz | sudo bash"
    fi
    
    if [[ ! -f "$ZAANET_DIR/app/.env" ]]; then
        error "ZaaNet configuration not found. Please reinstall ZaaNet first."
    fi
    
    if ! command -v zaanet &> /dev/null; then
        error "ZaaNet management command not found. Please reinstall ZaaNet first."
    fi
    
    success "ZaaNet installation verified"
}

# Load existing ZaaNet configuration
load_zaanet_config() {
    echo "Loading ZaaNet configuration..."
    
    # Source the existing configuration
    source "$ZAANET_DIR/app/.env"
    
    # Store existing values
    EXISTING_WIRELESS_INTERFACE="$WIRELESS_INTERFACE"
    EXISTING_PORTAL_IP="$PORTAL_IP"
    EXISTING_WIFI_SSID="$WIFI_SSID"
    
    log "Existing config loaded:"
    log "  Primary Interface: $EXISTING_WIRELESS_INTERFACE"
    log "  Primary SSID: $EXISTING_WIFI_SSID"
    log "  Primary IP: $EXISTING_PORTAL_IP"
}

# Detect USB WiFi dongles
detect_usb_dongles() {
    echo "Scanning for USB WiFi dongles..."
    
    # Get all wireless interfaces
    ALL_WIRELESS=($(ls /sys/class/net/ | grep -E '^(wlan|wlx)' | sort))
    
    # Filter out the existing primary interface
    USB_DONGLES=()
    for interface in "${ALL_WIRELESS[@]}"; do
        if [[ "$interface" != "$EXISTING_WIRELESS_INTERFACE" ]]; then
            # Check if it's a USB device
            DEVICE_PATH="/sys/class/net/$interface/device"
            if [[ -L "$DEVICE_PATH" ]]; then
                USB_PATH=$(readlink -f "$DEVICE_PATH")
                if [[ "$USB_PATH" == *"usb"* ]]; then
                    USB_DONGLES+=("$interface")
                fi
            fi
        fi
    done
    
    echo "Found wireless interfaces:"
    echo "  Primary (built-in): $EXISTING_WIRELESS_INTERFACE"
    for dongle in "${USB_DONGLES[@]}"; do
        echo "  USB Dongle: $dongle"
    done
    
    if [[ ${#USB_DONGLES[@]} -eq 0 ]]; then
        error "No USB WiFi dongles detected. Please ensure your dongle is connected and recognized by the system."
    fi
    
    success "${#USB_DONGLES[@]} USB dongle(s) detected"
}

# Install drivers for detected dongles
install_dongle_drivers() {
    echo "Installing/updating drivers for USB dongles..."
    
    # Update system first
    apt-get update -y
    
    # Install build dependencies if not already present
    apt-get install -y git dkms build-essential linux-headers-$(uname -r) || \
    apt-get install -y git dkms build-essential raspberrypi-kernel-headers
    
    for interface in "${USB_DONGLES[@]}"; do
        echo "Processing dongle: $interface"
        
        # Get USB vendor and product ID
        DEVICE_PATH="/sys/class/net/$interface/device"
        USB_PATH=$(readlink -f "$DEVICE_PATH")
        
        # Extract vendor and product ID
        VENDOR_ID=""
        PRODUCT_ID=""
        
        if [[ -f "$USB_PATH/idVendor" && -f "$USB_PATH/idProduct" ]]; then
            VENDOR_ID=$(cat "$USB_PATH/idVendor")
            PRODUCT_ID=$(cat "$USB_PATH/idProduct")
            log "Dongle $interface: Vendor=$VENDOR_ID, Product=$PRODUCT_ID"
        fi
        
        # Check if it supports AP mode
        if iw list 2>/dev/null | grep -A 10 "Wiphy.*$interface" | grep -q "AP"; then
            success "Dongle $interface already supports AP mode"
        else
            warning "Dongle $interface may need specific drivers for AP mode"
            
            # Install common RTL drivers that support most AC-1200 dongles
            if [[ "$VENDOR_ID" == "0bda" ]]; then  # Realtek
                echo "Installing Realtek drivers for $interface..."
                install_realtek_drivers
            else
                echo "Installing generic drivers for $interface..."
                install_generic_drivers
            fi
        fi
    done
}

install_realtek_drivers() {
    local driver_installed=false
    
    # Try RTL8812AU drivers (most common for AC-1200)
    if ! lsmod | grep -q "8812au"; then
        echo "Installing RTL8812AU drivers..."
        if install_rtl8812au_driver; then
            driver_installed=true
        fi
    fi
    
    # Try RTL88x2BU drivers (alternative)
    if ! $driver_installed && ! lsmod | grep -q "88x2bu"; then
        echo "Installing RTL88x2BU drivers..."
        install_rtl88x2bu_driver
    fi
}

install_rtl8812au_driver() {
    local temp_dir="/tmp/rtl8812au-$(date +%s)"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Try multiple driver sources
    local driver_sources=(
        "https://github.com/aircrack-ng/rtl8812au/archive/refs/heads/v5.6.4.2.zip"
        "https://github.com/gnab/rtl8812au/archive/refs/heads/master.zip"
        "https://github.com/morrownr/8812au-20210629/archive/refs/heads/main.zip"
    )
    
    for source in "${driver_sources[@]}"; do
        echo "Trying driver source: $source"
        if wget -q "$source" -O driver.zip; then
            if unzip -q driver.zip; then
                cd */
                if make && make install; then
                    modprobe 8812au
                    echo "8812au" >> /etc/modules-load.d/zaanet-usb.conf
                    success "RTL8812AU driver installed successfully"
                    rm -rf "$temp_dir"
                    return 0
                fi
                cd ..
            fi
        fi
    done
    
    rm -rf "$temp_dir"
    return 1
}

install_rtl88x2bu_driver() {
    local temp_dir="/tmp/rtl88x2bu-$(date +%s)"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    if wget -q "https://github.com/cilynx/rtl88x2bu/archive/refs/heads/master.zip" -O driver.zip; then
        if unzip -q driver.zip; then
            cd rtl88x2bu-master/
            if make && make install; then
                modprobe 88x2bu
                echo "88x2bu" >> /etc/modules-load.d/zaanet-usb.conf
                success "RTL88x2BU driver installed successfully"
            fi
        fi
    fi
    
    rm -rf "$temp_dir"
}

install_generic_drivers() {
    echo "Attempting generic driver installation..."
    modprobe cfg80211
    modprobe mac80211
    success "Generic WiFi drivers loaded"
}

# Configure dongles for ZaaNet
configure_dongles() {
    echo "Configuring USB dongles for ZaaNet..."
    
    local dongle_count=0
    
    for interface in "${USB_DONGLES[@]}"; do
        dongle_count=$((dongle_count + 1))
        
        # Generate unique configuration for each dongle
        local base_ip="192.168.$((100 + dongle_count))"
        local ssid_suffix=""
        
        if [[ $dongle_count -eq 1 ]]; then
            ssid_suffix="-Extended"
        else
            ssid_suffix="-$dongle_count"
        fi
        
        echo "Configuring dongle $dongle_count ($interface):"
        echo "  SSID: ${EXISTING_WIFI_SSID}${ssid_suffix}"
        echo "  IP Range: ${base_ip}.1 - ${base_ip}.200"
        
        # Create hostapd configuration for this dongle
        create_dongle_hostapd_config "$interface" "$dongle_count" "${EXISTING_WIFI_SSID}${ssid_suffix}" "${base_ip}.1"
        
        # Update dnsmasq configuration
        add_dongle_to_dnsmasq "$interface" "${base_ip}.100" "${base_ip}.200" "${base_ip}.1"
        
        # Create systemd service for this dongle
        create_dongle_service "$interface" "$dongle_count"
        
        # Update firewall rules
        add_dongle_firewall_rules "$interface" "${base_ip}.0/24"
        
        success "Dongle $dongle_count configured successfully"
    done
    
    # Update main ZaaNet configuration
    update_zaanet_config
}

create_dongle_hostapd_config() {
    local interface="$1"
    local dongle_num="$2" 
    local ssid="$3"
    local ip="$4"
    
    cat > "/etc/hostapd/hostapd-dongle${dongle_num}.conf" << EOF
# ZaaNet USB Dongle ${dongle_num} Configuration
interface=${interface}
driver=nl80211
ssid=${ssid}
hw_mode=g
channel=$((6 + dongle_num))
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
country_code=GH

# Enable 802.11n for better speeds
ieee80211n=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]

# Enable 802.11ac for AC-1200 speeds (if supported)
ieee80211ac=1
vht_capab=[RXLDPC][SHORT-GI-80][TX-STBC-2BY1][RX-STBC-1]

# Auto-generated by ZaaNet USB Addon on $(date)
EOF
}

add_dongle_to_dnsmasq() {
    local interface="$1"
    local dhcp_start="$2"
    local dhcp_end="$3"
    local portal_ip="$4"
    
    # Backup original dnsmasq config
    cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup-$(date +%s)
    
    # Add dongle configuration to dnsmasq
    cat >> /etc/dnsmasq.conf << EOF

# ZaaNet USB Dongle Configuration - ${interface}
interface=${interface}
dhcp-range=${dhcp_start},${dhcp_end},12h
address=/#/${portal_ip}
EOF
}

create_dongle_service() {
    local interface="$1"
    local dongle_num="$2"
    
    cat > "/etc/systemd/system/hostapd-dongle${dongle_num}.service" << EOF
[Unit]
Description=Hostapd for USB Dongle ${dongle_num} (${interface})
After=network.target hostapd.service
Wants=network.target

[Service]
Type=forking
PIDFile=/run/hostapd-dongle${dongle_num}.pid
Restart=on-failure
RestartSec=2
Environment=DAEMON_CONF=/etc/hostapd/hostapd-dongle${dongle_num}.conf
ExecStart=/usr/sbin/hostapd -B -P /run/hostapd-dongle${dongle_num}.pid \$DAEMON_CONF

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable "hostapd-dongle${dongle_num}"
}

add_dongle_firewall_rules() {
    local interface="$1"
    local subnet="$2"
    
    # Add rules to the existing ZaaNet firewall script
    local firewall_script="$ZAANET_DIR/scripts/zaanet-firewall.sh"
    
    if [[ -f "$firewall_script" ]]; then
        # Create backup
        cp "$firewall_script" "${firewall_script}.backup-$(date +%s)"
        
        # Add dongle rules to firewall script
        sed -i "/# ZaaNet USB Dongle rules/d" "$firewall_script"
        sed -i "/setup_basic_rules()/a\\
# ZaaNet USB Dongle rules for $interface\\
  iptables -A FORWARD -i \"$interface\" -j ZAANET_AUTH_USERS\\
  iptables -A INPUT -i \"$interface\" -p udp --dport 53 -j ACCEPT\\
  iptables -A INPUT -i \"$interface\" -p tcp --dport 53 -j ACCEPT\\
  iptables -A INPUT -i \"$interface\" -p tcp --dport 80 -j ACCEPT\\
  iptables -A INPUT -i \"$interface\" -p tcp --dport 443 -j ACCEPT" "$firewall_script"
    fi
}

update_zaanet_config() {
    echo "Updating ZaaNet configuration..."
    
    # Create list of all dongles for the main config
    local dongle_interfaces=""
    for interface in "${USB_DONGLES[@]}"; do
        if [[ -z "$dongle_interfaces" ]]; then
            dongle_interfaces="$interface"
        else
            dongle_interfaces="$dongle_interfaces,$interface"
        fi
    done
    
    # Update .env file
    if ! grep -q "USB_DONGLES=" "$ZAANET_DIR/app/.env"; then
        echo "" >> "$ZAANET_DIR/app/.env"
        echo "# USB Dongle Configuration - Added by ZaaNet USB Addon" >> "$ZAANET_DIR/app/.env"
        echo "USB_DONGLES=\"$dongle_interfaces\"" >> "$ZAANET_DIR/app/.env"
        echo "USB_ADDON_INSTALLED=true" >> "$ZAANET_DIR/app/.env"
        echo "USB_ADDON_DATE=\"$(date)\"" >> "$ZAANET_DIR/app/.env"
    fi
}

# Update ZaaNet management commands
update_management_commands() {
    echo "Updating ZaaNet management commands..."
    
    # Create USB dongle management functions
    cat >> /usr/local/bin/zaanet << 'EOF'

# USB Dongle Management Functions
manage_dongles() {
    local action="$1"
    
    case "$action" in
        start)
            echo "Starting USB dongles..."
            for service in /etc/systemd/system/hostapd-dongle*.service; do
                if [[ -f "$service" ]]; then
                    local service_name=$(basename "$service" .service)
                    sudo systemctl start "$service_name"
                    echo "  Started: $service_name"
                fi
            done
            ;;
        stop)
            echo "Stopping USB dongles..."
            for service in /etc/systemd/system/hostapd-dongle*.service; do
                if [[ -f "$service" ]]; then
                    local service_name=$(basename "$service" .service)
                    sudo systemctl stop "$service_name"
                    echo "  Stopped: $service_name"
                fi
            done
            ;;
        status)
            echo "USB Dongle Status:"
            for service in /etc/systemd/system/hostapd-dongle*.service; do
                if [[ -f "$service" ]]; then
                    local service_name=$(basename "$service" .service)
                    local status=$(systemctl is-active "$service_name")
                    echo "  $service_name: $status"
                fi
            done
            ;;
    esac
}

# Check if this is a dongle command
if [[ "$1" == "dongles" ]]; then
    manage_dongles "$2"
    exit 0
fi
EOF
    
    success "Management commands updated with dongle support"
}

# Test the configuration
test_configuration() {
    echo "Testing USB dongle configuration..."
    
    for interface in "${USB_DONGLES[@]}"; do
        echo "Testing interface: $interface"
        
        # Check if interface exists and is up
        if ip link show "$interface" &>/dev/null; then
            success "Interface $interface exists"
        else
            error "Interface $interface not found"
        fi
        
        # Check if it supports AP mode
        if iw list 2>/dev/null | grep -A 20 "$interface" | grep -q "AP"; then
            success "Interface $interface supports AP mode"
        else
            warning "Interface $interface may not support AP mode"
        fi
        
        # Test hostapd configuration
        local dongle_num=$(echo "$interface" | sed 's/[^0-9]*//g')
        if [[ -z "$dongle_num" ]]; then
            dongle_num="1"
        fi
        
        local config_file="/etc/hostapd/hostapd-dongle${dongle_num}.conf"
        if hostapd -t "$config_file" &>/dev/null; then
            success "Hostapd configuration valid for $interface"
        else
            warning "Hostapd configuration may have issues for $interface"
        fi
    done
}

# Show completion summary
show_completion() {
    clear
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║          USB WiFi Dongle Addon Installation Complete!       ║
║              Your ZaaNet Capacity Has Been Expanded         ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}USB Dongles Configured:${NC}"
    
    local dongle_count=0
    for interface in "${USB_DONGLES[@]}"; do
        dongle_count=$((dongle_count + 1))
        local base_ip="192.168.$((100 + dongle_count))"
        local ssid_suffix=""
        
        if [[ $dongle_count -eq 1 ]]; then
            ssid_suffix="-Extended"
        else
            ssid_suffix="-$dongle_count"
        fi
        
        echo "  Dongle $dongle_count ($interface):"
        echo "    SSID: ${EXISTING_WIFI_SSID}${ssid_suffix}"
        echo "    IP: ${base_ip}.1"
        echo "    Range: ${base_ip}.100 - ${base_ip}.200"
        echo ""
    done
    
    echo -e "${YELLOW}Start Your Expanded Portal:${NC}"
    echo "  zaanet start          # Starts all APs (built-in + dongles)"
    echo "  zaanet dongles start  # Start only USB dongles"
    echo "  zaanet dongles stop   # Stop only USB dongles"
    echo "  zaanet dongles status # Check dongle status"
    echo ""
    
    echo -e "${CYAN}Total WiFi Networks Available:${NC}"
    echo "  Primary: $EXISTING_WIFI_SSID (built-in WiFi)"
    for interface in "${USB_DONGLES[@]}"; do
        dongle_count=$((dongle_count + 1))
        local ssid_suffix="-Extended"
        if [[ $dongle_count -gt 1 ]]; then
            ssid_suffix="-$dongle_count"
        fi
        echo "  Extended: ${EXISTING_WIFI_SSID}${ssid_suffix} (USB dongle)"
    done
    echo ""
    
    echo -e "${GREEN}Capacity Increase:${NC}"
    echo "  Before: ~50 concurrent users (single AP)"
    echo "  After: ~$((50 * (1 + ${#USB_DONGLES[@]}))) concurrent users (multiple APs)"
    echo ""
    
    echo -e "${PURPLE}Next Steps:${NC}"
    echo "  1. Run: zaanet start"
    echo "  2. Check status: zaanet status"
    echo "  3. Test with multiple devices on different networks"
    echo ""
    
    success "USB dongle addon installation completed successfully!"
}

# Main installation function
main() {
    show_banner
    check_root
    check_zaanet_installation
    load_zaanet_config
    detect_usb_dongles
    install_dongle_drivers
    configure_dongles
    update_management_commands
    test_configuration
    show_completion
    
    log "ZaaNet USB dongle addon installation completed successfully!"
}

# Global error handling
trap 'error "Installation failed at line $LINENO. Check $USB_ADDON_LOG for details."' ERR

# Create addon log
touch "$USB_ADDON_LOG"
chmod 644 "$USB_ADDON_LOG"

# Start installation
main "$@"

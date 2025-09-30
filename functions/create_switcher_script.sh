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

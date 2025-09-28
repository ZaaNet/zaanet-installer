#!/bin/bash
# functions/create_zaanet_scripts.sh
# Create ZaaNet management and control scripts

create_zaanet_scripts() {
    log "📜 Creating ZaaNet management scripts..."
    
    # Create scripts directory
    mkdir -p "$ZAANET_DIR/scripts"
    
    # =============================================================================
    # NETWORK SWITCHER SCRIPT
    # =============================================================================
    
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
    echo "   Wi-Fi SSID: %WIFI_SSID%"
    echo "   Portal IP: %PORTAL_IP%"
    echo "   Interface: $INTERFACE"
    echo ""
    
    if systemctl is-active --quiet hostapd && systemctl is-active --quiet dnsmasq; then
        echo "Mode: ZaaNet Captive Portal Active"
        ip addr show "$INTERFACE" | grep inet || echo "No IP assigned"
    else
        echo "Mode: Normal Internet Mode"
    fi
    
    echo ""
    echo "Services:"
    echo "  📡 hostapd: $(systemctl is-active hostapd)"
    echo "  🌐 dnsmasq: $(systemctl is-active dnsmasq)"
    echo "  🔧 Network: $(ip link show "$INTERFACE" | grep "state UP" >/dev/null && echo "UP" || echo "DOWN")"
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
        echo "  --zaanet   Switch to captive portal mode"
        echo "  --normal   Switch to normal internet mode"
        echo "  --status   Show current status"
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
    
    # =============================================================================
    # FIREWALL SCRIPT
    # =============================================================================
    
    create_firewall_script() {
        log "Creating firewall management script..."
        
        cat > "$ZAANET_DIR/scripts/zaanet-firewall.sh" <<'EOF'
#!/bin/bash
# ZaaNet Captive Portal Firewall Setup

set -euo pipefail

# Configuration - Auto-detected values
LAN_IF="%WIRELESS_INTERFACE%"
WAN_IF="%ETHERNET_INTERFACE%"
PORTAL_IP="%PORTAL_IP%"
LAN_SUBNET="192.168.100.0/24"
LOG_FILE="/var/log/zaanet-firewall.log"

log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE" 2>/dev/null || true
}

# Validate environment
validate_environment() {
    if [[ $EUID -ne 0 ]]; then
        log "This script must be run as root"
        exit 1
    fi

    for tool in iptables ip; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log "Required tool not found: $tool"
            exit 1
        fi
    done

    if ! ip link show "$LAN_IF" >/dev/null 2>&1; then
        log "LAN interface $LAN_IF not found"
        exit 1
    fi

    if ! ip link show "$WAN_IF" >/dev/null 2>&1; then
        log "WAN interface $WAN_IF not found, internet sharing may not work"
    fi

    log "Environment validation passed"
}

enable_ip_forwarding() {
    echo 1 > /proc/sys/net/ipv4/ip_forward
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf 2>/dev/null; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    log "IP forwarding enabled"
}

cleanup_rules() {
    log "Cleaning up existing rules..."
    iptables -F 2>/dev/null || true
    iptables -t nat -F 2>/dev/null || true
    iptables -t mangle -F 2>/dev/null || true
    iptables -X ZAANET_AUTH_USERS 2>/dev/null || true
    iptables -X ZAANET_BLOCKED 2>/dev/null || true
}

setup_policies() {
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD DROP
}

setup_nat() {
    if ip link show "$WAN_IF" >/dev/null 2>&1; then
        iptables -t nat -A POSTROUTING -o "$WAN_IF" -j MASQUERADE
        log "NAT configured for internet sharing via $WAN_IF"
    else
        log "No WAN interface available for NAT"
    fi
}

setup_basic_rules() {
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow established connections
    iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    
    # Allow access to portal
    iptables -A FORWARD -i "$LAN_IF" -d "$PORTAL_IP" -j ACCEPT
    iptables -A INPUT -i "$LAN_IF" -d "$PORTAL_IP" -j ACCEPT
    
    # Allow DNS and portal services
    iptables -A INPUT -i "$LAN_IF" -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -i "$LAN_IF" -p tcp --dport 53 -j ACCEPT
    iptables -A INPUT -i "$LAN_IF" -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -i "$LAN_IF" -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -i "$LAN_IF" -p udp --dport 67:68 -j ACCEPT
}

create_auth_chains() {
    # Create authenticated users chain
    iptables -N ZAANET_AUTH_USERS 2>/dev/null || log "ZAANET_AUTH_USERS chain exists"
    
    # Create blocked users chain
    iptables -N ZAANET_BLOCKED 2>/dev/null || log "ZAANET_BLOCKED chain exists"
    
    # Link chains to FORWARD
    if ! iptables -C FORWARD -i "$LAN_IF" -j ZAANET_AUTH_USERS 2>/dev/null; then
        iptables -I FORWARD 2 -i "$LAN_IF" -j ZAANET_AUTH_USERS
    fi
    
    if ! iptables -C FORWARD -j ZAANET_BLOCKED 2>/dev/null; then
        iptables -I FORWARD -j ZAANET_BLOCKED
    fi
}

test_configuration() {
    log "Testing firewall configuration..."
    if iptables -L >/dev/null 2>&1; then
        log "Firewall rules applied successfully"
    else
        log "Error in firewall configuration"
        exit 1
    fi
}

show_summary() {
    log "Firewall setup complete:"
    log "  LAN Interface: $LAN_IF"
    log "  WAN Interface: $WAN_IF"
    log "  Portal IP: $PORTAL_IP"
    log "  Auth chain: ZAANET_AUTH_USERS"
    log "  Block chain: ZAANET_BLOCKED"
}

main() {
    local backup_file="/tmp/iptables-backup-$(date +%Y%m%d-%H%M%S).rules"
    iptables-save > "$backup_file" 2>/dev/null || true
    log "Iptables backed up to: $backup_file"

    validate_environment
    enable_ip_forwarding
    cleanup_rules
    setup_policies
    setup_nat
    setup_basic_rules
    create_auth_chains
    test_configuration
    show_summary
}

trap 'log "Script interrupted"; exit 130' INT TERM
main "$@"
EOF
        
        # Replace placeholders
        sed -i "s|%WIRELESS_INTERFACE%|$WIRELESS_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
        sed -i "s|%ETHERNET_INTERFACE%|$ETHERNET_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
        sed -i "s|%PORTAL_IP%|$PORTAL_IP|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
        
        success "✓ Firewall script created"
    }
    
    # =============================================================================
    # STATUS SCRIPT
    # =============================================================================
    
    create_status_script() {
        log "Creating status monitoring script..."
        
        cat > "$ZAANET_DIR/scripts/zaanet-status.sh" <<'EOF'
#!/bin/bash
# ZaaNet Status Monitor

show_detailed_status() {
    echo "================================"
    echo "       ZaaNet Status Report"
    echo "================================"
    echo ""
    
    # Service Status
    echo "🔧 Services:"
    printf "   hostapd:  %-10s " "$(systemctl is-active hostapd 2>/dev/null || echo 'inactive')"
    systemctl is-active --quiet hostapd && echo "✓" || echo "✗"
    
    printf "   dnsmasq:  %-10s " "$(systemctl is-active dnsmasq 2>/dev/null || echo 'inactive')"
    systemctl is-active --quiet dnsmasq && echo "✓" || echo "✗"
    
    echo ""
    
    # Network Status
    echo "📡 Network:"
    echo "   Interface: %WIRELESS_INTERFACE%"
    echo "   SSID: %WIFI_SSID%"
    echo "   Portal IP: %PORTAL_IP%"
    
    if ip addr show "%WIRELESS_INTERFACE%" | grep -q "%PORTAL_IP%"; then
        echo "   Status: IP configured ✓"
    else
        echo "   Status: IP not configured ✗"
    fi
    
    echo ""
    
    # Connected Clients
    echo "👥 Connected Clients:"
    if [[ -f /var/lib/dhcp/dnsmasq.leases ]]; then
        local client_count=$(wc -l < /var/lib/dhcp/dnsmasq.leases)
        echo "   Active leases: $client_count"
        if [[ $client_count -gt 0 ]]; then
            echo "   Recent connections:"
            tail -5 /var/lib/dhcp/dnsmasq.leases | while read line; do
                local ip=$(echo "$line" | awk '{print $3}')
                local mac=$(echo "$line" | awk '{print $2}')
                echo "     $ip ($mac)"
            done
        fi
    else
        echo "   No lease file found"
    fi
    
    echo ""
    
    # Log Status
    echo "📋 Recent Activity:"
    if [[ -f /var/log/zaanet.log ]]; then
        echo "   Last 3 log entries:"
        tail -3 /var/log/zaanet.log | sed 's/^/     /'
    else
        echo "   No log file found"
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
    
    # =============================================================================
    # RUN SCRIPT CREATION
    # =============================================================================
    
    create_switcher_script
    create_firewall_script
    create_status_script
    
    # Make all scripts executable
    chmod +x "$ZAANET_DIR/scripts"/*.sh
    
    # Set proper ownership
    chown -R "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR/scripts"
    
    success "✅ ZaaNet management scripts created successfully"
}
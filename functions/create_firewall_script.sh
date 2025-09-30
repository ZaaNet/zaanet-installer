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
   
    # === FORWARD Chain Structure ===
    
    # 1. CRITICAL: Check authentication FIRST (both directions for counting)
    # Outbound traffic (uploads): WiFi → Internet
    iptables -I FORWARD 1 -i "$LAN_IF" -j ZAANET_AUTH_USERS
    
    # Inbound traffic (downloads): Internet → WiFi
    iptables -I FORWARD 1 -o "$LAN_IF" -j ZAANET_AUTH_USERS
   
    # 2. Check if IP is explicitly blocked (only outgoing WiFi traffic)
    iptables -A FORWARD -i "$LAN_IF" -j ZAANET_BLOCKED
   
    # 3. Allow return traffic (internet → clients)
    iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
   
    # 4. Everything else hits DROP (policy)
   
    log "SUCCESS" "Authentication chains configured"
    log "INFO" "  FORWARD rule order:"
    log "INFO" "    1. Check auth outbound (WiFi → Internet)"
    log "INFO" "    2. Check auth inbound (Internet → WiFi)"
    log "INFO" "    3. ZAANET_BLOCKED → Check blocks (WiFi only)"
    log "INFO" "    4. ESTABLISHED/RELATED → ACCEPT (return traffic)"
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

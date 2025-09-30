#!/bin/bash
# functions/create_firewall_script.sh

create_firewall_script() {
    log "Creating firewall management script..."
    
    mkdir -p "$ZAANET_DIR/scripts"
    
    cat > "$ZAANET_DIR/scripts/zaanet-firewall.sh" <<'EOF'
#!/bin/bash

# Configuration - Auto-detected values
LAN_IF="%WIRELESS_INTERFACE%"
WAN_IF="%ETHERNET_INTERFACE%"
PORTAL_IP="%PORTAL_IP%"
LAN_SUBNET="192.168.100.0/24"
PORTAL_PORT="80"
LOG_FILE="/var/log/zaanet-firewall.log"

# ... (rest of your firewall script - the improved version with ESTABLISHED inside AUTH chain) ...

create_auth_chains() {
    log "INFO" "Creating authentication chains..."
    
    iptables -N ZAANET_AUTH_USERS 2>/dev/null || true
    iptables -N ZAANET_BLOCKED 2>/dev/null || true
    
    iptables -A FORWARD -j ZAANET_BLOCKED
    iptables -A FORWARD -i "$LAN_IF" -j ZAANET_AUTH_USERS
    
    # ESTABLISHED rule INSIDE AUTH chain
    iptables -A ZAANET_AUTH_USERS -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    
    # NFQUEUE for monitoring (after ESTABLISHED, before user rules)
    iptables -A ZAANET_AUTH_USERS -j NFQUEUE --queue-num 0 --queue-bypass
    
    log "SUCCESS" "Authentication chains configured"
}

# ... (rest of script) ...
EOF
    
    # Replace placeholders
    sed -i "s|%WIRELESS_INTERFACE%|$WIRELESS_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    sed -i "s|%ETHERNET_INTERFACE%|$ETHERNET_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    sed -i "s|%PORTAL_IP%|$PORTAL_IP|g" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    
    chmod +x "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    chown "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR/scripts/zaanet-firewall.sh"
    
    success "✓ Firewall script created"
}

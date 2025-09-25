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
    
    success "Network services configured"
}
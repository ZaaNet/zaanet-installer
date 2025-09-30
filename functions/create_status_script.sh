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

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
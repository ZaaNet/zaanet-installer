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
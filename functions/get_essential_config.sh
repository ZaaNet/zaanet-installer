get_essential_config() {
    # Contract ID
    read -p "Enter your contract/network ID: " CONTRACT_ID
    while [[ -z "$CONTRACT_ID" ]]; do
        echo "Contract ID is required to identify this installation!"
        read -p "Enter your contract/network ID: " CONTRACT_ID
    done
    
    # Optional customizations
    read -p "Wi-Fi network name [default: $WIFI_SSID]: " CUSTOM_SSID
    if [[ -n "$CUSTOM_SSID" ]]; then
        WIFI_SSID="$CUSTOM_SSID"
    fi
    
    # Auto-start option
    read -p "Enable auto-start on boot? [Y/n]: " AUTO_START
    AUTO_START=${AUTO_START:-Y}
    
    # Show configuration summary
    echo ""
    echo -e "${CYAN} Configuration Summary:${NC}"
    echo "   Wi-Fi SSID: $WIFI_SSID"
    echo "   Portal IP: $PORTAL_IP"
    echo "   DHCP Range: $DHCP_START - $DHCP_END"
    echo "   Portal Domain: $PORTAL_DOMAIN"
    echo "  Wireless Interface: $WIRELESS_INTERFACE"
    echo "   Internet Interface: $ETHERNET_INTERFACE"
    echo "   Main Server: $MAIN_SERVER_URL"
    echo "   Contract ID: $CONTRACT_ID"
    echo "   Auto-start: $AUTO_START"
    echo ""
}
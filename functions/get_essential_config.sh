#!/bin/bash
# functions/get_essential_config.sh
# Get essential configuration from user

get_essential_config() {
    log "📝 Getting essential configuration..."
    
    echo ""
    echo -e "${CYAN}🔧 ZaaNet Configuration${NC}"
    echo ""
    
    # Contract ID (required)
    while [[ -z "$CONTRACT_ID" ]]; do
        read -p "Enter your contract/network ID: " CONTRACT_ID
        if [[ -z "$CONTRACT_ID" ]]; then
            echo -e "${RED}Contract ID is required!${NC}"
        fi
    done
    
    # Wi-Fi SSID (required)
    while [[ -z "$CUSTOM_SSID" ]]; do
        read -p "Enter Wi-Fi network name: " CUSTOM_SSID
        if [[ -z "$CUSTOM_SSID" ]]; then
            echo -e "${RED}Wi-Fi network name is required!${NC}"
        fi
    done
    WIFI_SSID="$CUSTOM_SSID"
    
    # Show summary
    echo ""
    echo -e "${CYAN}Configuration Summary:${NC}"
    echo "   Contract ID: $CONTRACT_ID"
    echo "   Wi-Fi SSID: $WIFI_SSID"
    echo "   Portal IP: $PORTAL_IP"
    echo "   Wireless Interface: $WIRELESS_INTERFACE"
    echo "   Internet Interface: $ETHERNET_INTERFACE"
    echo ""
    
    # Export variables
    export CONTRACT_ID
    export WIFI_SSID
    
    success "✅ Configuration complete"
}
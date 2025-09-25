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
    echo -e "${CYAN} Your Captive Portal is Ready:${NC}"
    echo "   📡 Wi-Fi Network: $WIFI_SSID"
    echo "   🏠 Portal IP: $PORTAL_IP"
    echo "   🔌 Wireless Interface: $WIRELESS_INTERFACE"
    echo "   🌐 Internet Interface: $ETHERNET_INTERFACE"
    echo "   📜 Contract ID: $CONTRACT_ID"
    echo ""
    echo -e "${YELLOW} Start Your Captive Portal:${NC}"
    echo "   sudo zaanet start"
    echo ""
    echo -e "${YELLOW}📱 For Users to Connect:${NC}"
    echo "   1. Connect to Wi-Fi: '$WIFI_SSID'"
    echo "   2. Open any website in browser"
    echo "   3. Get redirected to captive portal"
    echo "   4. Complete authentication"
    echo "   5. Enjoy internet access!"
    echo ""
    echo -e "${YELLOW}⚙️ Management Commands:${NC}"
    echo "   zaanet status      # Check current status"
    echo "   zaanet stop        # Return to normal internet"
    echo "   zaanet restart     # Restart services"
    echo "   zaanet logs        # View live logs"
    echo "   zaanet config      # Show configuration"
    echo "   zaanet firewall    # Manage user access"
    echo ""
    echo -e "${BLUE}🔧 Optional Configuration:${NC}"
    if [[ "$AUTO_START" =~ ^[Yy] ]]; then
        echo "   ✅ Auto-start enabled - portal will start on boot"
    else
        echo "   ⚙️ Enable auto-start: sudo zaanet enable"
    fi
    echo "   📄 Edit config: nano $ZAANET_DIR/app/.env"
    echo "   🔄 Update ZaaNet: zaanet update"
    echo ""
    echo -e "${PURPLE}🎯 Quick Test:${NC}"
    echo "   sudo zaanet start"
    echo "   # Connect phone/laptop to '$WIFI_SSID'"
    echo "   # Open browser → automatic redirect to portal"
    echo ""
    echo -e "${GREEN}📚 Documentation & Support:${NC}"
    echo "   📖 Docs: https://docs.zaanet.xyz"
    echo "   🐛 Issues: https://github.com/yourusername/zaanet/issues"
    echo "   💬 Support: support@zaanet.xyz"
}
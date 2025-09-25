auto_detect_interfaces() {    
    # Detect wireless interface
    WIRELESS_INTERFACE=""
    for interface in wlan0 wlp2s0 wlp3s0 wlx* wlo1; do
        if ip link show "$interface" >/dev/null 2>&1; then
            WIRELESS_INTERFACE="$interface"
            break
        fi
    done
    
    # Try alternative detection methods for wireless
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        WIRELESS_INTERFACE=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2; exit}')
    fi
    
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        WIRELESS_INTERFACE=$(find /sys/class/net -name "wl*" -type l -exec basename {} \; 2>/dev/null | head -1)
    fi
    
    # Detect ethernet interface
    ETHERNET_INTERFACE=""
    for interface in eth0 enp1s0 enp1s0f0 eno1 end0; do
        if ip link show "$interface" >/dev/null 2>&1; then
            ETHERNET_INTERFACE="$interface"
            break
        fi
    done
    
    # Try alternative detection for ethernet
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        ETHERNET_INTERFACE=$(ip link | grep -oE '(eth[0-9]+|enp[0-9]+s[0-9]+[f0-9]*|eno[0-9]+)' | head -1)
    fi
    
    # Display results
    echo "   📡 Wireless Interface: ${WIRELESS_INTERFACE:-Not detected}"
    echo "   🌐 Ethernet Interface: ${ETHERNET_INTERFACE:-Not detected}"
    
    # Validation
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        error "No wireless interface detected. ZaaNet requires Wi-Fi capability."
    fi
    
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        warning "No ethernet interface detected. You'll need to configure internet source manually."
        echo "   You can use USB-to-Ethernet adapter or configure Wi-Fi client mode later."
        read -p "Continue without ethernet? [y/N]: " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy] ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        ETHERNET_INTERFACE="eth0"  # Default fallback
    fi
    
    success "Network interfaces detected"
}
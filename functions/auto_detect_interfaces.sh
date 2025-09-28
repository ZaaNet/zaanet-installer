#!/bin/bash
# functions/auto_detect_interfaces.sh
# Auto-detect wireless and ethernet network interfaces

auto_detect_interfaces() {
    log "🔍 Auto-detecting network interfaces..."
    
    # Initialize variables
    WIRELESS_INTERFACE=""
    ETHERNET_INTERFACE=""
    
    # =============================================================================
    # WIRELESS INTERFACE DETECTION
    # =============================================================================
    
    log "Scanning for wireless interfaces..."
    
    # Method 1: Check common wireless interface names
    local wireless_patterns=(
        "wlan0"      # Most common on Raspberry Pi
        "wlp2s0"     # PCIe wireless cards
        "wlp3s0"     # Alternative PCIe slot
        "wlx*"       # USB wireless adapters (wildcard)
        "wlo1"       # Some laptops
        "wlp0s*"     # Another PCIe pattern
    )
    
    for pattern in "${wireless_patterns[@]}"; do
        # Handle wildcard patterns differently
        if [[ "$pattern" == *"*"* ]]; then
            # Use find for wildcard patterns
            local found_interfaces
            found_interfaces=$(find /sys/class/net -name "${pattern}" -type l -exec basename {} \; 2>/dev/null)
            if [[ -n "$found_interfaces" ]]; then
                WIRELESS_INTERFACE=$(echo "$found_interfaces" | head -1)
                log "Found wireless interface (wildcard): $WIRELESS_INTERFACE"
                break
            fi
        else
            # Direct check for exact names
            if ip link show "$pattern" >/dev/null 2>&1; then
                WIRELESS_INTERFACE="$pattern"
                log "Found wireless interface: $WIRELESS_INTERFACE"
                break
            fi
        fi
    done
    
    # Method 2: Use iw command to detect wireless interfaces
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        log "Trying iw command for wireless detection..."
        if command -v iw >/dev/null 2>&1; then
            WIRELESS_INTERFACE=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2; exit}')
            if [[ -n "$WIRELESS_INTERFACE" ]]; then
                log "Found wireless interface via iw: $WIRELESS_INTERFACE"
            fi
        fi
    fi
    
    # Method 3: Search in /sys/class/net for any wireless interface
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        log "Searching /sys/class/net for wireless interfaces..."
        WIRELESS_INTERFACE=$(find /sys/class/net -name "wl*" -type l -exec basename {} \; 2>/dev/null | head -1)
        if [[ -n "$WIRELESS_INTERFACE" ]]; then
            log "Found wireless interface in sysfs: $WIRELESS_INTERFACE"
        fi
    fi
    
    # Method 4: Check for any interface with wireless capabilities
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        log "Checking for wireless capabilities in all interfaces..."
        for interface in /sys/class/net/*/wireless; do
            if [[ -d "$interface" ]]; then
                WIRELESS_INTERFACE=$(basename "$(dirname "$interface")")
                log "Found interface with wireless capabilities: $WIRELESS_INTERFACE"
                break
            fi
        done
    fi
    
    # =============================================================================
    # ETHERNET INTERFACE DETECTION
    # =============================================================================
    
    log "Scanning for ethernet interfaces..."
    
    # Method 1: Check common ethernet interface names
    local ethernet_patterns=(
        "eth0"       # Traditional naming
        "enp1s0"     # Predictable network interface names
        "enp1s0f0"   # Multi-function cards
        "eno1"       # Onboard ethernet
        "end0"       # Some systems
        "enp0s*"     # PCIe ethernet (wildcard)
        "ens*"       # Some naming schemes
    )
    
    for pattern in "${ethernet_patterns[@]}"; do
        # Handle wildcard patterns
        if [[ "$pattern" == *"*"* ]]; then
            # Use shell globbing for wildcards
            for interface in /sys/class/net/${pattern}; do
                if [[ -L "$interface" ]]; then
                    ETHERNET_INTERFACE=$(basename "$interface")
                    log "Found ethernet interface (wildcard): $ETHERNET_INTERFACE"
                    break 2  # Break out of both loops
                fi
            done
        else
            # Direct check for exact names
            if ip link show "$pattern" >/dev/null 2>&1; then
                ETHERNET_INTERFACE="$pattern"
                log "Found ethernet interface: $ETHERNET_INTERFACE"
                break
            fi
        fi
    done
    
    # Method 2: Use ip command to find ethernet interfaces
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        log "Using ip command to detect ethernet interfaces..."
        ETHERNET_INTERFACE=$(ip link show | grep -oE 'eth[0-9]+|enp[0-9]+s[0-9]+[f0-9]*|eno[0-9]+|ens[0-9]+' | head -1)
        if [[ -n "$ETHERNET_INTERFACE" ]]; then
            log "Found ethernet interface via ip command: $ETHERNET_INTERFACE"
        fi
    fi
    
    # Method 3: Find any non-wireless, non-loopback interface
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        log "Looking for any wired network interface..."
        while IFS= read -r interface; do
            # Skip loopback, wireless, and virtual interfaces
            if [[ "$interface" != "lo" ]] && 
               [[ "$interface" != wl* ]] && 
               [[ "$interface" != docker* ]] && 
               [[ "$interface" != br-* ]] && 
               [[ "$interface" != virbr* ]] && 
               [[ -d "/sys/class/net/$interface" ]] && 
               [[ ! -d "/sys/class/net/$interface/wireless" ]]; then
                ETHERNET_INTERFACE="$interface"
                log "Found wired interface: $ETHERNET_INTERFACE"
                break
            fi
        done < <(ls /sys/class/net/)
    fi
    
    # =============================================================================
    # INTERFACE VALIDATION
    # =============================================================================
    
    validate_interfaces() {
        log "Validating detected interfaces..."
        
        # Validate wireless interface
        if [[ -n "$WIRELESS_INTERFACE" ]]; then
            if ip link show "$WIRELESS_INTERFACE" >/dev/null 2>&1; then
                # Check if it actually has wireless capabilities
                if [[ -d "/sys/class/net/$WIRELESS_INTERFACE/wireless" ]] || 
                   iw dev "$WIRELESS_INTERFACE" info >/dev/null 2>&1; then
                    success "✓ Wireless interface validated: $WIRELESS_INTERFACE"
                else
                    warning "Interface $WIRELESS_INTERFACE exists but may not have wireless capabilities"
                fi
            else
                warning "Detected wireless interface $WIRELESS_INTERFACE is not available"
                WIRELESS_INTERFACE=""
            fi
        fi
        
        # Validate ethernet interface
        if [[ -n "$ETHERNET_INTERFACE" ]]; then
            if ip link show "$ETHERNET_INTERFACE" >/dev/null 2>&1; then
                success "✓ Ethernet interface validated: $ETHERNET_INTERFACE"
            else
                warning "Detected ethernet interface $ETHERNET_INTERFACE is not available"
                ETHERNET_INTERFACE=""
            fi
        fi
    }
    
    validate_interfaces
    
    # =============================================================================
    # DISPLAY RESULTS
    # =============================================================================
    
    echo ""
    echo -e "${CYAN}🔍 Network Interface Detection Results:${NC}"
    echo "   📡 Wireless Interface: ${WIRELESS_INTERFACE:-${RED}Not detected${NC}}"
    echo "   🌐 Ethernet Interface: ${ETHERNET_INTERFACE:-${YELLOW}Not detected${NC}}"
    
    # Display interface details if found
    if [[ -n "$WIRELESS_INTERFACE" ]]; then
        local wifi_state
        wifi_state=$(ip link show "$WIRELESS_INTERFACE" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
        echo "   📡 Wireless State: ${wifi_state:-UNKNOWN}"
    fi
    
    if [[ -n "$ETHERNET_INTERFACE" ]]; then
        local eth_state
        eth_state=$(ip link show "$ETHERNET_INTERFACE" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2)
        echo "   🌐 Ethernet State: ${eth_state:-UNKNOWN}"
    fi
    
    # =============================================================================
    # REQUIREMENT VALIDATION
    # =============================================================================
    
    # Wireless interface is mandatory for captive portal
    if [[ -z "$WIRELESS_INTERFACE" ]]; then
        echo ""
        error "❌ No wireless interface detected. ZaaNet requires Wi-Fi capability for the captive portal."
        echo ""
        echo "Possible solutions:"
        echo "• Connect a USB Wi-Fi adapter"
        echo "• Enable Wi-Fi if disabled"
        echo "• Check if wireless drivers are installed"
        echo ""
        echo "To check wireless capability manually:"
        echo "  sudo iw dev"
        echo "  lsusb | grep -i wireless"
        echo "  lspci | grep -i wireless"
        exit 1
    fi
    
    # Ethernet is recommended but not mandatory
    if [[ -z "$ETHERNET_INTERFACE" ]]; then
        echo ""
        warning "⚠️  No ethernet interface detected."
        echo ""
        echo "This means:"
        echo "• No wired internet connection available"
        echo "• You'll need alternative internet source (USB tethering, Wi-Fi client mode)"
        echo "• Manual configuration may be required"
        echo ""
        
        # Give user option to continue
        read -p "Continue installation without ethernet? [y/N]: " -r CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            echo "Installation cancelled by user."
            exit 0
        fi
        
        # Set a default fallback for configuration files
        ETHERNET_INTERFACE="eth0"
        warning "Using fallback ethernet interface name: $ETHERNET_INTERFACE"
    fi
    
    # =============================================================================
    # EXPORT VARIABLES
    # =============================================================================
    
    # Export for use in other functions
    export WIRELESS_INTERFACE
    export ETHERNET_INTERFACE
    
    echo ""
    success "✅ Network interface detection completed"
    log "Wireless: $WIRELESS_INTERFACE | Ethernet: $ETHERNET_INTERFACE"
}
#!/bin/bash
# functions/check_device_compatibility.sh
# Check if device can run ZaaNet (hostapd + dnsmasq + iptables)

check_device_compatibility() {
    log "🔍 Checking ZaaNet compatibility..."
    
    local requirements_met=true
    local is_raspberry_pi=false
    
    # Check if this is a Raspberry Pi
    if [[ -f /proc/device-tree/model ]]; then
        local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
        if [[ "$model" =~ [Rr]aspberry.*[Pp]i ]]; then
            is_raspberry_pi=true
            log "✓ Raspberry Pi detected: $model"
        fi
    fi
    local is_raspberry_pi=false
    
    # Check if this is a Raspberry Pi
    if [[ -f /proc/device-tree/model ]]; then
        local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
        if [[ "$model" =~ [Rr]aspberry.*[Pp]i ]]; then
            is_raspberry_pi=true
            log "✓ Raspberry Pi detected: $model"
        fi
    fi
    
    # =============================================================================
    # ESSENTIAL REQUIREMENTS CHECK
    # =============================================================================
    
    # 1. Check for Wi-Fi capability (absolutely required)
    check_wifi() {
        log "Checking Wi-Fi capability..."
        
        # Check for wireless interfaces
        if iw dev 2>/dev/null | grep -q "Interface" || 
           ls /sys/class/net/*/wireless 2>/dev/null | grep -q wireless; then
            success "✓ Wi-Fi capability detected"
            return 0
        else
            error "❌ No Wi-Fi capability found. ZaaNet requires wireless AP functionality."
            return 1
        fi
    }
    
    # 2. Check if we can install required packages
    check_package_manager() {
        log "Checking package manager..."
        
        if command -v apt-get >/dev/null; then
            export PKG_MANAGER="apt"
            success "✓ APT package manager found"
        elif command -v yum >/dev/null; then
            export PKG_MANAGER="yum" 
            success "✓ YUM package manager found"
        elif command -v dnf >/dev/null; then
            export PKG_MANAGER="dnf"
            success "✓ DNF package manager found"
        elif command -v pacman >/dev/null; then
            export PKG_MANAGER="pacman"
            success "✓ Pacman package manager found"
        else
            error "❌ No supported package manager found (apt/yum/dnf/pacman)"
            return 1
        fi
    }
    
    # 3. Check for systemd (needed for services)
    check_systemd() {
        log "Checking systemd..."
        
        if systemctl --version >/dev/null 2>&1; then
            success "✓ systemd found"
            return 0
        else
            error "❌ systemd required for ZaaNet services"
            return 1
        fi
    }
    
    # 4. Check if we can install/use iptables
    check_iptables() {
        log "Checking iptables capability..."
        
        # Check if already installed
        if command -v iptables >/dev/null; then
            if iptables -L >/dev/null 2>&1; then
                success "✓ iptables already installed and accessible"
                return 0
            else
                warning "iptables installed but needs root access"
            fi
        fi
        
        # Check if we can install it
        case "$PKG_MANAGER" in
            "apt")
                if apt-cache show iptables >/dev/null 2>&1; then
                    success "✓ iptables available for installation"
                    return 0
                fi
                ;;
            "yum"|"dnf")
                if $PKG_MANAGER info iptables >/dev/null 2>&1; then
                    success "✓ iptables available for installation"
                    return 0
                fi
                ;;
            "pacman")
                if pacman -Si iptables >/dev/null 2>&1; then
                    success "✓ iptables available for installation"
                    return 0
                fi
                ;;
        esac
        
        error "❌ Cannot find iptables package"
        return 1
    }
    
    # 5. Check minimum resources
    check_resources() {
        log "Checking system resources..."
        
        # RAM check
        local ram_mb=$(grep MemTotal /proc/meminfo | awk '{print int($2/1024)}')
        if [[ "$ram_mb" -lt 256 ]]; then
            error "❌ Insufficient RAM: ${ram_mb}MB (minimum: 256MB)"
            return 1
        else
            success "✓ Sufficient RAM: ${ram_mb}MB"
        fi
        
        # Storage check  
        local storage_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
        if [[ "$storage_gb" -lt 1 ]]; then
            error "❌ Insufficient storage: ${storage_gb}GB (minimum: 1GB)"
            return 1
        else
            success "✓ Sufficient storage: ${storage_gb}GB"
        fi
        
        return 0
    }
    
    # =============================================================================
    # RUN ALL CHECKS
    # =============================================================================
    
    echo ""
    echo -e "${CYAN}📋 ZaaNet Compatibility Check${NC}"
    echo ""
    
    check_wifi || requirements_met=false
    check_package_manager || requirements_met=false  
    check_systemd || requirements_met=false
    check_iptables || requirements_met=false
    check_resources || requirements_met=false
    
    # =============================================================================
    # FINAL DECISION
    # =============================================================================
    
    echo ""
    if [[ "$requirements_met" == true ]]; then
        success "🎉 Device is compatible with ZaaNet!"
        log "Ready to install hostapd, dnsmasq, and configure captive portal"
        
        # Export for other functions
        export IS_RASPBERRY_PI="$is_raspberry_pi"
        
        return 0
    else
        error "❌ Device does not meet ZaaNet requirements"
        echo ""
        echo "Required for ZaaNet:"
        echo "• Wi-Fi adapter with AP mode support"
        echo "• Package manager (apt/yum/dnf/pacman)"
        echo "• systemd for service management"  
        echo "• iptables access for NAT/forwarding"
        echo "• Minimum 256MB RAM, 1GB storage"
        exit 1
    fi
}
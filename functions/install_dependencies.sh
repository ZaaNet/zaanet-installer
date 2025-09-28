#!/bin/bash
# functions/install_dependencies.sh
# Install required packages for ZaaNet

install_dependencies() {
    log "📦 Installing ZaaNet dependencies..."
    
    # =============================================================================
    # UPDATE PACKAGE LISTS
    # =============================================================================
    
    update_packages() {
        log "Updating package lists..."
        case "$PKG_MANAGER" in
            "apt")
                apt-get update -y
                ;;
            "yum")
                yum check-update || true
                ;;
            "dnf") 
                dnf check-update || true
                ;;
            "pacman")
                pacman -Sy --noconfirm
                ;;
        esac
    }
    
    # =============================================================================
    # INSTALL CORE DEPENDENCIES
    # =============================================================================
    
    install_core_packages() {
        log "Installing core packages..."
        
        case "$PKG_MANAGER" in
            "apt")
                apt-get install -y \
                    curl wget git unzip \
                    build-essential \
                    hostapd dnsmasq \
                    iptables iptables-persistent \
                    iw \
                    systemd net-tools \
                    jq
                
                # Try to install wireless-tools, but don't fail if unavailable
                apt-get install -y wireless-tools 2>/dev/null || log "wireless-tools not available, using iw instead"
                ;;
            "yum")
                yum install -y \
                    curl wget git unzip \
                    gcc gcc-c++ make \
                    hostapd dnsmasq \
                    iptables iptables-services \
                    iw wireless-tools \
                    systemd net-tools \
                    jq
                ;;
            "dnf")
                dnf install -y \
                    curl wget git unzip \
                    gcc gcc-c++ make \
                    hostapd dnsmasq \
                    iptables iptables-services \
                    iw wireless-tools \
                    systemd net-tools \
                    jq
                ;;
            "pacman")
                pacman -S --noconfirm \
                    curl wget git unzip \
                    base-devel \
                    hostapd dnsmasq \
                    iptables \
                    iw wireless_tools \
                    systemd net-tools \
                    jq
                ;;
        esac
    }
    
    # =============================================================================
    # INSTALL NODE.JS
    # =============================================================================
    
    install_nodejs() {
        if command -v node >/dev/null 2>&1; then
            local node_version=$(node --version)
            log "Node.js already installed: $node_version"
            return 0
        fi
        
        log "Installing Node.js..."
        
        case "$PKG_MANAGER" in
            "apt")
                # Install NodeSource repository
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
                apt-get install -y nodejs
                ;;
            "yum"|"dnf")
                # Install NodeSource repository  
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
                $PKG_MANAGER install -y nodejs
                ;;
            "pacman")
                pacman -S --noconfirm nodejs npm
                ;;
        esac
        
        # Verify installation
        if command -v node >/dev/null 2>&1; then
            success "✓ Node.js installed: $(node --version)"
        else
            error "Failed to install Node.js"
        fi
    }
    
    # =============================================================================
    # INSTALL PM2
    # =============================================================================
    
    install_pm2() {
        if command -v pm2 >/dev/null 2>&1; then
            log "PM2 already installed"
            return 0
        fi
        
        log "Installing PM2 process manager..."
        
        if command -v npm >/dev/null 2>&1; then
            npm install -g pm2
            
            # Verify installation
            if command -v pm2 >/dev/null 2>&1; then
                success "✓ PM2 installed"
            else
                error "Failed to install PM2"
            fi
        else
            error "npm not available - cannot install PM2"
        fi
    }
    
    # =============================================================================
    # VERIFY CRITICAL SERVICES
    # =============================================================================
    
    verify_services() {
        log "Verifying critical services..."
        
        local services=("hostapd" "dnsmasq")
        local missing_services=()
        
        for service in "${services[@]}"; do
            if command -v "$service" >/dev/null 2>&1; then
                success "✓ $service installed"
            else
                missing_services+=("$service")
                error "✗ $service not found"
            fi
        done
        
        if [[ ${#missing_services[@]} -gt 0 ]]; then
            error "Missing critical services: ${missing_services[*]}"
            exit 1
        fi
    }
    
    # =============================================================================
    # RUN INSTALLATION
    # =============================================================================
    
    update_packages
    install_core_packages
    install_nodejs  
    install_pm2
    verify_services
    
    success "✅ All dependencies installed successfully"
}

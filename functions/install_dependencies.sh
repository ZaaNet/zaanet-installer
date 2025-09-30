#!/bin/bash
# functions/install_dependencies.sh

install_dependencies() {
    log "📦 Installing ZaaNet dependencies..."
    
    update_packages() {
        log "Updating package lists..."
        case "$PKG_MANAGER" in
            "apt") apt-get update -y ;;
            "yum") yum check-update || true ;;
            "dnf") dnf check-update || true ;;
            "pacman") pacman -Sy --noconfirm ;;
        esac
    }
    
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
                systemd net-tools jq \
                python3 python3-pip python3-dev
            
            # Try libnetfilter-queue-dev (optional)
            apt-get install -y libnetfilter-queue-dev 2>/dev/null || \
            apt-get install -y libnetfilter-queue1 2>/dev/null || \
            log "libnetfilter-queue not available, continuing..."
            ;;
        "yum")
            yum install -y \
                curl wget git unzip \
                gcc gcc-c++ make \
                hostapd dnsmasq \
                iptables iptables-services \
                iw wireless-tools \
                systemd net-tools jq \
                python3 python3-pip python3-devel \
                libnetfilter_queue-devel
            ;;
        "dnf")
            dnf install -y \
                curl wget git unzip \
                gcc gcc-c++ make \
                hostapd dnsmasq \
                iptables iptables-services \
                iw wireless-tools \
                systemd net-tools jq \
                python3 python3-pip python3-devel \
                libnetfilter_queue-devel
            ;;
        "pacman")
            pacman -S --noconfirm \
                curl wget git unzip base-devel \
                hostapd dnsmasq iptables \
                iw wireless_tools \
                systemd net-tools jq \
                python python-pip \
                libnetfilter_queue
            ;;
    esac
}
    
    install_python_packages() {
        log "Installing Python packages for traffic monitoring..."
        
        # Install via pip
        if pip3 install netfilterqueue scapy 2>/dev/null; then
            success "✓ Python packages installed via pip"
        elif pip3 install --break-system-packages netfilterqueue scapy 2>/dev/null; then
            success "✓ Python packages installed via pip (with override)"
        else
            error "Failed to install Python packages"
            log "Manual fix: sudo apt install libnetfilter-queue-dev && sudo pip3 install --break-system-packages netfilterqueue scapy"
            exit 1
        fi
        
        # Verify
        if python3 -c "from netfilterqueue import NetfilterQueue; from scapy.all import IP" 2>/dev/null; then
            success "✓ Python packages verified"
        else
            error "Python package import failed"
            exit 1
        fi
    }
    
    install_nodejs() {
        if command -v node >/dev/null 2>&1; then
            log "Node.js already installed: $(node --version)"
            return 0
        fi
        
        log "Installing Node.js..."
        
        case "$PKG_MANAGER" in
            "apt")
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
                apt-get install -y nodejs
                ;;
            "yum"|"dnf")
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
                $PKG_MANAGER install -y nodejs
                ;;
            "pacman")
                pacman -S --noconfirm nodejs npm
                ;;
        esac
        
        command -v node >/dev/null 2>&1 && success "✓ Node.js installed: $(node --version)" || error "Failed to install Node.js"
    }
    
    install_pm2() {
        if command -v pm2 >/dev/null 2>&1; then
            log "PM2 already installed"
            return 0
        fi
        
        log "Installing PM2..."
        npm install -g pm2
        command -v pm2 >/dev/null 2>&1 && success "✓ PM2 installed" || error "Failed to install PM2"
    }
    
    verify_services() {
        log "Verifying critical services..."
        
        local services=("hostapd" "dnsmasq" "python3" "node")
        local missing=()
        
        for service in "${services[@]}"; do
            if command -v "$service" >/dev/null 2>&1; then
                success "✓ $service"
            else
                missing+=("$service")
                error "✗ $service not found"
            fi
        done
        
        [[ ${#missing[@]} -eq 0 ]] || { error "Missing: ${missing[*]}"; exit 1; }
    }
    
    # Execute
    update_packages
    install_core_packages
    install_python_packages
    install_nodejs
    install_pm2
    verify_services
    
    success "✅ All dependencies installed"
}

install_dependencies() {    
    # Update package list
    apt-get update -y
    
    # Install core dependencies
    apt-get install -y \
        curl wget git unzip \
        build-essential \
        hostapd dnsmasq \
        iptables iptables-persistent \
        iw wireless-tools \
        systemd net-tools \
        jq
    
    # Install Node.js (LTS)
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        apt-get install -y nodejs
    else
        log "Node.js already installed: $(node --version)"
    fi
    
    # Install PM2 for process management
    if ! command -v pm2 &> /dev/null; then
        log "Installing PM2..."
        npm install -g pm2
    else
        log "PM2 already installed"
    fi
    
    success "All dependencies installed"
}
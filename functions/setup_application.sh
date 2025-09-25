setup_application() {
    echo "Setting up ZaaNet application..."
    
    # Create directory structure
    mkdir -p "$ZAANET_DIR"/{app,scripts,configs,logs,data}
    
    # Clone ZaaNet repo
    if [ ! -d "$ZAANET_DIR/app/.git" ]; then
        log "Downloading ZaaNet application..."
        git clone "$GITHUB_REPO" "$ZAANET_DIR/app" || {
            error "Failed to download ZaaNet application. Check your internet connection and repository URL."
        }
    else
        log "Updating existing ZaaNet application..."
        cd "$ZAANET_DIR/app"
        git pull || warning "Failed to update application"
    fi
    
    cd "$ZAANET_DIR/app"
    
    # Install project dependencies
    log "Installing Node.js dependencies..."
    npm install || {
        error "Failed to install Node.js dependencies"
    }
    
    # Setup environment variables
    log "Configuring environment..."
   cat <<EOF > .env
# ZaaNet Auto-Configuration
PORTAL_IP=$PORTAL_IP
PORTAL_PORT=$PORTAL_PORT
PORTAL_DOMAIN=$PORTAL_DOMAIN
WIRELESS_INTERFACE=$WIRELESS_INTERFACE
ETHERNET_INTERFACE=$ETHERNET_INTERFACE
DNS_SERVER=$DNS_SERVER

# Network Configuration
WIFI_SSID=$WIFI_SSID
DHCP_START=$DHCP_START
DHCP_END=$DHCP_END
CONTRACT_ID=$CONTRACT_ID

# Main server configuration
MAIN_SERVER_URL=$MAIN_SERVER_URL

# Node Environment
NODE_ENV=production

# Auto-installer metadata
INSTALLER_VERSION=1.0.0
INSTALL_DATE="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
DEVICE_MODEL="$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown")"
EOF
    
    # Application is pre-built, no build step needed
    log "Using pre-built application from release repository"
    
    success "Application setup complete"
}
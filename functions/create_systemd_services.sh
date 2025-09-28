#!/bin/bash
# functions/create_systemd_services.sh
# Create systemd service files for ZaaNet

create_systemd_services() {
    log "🔧 Creating systemd services..."
    
    # Validate environment
    if [[ -z "$ZAANET_USER" ]]; then
        error "ZAANET_USER is empty!"
    fi
    
    if [[ -z "$ZAANET_DIR" ]]; then
        error "ZAANET_DIR is empty!"
    fi
    
    # Test write permissions
    if ! touch /etc/systemd/system/zaanet.service.test 2>/dev/null; then
        error "Cannot write to /etc/systemd/system/ - check permissions"
    fi
    rm -f /etc/systemd/system/zaanet.service.test
    
    # Create ZaaNet application service
    log "Creating zaanet.service..."
    
    cat > /etc/systemd/system/zaanet.service <<EOF
[Unit]
Description=ZaaNet Captive Portal Application
After=network.target zaanet-manager.service
Wants=network-online.target
Requires=zaanet-manager.service

[Service]
Type=simple
User=$ZAANET_USER
Group=$ZAANET_USER
WorkingDirectory=$ZAANET_DIR/app
ExecStart=/usr/bin/node server.js
Environment=NODE_ENV=production
Environment=ZAANET_DIR=$ZAANET_DIR
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=HOME=$ZAANET_DIR
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    # Verify zaanet.service
    if [[ ! -f /etc/systemd/system/zaanet.service || ! -s /etc/systemd/system/zaanet.service ]]; then
        error "zaanet.service file was not created properly"
    fi
    
    # Create ZaaNet network manager service
    log "Creating zaanet-manager.service..."
    
    cat > /etc/systemd/system/zaanet-manager.service <<EOF
[Unit]
Description=ZaaNet Network Manager
After=network.target
Before=zaanet.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$ZAANET_DIR/scripts/zaanet-switcher.sh --zaanet
ExecStop=$ZAANET_DIR/scripts/zaanet-switcher.sh --normal
TimeoutStartSec=120
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF
    
    # Verify zaanet-manager.service
    if [[ ! -f /etc/systemd/system/zaanet-manager.service || ! -s /etc/systemd/system/zaanet-manager.service ]]; then
        error "zaanet-manager.service file was not created properly"
    fi
    
    # Verify the switcher script exists
    if [[ ! -f "$ZAANET_DIR/scripts/zaanet-switcher.sh" ]]; then
        warning "⚠️ zaanet-switcher.sh not found at $ZAANET_DIR/scripts/zaanet-switcher.sh"
    else
        chmod +x "$ZAANET_DIR/scripts/zaanet-switcher.sh"
    fi
    
    # Reload systemd
    if ! systemctl daemon-reload; then
        error "Failed to reload systemd daemon"
    fi
    
    success "✅ Systemd services created successfully"
}
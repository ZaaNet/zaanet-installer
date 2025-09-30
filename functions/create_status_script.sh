#!/bin/bash
# functions/create_status_script.sh

create_status_script() {
    log "Creating status monitoring script..."
    
    mkdir -p "$ZAANET_DIR/scripts"
    
    cat > "$ZAANET_DIR/scripts/zaanet-status.sh" <<'EOF'
#!/bin/bash
# ZaaNet Status Monitor

# ... (your status script content) ...
EOF
    
    # Replace placeholders
    sed -i "s|%WIRELESS_INTERFACE%|$WIRELESS_INTERFACE|g" "$ZAANET_DIR/scripts/zaanet-status.sh"
    sed -i "s|%WIFI_SSID%|$WIFI_SSID|g" "$ZAANET_DIR/scripts/zaanet-status.sh"
    sed -i "s|%PORTAL_IP%|$PORTAL_IP|g" "$ZAANET_DIR/scripts/zaanet-status.sh"
    
    chmod +x "$ZAANET_DIR/scripts/zaanet-status.sh"
    chown "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR/scripts/zaanet-status.sh"
    
    success "✓ Status script created"
}

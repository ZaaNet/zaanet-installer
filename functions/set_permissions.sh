set_permissions() {    
    # Set ownership
    chown -R "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR"
    
    # Set script permissions
    chmod +x "$ZAANET_DIR/scripts"/*.sh
    
    # Create log files with proper permissions
    touch /var/log/zaanet.log /var/log/zaanet-firewall.log
    chown "$ZAANET_USER:$ZAANET_USER" /var/log/zaanet*.log
    chmod 644 /var/log/zaanet*.log
    
    success "✅ Permissions configured"
}
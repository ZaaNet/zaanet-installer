configure_auto_start() {
    if [[ "$AUTO_START" =~ ^[Yy] ]]; then
        echo "Configuring auto-start on boot..."
        systemctl enable zaanet-manager
        systemctl enable zaanet
        success "ZaaNet will start automatically on boot"
    else
        log "Auto-start disabled by user choice"
    fi
}
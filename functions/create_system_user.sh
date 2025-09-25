create_system_user() {
    echo "👤 Creating ZaaNet system user..."
    
    if ! id "$ZAANET_USER" &>/dev/null; then
        # Create user with home directory and bash shell (like a regular user, not system user)
        useradd -m -s /bin/bash "$ZAANET_USER" -c "ZaaNet Service User"
        log "Created user: $ZAANET_USER"
    else
        log "User $ZAANET_USER already exists"
        # Ensure user has proper shell and home directory
        usermod -s /bin/bash "$ZAANET_USER"
        usermod -d "/home/$ZAANET_USER" "$ZAANET_USER"
    fi
    
    # Give zaanet complete sudo privileges
    log "Granting complete sudo privileges to $ZAANET_USER..."
    tee /etc/sudoers.d/zaanet << EOF
# ZaaNet user - complete sudo privileges
$ZAANET_USER ALL=(ALL) NOPASSWD: ALL
EOF
    
    chmod 440 /etc/sudoers.d/zaanet
    
    # Add to common groups for device access
    usermod -aG sudo,adm,dialout,cdrom,floppy,audio,dip,video,plugdev,netdev,lpadmin "$ZAANET_USER" 2>/dev/null || true
    
    success "✅ System user ready with complete privileges"
}
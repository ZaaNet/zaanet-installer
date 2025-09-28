#!/bin/bash
# functions/set_permissions.sh
# Set proper file permissions and ownership for ZaaNet

set_permissions() {
    log "🔒 Setting file permissions and ownership..."
    
    # =============================================================================
    # VALIDATE ENVIRONMENT
    # =============================================================================
    
    if [[ -z "$ZAANET_USER" ]]; then
        error "ZAANET_USER is not set"
    fi
    
    if [[ -z "$ZAANET_DIR" ]]; then
        error "ZAANET_DIR is not set"
    fi
    
    if [[ ! -d "$ZAANET_DIR" ]]; then
        error "ZaaNet directory does not exist: $ZAANET_DIR"
    fi
    
    # =============================================================================
    # SET DIRECTORY OWNERSHIP
    # =============================================================================
    
    log "Setting directory ownership..."
    
    # Set ownership of main directory
    if chown -R "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR"; then
        success "✓ Directory ownership set to $ZAANET_USER"
    else
        error "Failed to set directory ownership"
    fi
    
    # =============================================================================
    # SET SCRIPT PERMISSIONS
    # =============================================================================
    
    log "Setting script permissions..."
    
    # Make scripts executable
    if [[ -d "$ZAANET_DIR/scripts" ]]; then
        if chmod +x "$ZAANET_DIR/scripts"/*.sh 2>/dev/null; then
            success "✓ Scripts made executable"
        else
            warning "No script files found or permission setting failed"
        fi
    else
        warning "Scripts directory not found: $ZAANET_DIR/scripts"
    fi
    
    # =============================================================================
    # SET APPLICATION PERMISSIONS
    # =============================================================================
    
    log "Setting application file permissions..."
    
    # Application directory permissions
    if [[ -d "$ZAANET_DIR/app" ]]; then
        chmod 755 "$ZAANET_DIR/app"
        find "$ZAANET_DIR/app" -type f -name "*.js" -exec chmod 644 {} \;
        find "$ZAANET_DIR/app" -type d -exec chmod 755 {} \;
    fi
    
    # Configuration files (more restrictive)
    if [[ -f "$ZAANET_DIR/app/.env" ]]; then
        chmod 600 "$ZAANET_DIR/app/.env"
        log "✓ Environment file secured (600)"
    fi
    
    if [[ -d "$ZAANET_DIR/configs" ]]; then
        chmod 700 "$ZAANET_DIR/configs"
        find "$ZAANET_DIR/configs" -type f -exec chmod 600 {} \;
        log "✓ Configuration files secured"
    fi
    
    # =============================================================================
    # CREATE AND SET LOG FILE PERMISSIONS
    # =============================================================================
    
    log "Setting up log files..."
    
    # Create log files with proper permissions
    local log_files=(
        "/var/log/zaanet.log"
        "/var/log/zaanet-firewall.log"
    )
    
    for log_file in "${log_files[@]}"; do
        if touch "$log_file"; then
            chown "$ZAANET_USER:$ZAANET_USER" "$log_file"
            chmod 644 "$log_file"
            log "✓ Created and configured: $(basename "$log_file")"
        else
            warning "Failed to create log file: $log_file"
        fi
    done
    
    # Create ZaaNet log directory if needed
    if [[ -d "$ZAANET_DIR/logs" ]]; then
        chmod 755 "$ZAANET_DIR/logs"
        chown "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR/logs"
    fi
    
    # =============================================================================
    # SET DATA DIRECTORY PERMISSIONS
    # =============================================================================
    
    log "Setting data directory permissions..."
    
    if [[ -d "$ZAANET_DIR/data" ]]; then
        chmod 700 "$ZAANET_DIR/data"
        log "✓ Data directory secured (700)"
    fi
    
    if [[ -d "$ZAANET_DIR/backups" ]]; then
        chmod 700 "$ZAANET_DIR/backups"
        log "✓ Backup directory secured (700)"
    fi
    
    # =============================================================================
    # VERIFY PERMISSIONS
    # =============================================================================
    
    verify_permissions() {
        log "Verifying permissions..."
        
        # Check if zaanet user owns the directory
        local owner=$(stat -c '%U' "$ZAANET_DIR" 2>/dev/null)
        if [[ "$owner" == "$ZAANET_USER" ]]; then
            success "✓ Directory ownership verified"
        else
            warning "Directory owner is '$owner', expected '$ZAANET_USER'"
        fi
        
        # Check script executability
        local script_count=0
        if [[ -d "$ZAANET_DIR/scripts" ]]; then
            script_count=$(find "$ZAANET_DIR/scripts" -name "*.sh" -executable | wc -l)
            if [[ $script_count -gt 0 ]]; then
                success "✓ Found $script_count executable scripts"
            fi
        fi
        
        # Check sensitive file permissions
        if [[ -f "$ZAANET_DIR/app/.env" ]]; then
            local env_perms=$(stat -c '%a' "$ZAANET_DIR/app/.env" 2>/dev/null)
            if [[ "$env_perms" == "600" ]]; then
                success "✓ Environment file properly secured"
            else
                warning "Environment file permissions: $env_perms (should be 600)"
            fi
        fi
    }
    
    verify_permissions
    
    success "✅ Permissions configured successfully"
}
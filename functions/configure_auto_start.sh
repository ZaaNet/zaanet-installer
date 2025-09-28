#!/bin/bash
# functions/configure_auto_start.sh
# Configure auto-start behavior for ZaaNet services

configure_auto_start() {
    log "🚀 Configuring auto-start behavior..."
    
    # =============================================================================
    # VALIDATE SERVICES EXIST
    # =============================================================================
    
    validate_services() {
        log "Validating systemd services..."
        
        local services=("zaanet-manager.service" "zaanet.service")
        local missing_services=()
        
        for service in "${services[@]}"; do
            if [[ -f "/etc/systemd/system/$service" ]]; then
                log "✓ Found: $service"
            else
                missing_services+=("$service")
                error "Missing service file: $service"
            fi
        done
        
        if [[ ${#missing_services[@]} -gt 0 ]]; then
            error "Cannot configure auto-start - missing services: ${missing_services[*]}"
        fi
    }
    
    # =============================================================================
    # CONFIGURE AUTO-START
    # =============================================================================
    
    if [[ "$AUTO_START" =~ ^[Yy] ]]; then
        log "Enabling auto-start on boot..."
        
        validate_services
        
        # Enable services
        if systemctl enable zaanet-manager; then
            success "✓ zaanet-manager enabled for auto-start"
        else
            error "Failed to enable zaanet-manager service"
        fi
        
        if systemctl enable zaanet; then
            success "✓ zaanet enabled for auto-start"
        else
            error "Failed to enable zaanet service"
        fi
        
        # Verify services are enabled
        if systemctl is-enabled --quiet zaanet-manager && systemctl is-enabled --quiet zaanet; then
            success "✅ ZaaNet will start automatically on boot"
        else
            warning "Auto-start may not be properly configured"
        fi
        
    else
        log "Auto-start disabled by user choice"
        
        # Ensure services are disabled if they exist
        if [[ -f "/etc/systemd/system/zaanet-manager.service" ]]; then
            systemctl disable zaanet-manager 2>/dev/null || true
        fi
        
        if [[ -f "/etc/systemd/system/zaanet.service" ]]; then
            systemctl disable zaanet 2>/dev/null || true
        fi
        
        log "Services will require manual start: sudo systemctl start zaanet-manager"
    fi
}
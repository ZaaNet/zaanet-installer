#!/bin/bash
# functions/create_system_user.sh
# Create dedicated system user for ZaaNet

create_system_user() {
    log "👤 Creating ZaaNet system user..."
    
    # Check if user already exists
    if id "$ZAANET_USER" >/dev/null 2>&1; then
        log "User '$ZAANET_USER' already exists"
        return 0
    fi
    
    # Create system user
    useradd --system \
            --home-dir "$ZAANET_DIR" \
            --create-home \
            --shell /bin/false \
            --comment "ZaaNet Captive Portal Service" \
            "$ZAANET_USER"
    
    # Verify user creation
    if id "$ZAANET_USER" >/dev/null 2>&1; then
        success "✓ Created system user: $ZAANET_USER"
    else
        error "Failed to create user: $ZAANET_USER"
    fi
    
    # Set proper ownership
    chown -R "$ZAANET_USER:$ZAANET_USER" "$ZAANET_DIR"
    
    success "✅ System user created successfully"
}
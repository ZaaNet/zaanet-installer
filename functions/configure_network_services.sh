#!/bin/bash
# functions/configure_network_services.sh
# Configure hostapd and dnsmasq for captive portal

configure_network_services() {
    log "⚙️ Configuring network services..."
    
    # =============================================================================
    # BACKUP EXISTING CONFIGURATIONS
    # =============================================================================
    
    backup_configs() {
        log "Backing up existing configurations..."
        
        local backup_dir="$ZAANET_DIR/backups/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        [[ -f /etc/hostapd/hostapd.conf ]] && cp /etc/hostapd/hostapd.conf "$backup_dir/"
        [[ -f /etc/dnsmasq.conf ]] && cp /etc/dnsmasq.conf "$backup_dir/"
        
        log "✓ Configurations backed up to: $backup_dir"
    }
    
    # =============================================================================
    # DISABLE CONFLICTING SERVICES
    # =============================================================================
    
    disable_conflicts() {
        log "Disabling conflicting network services..."
        
        # Stop and disable NetworkManager on wireless interface
        if systemctl is-active --quiet NetworkManager 2>/dev/null; then
            log "Disabling NetworkManager management of $WIRELESS_INTERFACE..."
            nmcli device set "$WIRELESS_INTERFACE" managed no 2>/dev/null || true
            nmcli device disconnect "$WIRELESS_INTERFACE" 2>/dev/null || true
        fi
        
        # Stop wpa_supplicant on wireless interface
        systemctl stop wpa_supplicant@"$WIRELESS_INTERFACE" 2>/dev/null || true
        systemctl disable wpa_supplicant@"$WIRELESS_INTERFACE" 2>/dev/null || true
        
        # Kill any remaining processes that might interfere
        pkill -f "wpa_supplicant.*$WIRELESS_INTERFACE" 2>/dev/null || true
        pkill -f "dhclient.*$WIRELESS_INTERFACE" 2>/dev/null || true
        
        # Wait for interface to settle
        sleep 2
        
        success "Conflicting services disabled"
    }
    
    # =============================================================================
    # CONFIGURE HOSTAPD
    # =============================================================================
    
    configure_hostapd() {
        log "Configuring hostapd for $WIRELESS_INTERFACE..."
        
        mkdir -p /etc/hostapd
        
        cat > /etc/hostapd/hostapd.conf <<EOF
# ZaaNet Hostapd Configuration - Auto-generated
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

interface=$WIRELESS_INTERFACE
EOF

        # Add driver line conditionally
        if [[ "$IS_RASPBERRY_PI" == "true" ]]; then
            echo "# driver=nl80211  # Commented out for Raspberry Pi compatibility" >> /etc/hostapd/hostapd.conf
        else
            echo "driver=nl80211" >> /etc/hostapd/hostapd.conf
        fi

        cat >> /etc/hostapd/hostapd.conf <<EOF
ssid=$WIFI_SSID

# Basic Wi-Fi settings
hw_mode=g
channel=6
wmm_enabled=1
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0

# No encryption (open network for captive portal)
wpa=0

# Country code and regulatory
country_code=GH

# Minimal settings for maximum compatibility
max_num_sta=30

# Logging
logger_syslog=-1
logger_stdout=-1

# Auto-generated for:
# Wireless Interface: $WIRELESS_INTERFACE
# Portal IP: $PORTAL_IP
# SSID: $WIFI_SSID
EOF
        
        # Configure hostapd daemon
        if [[ -f /etc/default/hostapd ]]; then
            sed -i 's/^#*DAEMON_CONF=.*/DAEMON_CONF="\/etc\/hostapd\/hostapd.conf"/' /etc/default/hostapd
        else
            echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' > /etc/default/hostapd
        fi
        
        success "✓ hostapd configured"
    }
    
    # =============================================================================
    # CONFIGURE DNSMASQ
    # =============================================================================
    
    configure_dnsmasq() {
        log "Configuring dnsmasq..."
        
        # Backup original if exists
        [[ -f /etc/dnsmasq.conf ]] && cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
        
        cat > /etc/dnsmasq.conf <<EOF
# ZaaNet Dnsmasq Configuration - Auto-generated
# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')

# Interface binding
interface=$WIRELESS_INTERFACE
bind-interfaces
except-interface=lo

# Don't provide DHCP on ethernet
no-dhcp-interface=$ETHERNET_INTERFACE

# DHCP configuration
dhcp-range=$DHCP_START,$DHCP_END,255.255.255.0,12h
dhcp-option=3,$PORTAL_IP
dhcp-option=6,$PORTAL_IP
dhcp-authoritative

# DNS configuration
domain-needed
bogus-priv
no-resolv
server=$DNS_SERVER
expand-hosts

# Common connectivity check domains
address=/connectivitycheck.gstatic.com/$PORTAL_IP
address=/clients3.google.com/$PORTAL_IP
address=/captive.apple.com/$PORTAL_IP
address=/www.msftconnecttest.com/$PORTAL_IP

# Logging
log-queries
log-dhcp

# Configuration summary:
# Portal IP: $PORTAL_IP
# DHCP Range: $DHCP_START - $DHCP_END
# Wireless Interface: $WIRELESS_INTERFACE
# Internet Interface: $ETHERNET_INTERFACE
EOF
        
        # Create dhcp lease directory
        mkdir -p /var/lib/dhcp
        
        success "✓ dnsmasq configured"
    }
    
    # =============================================================================
    # VERIFY CONFIGURATIONS
    # =============================================================================
    
    verify_configs() {
        log "Verifying configurations..."
        
        # Check hostapd config file exists and has basic syntax
        if [[ -f /etc/hostapd/hostapd.conf ]] && grep -q "interface=" /etc/hostapd/hostapd.conf; then
            success "✓ hostapd configuration file created"
        else
            error "hostapd configuration file missing or invalid"
        fi
        
        # Check dnsmasq config file exists and has basic syntax
        if [[ -f /etc/dnsmasq.conf ]] && grep -q "interface=" /etc/dnsmasq.conf; then
            success "✓ dnsmasq configuration file created"
        else
            error "dnsmasq configuration file missing or invalid"
        fi
        
        log "Configuration verification completed (runtime testing skipped)"
    }
    
    # =============================================================================
    # RUN CONFIGURATION
    # =============================================================================
    
    backup_configs
    disable_conflicts
    configure_hostapd
    configure_dnsmasq
    verify_configs
    
    success "✅ Network services configured"
}

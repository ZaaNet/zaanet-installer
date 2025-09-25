create_zaanet_scripts() {    
    # Create the network switcher script
    cat > "$ZAANET_DIR/scripts/zaanet-switcher.sh" << EOF
#!/bin/bash
# ZaaNet Network Mode Switcher - Auto-generated
# Switches between normal internet mode and ZaaNet captive portal mode

# Configuration - Auto-detected
INTERFACE="$WIRELESS_INTERFACE"
IP_ADDRESS="$PORTAL_IP/24"
DNS_SERVER="$DNS_SERVER"
PORTAL_PORT="$PORTAL_PORT"  # Use environment variable
FIREWALL_SCRIPT="$ZAANET_DIR/scripts/zaanet-firewall.sh"
LOG_FILE="/var/log/zaanet.log"

# Check for root privileges
if [[ \$EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo"
  exit 1
fi

# Logging function
log() {
  echo "\$(date -u '+%Y-%m-%d %H:%M:%S') [ZaaNet] \$1" | tee -a "\$LOG_FILE"
}

# FUNCTION - NORMAL INTERNET MODE
to_normal_mode() {
  log "Switching to normal internet mode..."
  
  # Stop and disable dnsmasq
  sudo systemctl stop dnsmasq
  sudo systemctl disable dnsmasq --quiet
  
  # Stop and disable hostapd
  sudo systemctl stop hostapd
  sudo systemctl disable hostapd --quiet
  sudo systemctl mask hostapd
  
  # Clear firewall rules
  log "Clearing ZaaNet firewall rules..."
  sudo iptables -F ZAANET_AUTH_USERS 2>/dev/null || true
  sudo iptables -X ZAANET_AUTH_USERS 2>/dev/null || true
  sudo iptables -F ZAANET_BLOCKED 2>/dev/null || true
  sudo iptables -X ZAANET_BLOCKED 2>/dev/null || true
  
  # Remove ZaaNet IP address
  sudo ip addr del "\$IP_ADDRESS" dev "\$INTERFACE" 2>/dev/null || true
  
  # Re-enable NetworkManager management
  log "Re-enabling NetworkManager management..."
  nmcli dev set "\$INTERFACE" managed yes 2>/dev/null || log "Could not re-enable NetworkManager management"
  
  # Restore WiFi functionality
  sudo ip link set \$INTERFACE up
  sudo systemctl restart NetworkManager 2>/dev/null || true

  log "Normal internet mode restored."
}

# FUNCTION - ZAANET MODE
to_zaanet_mode() {
  
  # Check if firewall script exists
  if [[ ! -x "\$FIREWALL_SCRIPT" ]]; then
    exit 1
  fi
  
  trap 'log "Error occurred, reverting to normal mode..."; to_normal_mode; exit 1' ERR
  
  # Disable NetworkManager management of wireless interface
  log "Preparing wireless interface..."
  nmcli device disconnect "\$INTERFACE" 2>/dev/null || log "Interface not connected to NetworkManager"
  nmcli dev set "\$INTERFACE" managed no 2>/dev/null || log "Could not disable NetworkManager management"
  
  # Brief pause to let NetworkManager release the interface
  sleep 2
  
  # Enable and start hostapd
  sudo systemctl unmask hostapd
  sudo systemctl enable hostapd --quiet
  if ! sudo systemctl start hostapd; then
    log "Failed to start hostapd. Check: systemctl status hostapd"
    exit 1
  fi
  
  # Validate and configure interface
  if ! ip link show "\$INTERFACE" >/dev/null 2>&1; then
    log "Interface \$INTERFACE does not exist"
    exit 1
  fi
  
  # Bring up interface and assign IP
  sudo ip link set "\$INTERFACE" down
  sleep 2
  sudo ip link set "\$INTERFACE" up
  
  # Remove existing IP and assign portal IP
  sudo ip addr flush dev "\$INTERFACE"
  sudo ip addr add "\$IP_ADDRESS" dev "\$INTERFACE"
  
  # Enable and start dnsmasq
  sudo systemctl enable dnsmasq --quiet
  if ! sudo systemctl restart dnsmasq; then
    log "Failed to start dnsmasq. Check: systemctl status dnsmasq"
    exit 1
  fi
  
  # Apply firewall rules
  log "Applying ZaaNet firewall rules..."
  if ! sudo "\$FIREWALL_SCRIPT"; then
    log "Failed to apply firewall rules"
    exit 1
  fi
}

# FUNCTION - STATUS CHECK
show_status() {
  echo "ZaaNet Status:"
  echo "   Wi-Fi SSID: $WIFI_SSID"
  echo "   Portal IP: $PORTAL_IP"
  echo "   Interface: \$INTERFACE"
  echo ""
  
  if systemctl is-active --quiet hostapd && systemctl is-active --quiet dnsmasq; then
    echo "Mode: ZaaNet Captive Portal Active"
    ip addr show "\$INTERFACE" | grep inet || echo "No IP assigned"
  else
    echo "Mode: Normal Internet Mode"
  fi
  
  echo ""
  echo "Services:"
  echo "  📡 hostapd: \$(systemctl is-active hostapd)"
  echo "  🌐 dnsmasq: \$(systemctl is-active dnsmasq)"
  echo "  🔧 systemd-resolved: \$(systemctl is-active systemd-resolved)"
}

# Entry Point
case "\$1" in
  --normal)
    to_normal_mode
    ;;
  --zaanet)
    to_zaanet_mode
    ;;
  --status)
    show_status
    ;;
  *)
    echo "Usage: \$0 [--normal | --zaanet | --status]"
    echo ""
    echo "Commands:"
    echo "  --zaanet   Switch to captive portal mode"
    echo "  --normal   Switch to normal internet mode"
    echo "  --status   Show current status"
    exit 1
    ;;
esac
EOF

# Create the firewall script
cat > "$ZAANET_DIR/scripts/zaanet-firewall.sh" << EOF
#!/bin/bash

# ZaaNet Captive Portal - FILTER Method Setup
# Simple and clean approach using only FILTER table

set -euo pipefail

# Configuration
LAN_IF="$WIRELESS_INTERFACE"
WAN_IF="$ETHERNET_INTERFACE"
PORTAL_IP="$PORTAL_IP"
LAN_SUBNET="192.168.100.0/24"

LOG_FILE="/var/log/zaanet-firewall.log"

log() {
  local message="[\$(date '+%Y-%m-%d %H:%M:%S')] \$1"
  echo "\$message"
  echo "\$message" >> "\$LOG_FILE" 2>/dev/null || true
}

# Validate environment
validate_environment() {
  if [[ \$EUID -ne 0 ]]; then
    log "This script must be run as root"
    exit 1
  fi

  for tool in iptables ip; do
    if ! command -v "\$tool" >/dev/null 2>&1; then
      log "Required tool not found: \$tool"
      exit 1
    fi
  done

  if ! ip link show "\$LAN_IF" >/dev/null 2>&1; then
    log "LAN interface \$LAN_IF not found"
    ip link show | grep -E "^[0-9]+:" | awk '{print \$2}' | sed 's/:\$//'
    exit 1
  fi

  if ! ip link show "\$WAN_IF" >/dev/null 2>&1; then
    log "WAN interface \$WAN_IF not found"
    ip link show | grep -E "^[0-9]+:" | awk '{print \$2}' | sed 's/:\$//'
    exit 1
  fi

  log "Environment validation passed"
}

enable_ip_forwarding() {
  echo 1 > /proc/sys/net/ipv4/ip_forward
  if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
  fi
  log "IP forwarding enabled and made persistent"
}

cleanup_rules() {
  iptables -F
  iptables -t nat -F
  iptables -t mangle -F
  iptables -X AUTHENTICATED_USERS 2>/dev/null || true
  iptables -t nat -X 2>/dev/null || true
  iptables -t mangle -X 2>/dev/null || true
}

setup_policies() {
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -P FORWARD DROP
}

setup_nat() {
  iptables -t nat -A POSTROUTING -o "\$WAN_IF" -j MASQUERADE
}

setup_basic_rules() {
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  iptables -A FORWARD -i "\$LAN_IF" -d "\$PORTAL_IP" -j ACCEPT
  iptables -A INPUT -i "\$LAN_IF" -d "\$PORTAL_IP" -j ACCEPT
  iptables -A INPUT -i "\$LAN_IF" -p udp --dport 53 -j ACCEPT
  iptables -A INPUT -i "\$LAN_IF" -p tcp --dport 53 -j ACCEPT
  iptables -A INPUT -i "\$LAN_IF" -p tcp --dport 80 -j ACCEPT
  iptables -A INPUT -i "\$LAN_IF" -p tcp --dport 443 -j ACCEPT
}

create_authenticated_chain() {
  iptables -N ZAANET_AUTH_USERS 2>/dev/null || echo "ZAANET_AUTH_USERS chain already exists"

  # Avoid duplicate insertion
  if ! iptables -C FORWARD -i "\$LAN_IF" -j ZAANET_AUTH_USERS 2>/dev/null; then
    iptables -I FORWARD 2 -i "\$LAN_IF" -j ZAANET_AUTH_USERS
  else
    log "ℹZAANET_AUTH_USERS already linked to FORWARD"
  fi
}

create_blocked_chain() {
  iptables -N ZAANET_BLOCKED 2>/dev/null || echo "ZAANET_BLOCKED chain already exists"

  # Avoid duplicate insertion
  if ! iptables -C FORWARD -j ZAANET_BLOCKED 2>/dev/null; then
    iptables -I FORWARD -j ZAANET_BLOCKED
  else
    log "ZAANET_BLOCKED already linked to FORWARD"
  fi
}

restore_authenticated_ips() {
  local restore_script="/opt/zaanet/scripts/restore_active_ips.sh"
  if [[ -x "\$restore_script" ]]; then
    bash "\$restore_script" && log "Active IPs restored" || log "Failed to restore active IPs"
  else
    log "No restore script found, starting with clean authenticated users list"
  fi
}

main() {
  local backup_file="/tmp/iptables-backup-\$(date +%Y%m%d-%H%M%S).rules"
  iptables-save > "\$backup_file" 2>/dev/null || true

  validate_environment
  enable_ip_forwarding
  cleanup_rules
  setup_policies
  setup_nat
  setup_basic_rules
  create_authenticated_chain
  create_blocked_chain
  restore_authenticated_ips
  test_configuration
  show_summary
}

trap 'log "Script interrupted"; exit 130' INT TERM
main "\$@"
EOF

    # Make scripts executable
    chmod +x "$ZAANET_DIR/scripts"/*.sh
    
    success "Management scripts created"
}
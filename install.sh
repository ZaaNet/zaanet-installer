#!/bin/bash
# ZaaNet Captive Portal Auto-Installer
# One-command setup for Raspberry Pi 4+
# curl -sSL https://get.zaanet.xyz | sudo bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Auto-Configuration (No user input required)
ZAANET_DIR="/opt/zaanet"
ZAANET_USER="zaanet"
GITHUB_REPO="https://github.com/ZaaNet/public-release-v1.0.0.git"

# Network Configuration (Works for all installations)
WIFI_SSID="ZaaNet-Portal"
PORTAL_IP="192.168.100.1"
DHCP_START="192.168.100.100"
DHCP_END="192.168.100.200"
DNS_SERVER="8.8.8.8"
PORTAL_DOMAIN="portal.zaanet.xyz"
PORTAL_PORT="80"
MAIN_SERVER_URL="https://www.zaanet.xyz"

# Determine script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="${SCRIPT_DIR}/functions"

# Source all function files
source_functions() {
    local functions_to_load=(
        "auto_detect_interfaces.sh"
        "check_device_compatibility.sh"
        "configure_auto_start.sh"
        "configure_network_services.sh"
        "create_management_commands.sh"
        "create_system_user.sh"
        "create_systemd_services.sh"
        "create_zaanet_scripts.sh"
        "get_essential_config.sh"
        "install_dependencies.sh"
        "set_permissions.sh"
        "setup_application.sh"
        "show_completion.sh"
    )
    
    log "Loading function modules..."
    
    for func_file in "${functions_to_load[@]}"; do
        local func_path="${FUNCTIONS_DIR}/${func_file}"
        if [[ -f "$func_path" ]]; then
            # shellcheck source=/dev/null
            source "$func_path"
            log "✓ Loaded ${func_file}"
        else
            error "Function file not found: ${func_path}"
        fi
    done
    
    log "All function modules loaded successfully"
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║  ███████╗ █████╗  █████╗ ███╗   ██╗███████╗████████╗        ║
║  ╚══███╔╝██╔══██╗██╔══██╗████╗  ██║██╔════╝╚══██╔══╝        ║
║    ███╔╝ ███████║███████║██╔██╗ ██║█████╗     ██║           ║
║   ███╔╝  ██╔══██║██╔══██║██║╚██╗██║██╔══╝     ██║           ║
║  ███████╗██║  ██║██║  ██║██║ ╚████║███████╗   ██║           ║
║  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝           ║
║                                                              ║
║             🚀 ZaaNet Auto-Installer v1.0.0 🚀              ║
║           Zero-Configuration Captive Portal Setup           ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}🎯 Automatic Setup for Raspberry Pi 4+${NC}"
    echo "   • No manual configuration required"
    echo "   • Complete captive portal in minutes"
    echo "   • Ready for production use"
    echo ""
}

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This installer must be run as root. Please use: curl -sSL https://get.zaanet.xyz | sudo bash"
    fi
}

# Verify all required function files exist
verify_function_files() {
    log "Verifying function files..."
    
    if [[ ! -d "$FUNCTIONS_DIR" ]]; then
        error "Functions directory not found: $FUNCTIONS_DIR"
    fi
    
    local required_functions=(
        "auto_detect_interfaces.sh"
        "check_device_compatibility.sh"
        "configure_auto_start.sh"
        "configure_network_services.sh"
        "create_management_commands.sh"
        "create_system_user.sh"
        "create_systemd_services.sh"
        "create_zaanet_scripts.sh"
        "get_essential_config.sh"
        "install_dependencies.sh"
        "set_permissions.sh"
        "setup_application.sh"
        "show_completion.sh"
    )
    
    local missing_functions=()
    
    for func_file in "${required_functions[@]}"; do
        if [[ ! -f "${FUNCTIONS_DIR}/${func_file}" ]]; then
            missing_functions+=("$func_file")
        fi
    done
    
    if [[ ${#missing_functions[@]} -gt 0 ]]; then
        error "Missing required function files: ${missing_functions[*]}"
    fi
    
    success "All required function files found"
}

# Main installation orchestrator
main() {
    show_banner
    check_root
    
    # Verify and load all function files
    verify_function_files
    source_functions
    
    # Now call the functions (these are defined in the sourced files)
    check_device_compatibility
    auto_detect_interfaces
    get_essential_config
    
    echo ""
    echo -e "${CYAN}🚀 Starting automated installation...${NC}"
    echo ""
    
    install_dependencies
    create_system_user
    setup_application
    configure_network_services
    create_zaanet_scripts
    create_systemd_services
    create_management_commands
    set_permissions
    configure_auto_start
    
    show_completion
    
    log "🎉 ZaaNet auto-installation completed successfully!"
}

# Global error handling
trap 'error "Installation failed at line $LINENO. Check /var/log/zaanet-install.log for details."' ERR

# Create install log
exec > >(tee -a /var/log/zaanet-install.log)
exec 2>&1

# Start installation
main "$@"
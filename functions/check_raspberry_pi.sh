check_raspberry_pi() {
    echo "Checking device compatibility..."
    
    if [[ ! -f /proc/device-tree/model ]]; then
        error "Cannot detect device model. This installer is designed for Raspberry Pi 4+"
    fi
    
    local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0')
    echo "   📱 Detected: $model"
    
    if [[ "$model" =~ "Raspberry Pi" ]]; then
        # Extract Pi version number
        local pi_version=$(echo "$model" | grep -o 'Pi [0-9]' | grep -o '[0-9]')
        if [[ -n "$pi_version" && "$pi_version" -ge 4 ]]; then
            success "Raspberry Pi $pi_version detected - Compatible!"
        else
            warning "Raspberry Pi $pi_version detected. Pi 4+ recommended for best performance."
            read -p "Continue anyway? [y/N]: " CONTINUE
            if [[ ! "$CONTINUE" =~ ^[Yy] ]]; then
                echo "Installation cancelled."
                exit 0
            fi
        fi
    else
        warning "Non-Raspberry Pi device detected. This installer is optimized for Pi 4+."
        read -p "Continue anyway? [y/N]: " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy] ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
}
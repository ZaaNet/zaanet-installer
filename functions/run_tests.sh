run_tests() {
    echo "🧪 Running system tests..."
    
    echo "DEBUG: Starting network interface tests..."
    if ip link show "$WIRELESS_INTERFACE" >/dev/null 2>&1; then
        success "✅ Wireless interface ($WIRELESS_INTERFACE) ready"
    else
        warning "❌ Wireless interface ($WIRELESS_INTERFACE) not found"
    fi
    echo "DEBUG: Wireless test completed"
    
    if ip link show "$ETHERNET_INTERFACE" >/dev/null 2>&1; then
        success "✅ Ethernet interface ($ETHERNET_INTERFACE) ready"
    else
        warning "⚠️ Ethernet interface ($ETHERNET_INTERFACE) not found"
    fi
    echo "DEBUG: Ethernet test completed"
    
    echo "DEBUG: About to test hostapd..."
    if timeout 15 bash -c 'hostapd -t /etc/hostapd/hostapd.conf' >/dev/null 2>&1; then
        success "✅ Hostapd configuration valid"
    else
        warning "⚠️ Hostapd configuration test failed/timeout"
    fi
    echo "DEBUG: Hostapd test completed"
    
    echo "DEBUG: About to test dnsmasq..."
    if timeout 15 bash -c 'dnsmasq --test' >/dev/null 2>&1; then
        success "✅ Dnsmasq configuration valid"
    else
        warning "⚠️ Dnsmasq configuration test failed/timeout"
    fi
    echo "DEBUG: Dnsmasq test completed"
    
    echo "DEBUG: Testing remaining components..."
    # ... rest of tests
    success "✅ All tests completed"
}
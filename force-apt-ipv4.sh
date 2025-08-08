#!/bin/bash
# ==========================================
# Force APT to use IPv4 instead of IPv6 (Interactive Version)
# Author: Aria Jahangiri Far
# ==========================================

# APT config file path
APT_CONF_FILE="/etc/apt/apt.conf.d/99force-ipv4"

# Enable ForceIPv4
enable_ipv4() {
    echo "Enabling ForceIPv4 for APT..."
    echo 'Acquire::ForceIPv4 "true";' | sudo tee "$APT_CONF_FILE" > /dev/null
    echo "✅ ForceIPv4 enabled. APT will now always use IPv4."
}

# Disable ForceIPv4
disable_ipv4() {
    echo "Disabling ForceIPv4 for APT..."
    sudo rm -f "$APT_CONF_FILE"
    echo "❌ ForceIPv4 disabled. APT will use default settings."
}

# Show current status
echo "--------------------------------------"
if [[ -f "$APT_CONF_FILE" ]]; then
    echo "📌 Current Status: ENABLED"
else
    echo "📌 Current Status: DISABLED"
fi
echo "--------------------------------------"
echo "Select an option:"
echo "1) Enable ForceIPv4"
echo "2) Disable ForceIPv4"
echo "3) Exit"

read -p "Enter your choice [1-3]: " choice

case "$choice" in
    1) enable_ipv4 ;;
    2) disable_ipv4 ;;
    3) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid choice!"; exit 1 ;;
esac

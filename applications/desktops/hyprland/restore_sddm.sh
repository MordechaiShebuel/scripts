


#!/bin/bash

set -e  # Exit on error

echo "=== Restoring SDDM ==="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Disable greetd
echo "[*] Disabling greetd service..."
if [[ -L /var/service/greetd ]]; then
    rm /var/service/greetd
else
    echo "[!] greetd service not found"
fi

# Enable SDDM
echo "[*] Enabling SDDM service..."
if [[ ! -L /var/service/sddm ]]; then
    ln -s /etc/sv/sddm /var/service/
else
    echo "[!] SDDM service already enabled"
fi

# Optional: remove noctalia-greeter and greetd packages
read -p "Remove greetd and noctalia-greeter packages? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[*] Removing packages..."
    xbps-remove -R greetd noctalia-greeter
fi

echo ""
echo "=== Restore complete ==="
echo "Reboot to apply changes: sudo reboot"

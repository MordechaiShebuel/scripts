#!/usr/bin/env bash
# TODO: BUG: there is something amiss with this setup, SonicDE vanishes panels and icons after reboot.

# Add repository key
# sudo wget -O /var/db/xbps/keys/00:ca:42:57:c9:c0:9a:ec:94:b4:7d:97:e5:a9:aa:1e.plist https://github.com/xlibre-void/xlibre/raw/refs/heads/main/repo-keys/x86_64/00:ca:42:57:c9:c0:9a:ec:94:b4:7d:97:e5:a9:aa:1e.plist
# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

# Add repository to sources
echo "Adding repository..."
sudo mkdir -p /etc/xbps.d
printf "repository=https://github.com/sonicde-void/sonicde-void/releases/latest/download/\n" | sudo tee /etc/xbps.d/99-repository-sonicde.conf

# Synchronize the repository
echo "Synchronizing the repository..."
sudo xbps-install -S

# Install Xlibre
echo "Installing SonicDE..."
sudo xbps-install -Su sonicde-meta

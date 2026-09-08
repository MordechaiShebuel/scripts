#!/usr/bin/env bash

# Add repository key
echo "Adding repository key..."
sudo wget -O /var/db/xbps/keys/00:ca:42:57:c9:c0:9a:ec:94:b4:7d:97:e5:a9:aa:1e.plist https://github.com/xlibre-void/xlibre/raw/refs/heads/main/repo-keys/x86_64/00:ca:42:57:c9:c0:9a:ec:94:b4:7d:97:e5:a9:aa:1e.plist

# Add repository to sources
echo "Adding repository to sources..."
sudo mkdir -p /etc/xbps.d
printf "repository=https://github.com/xlibre-void/xlibre/releases/latest/download/" | sudo tee /etc/xbps.d/99-repository-xlibre.conf

# Synchronize the repository
echo "Synchronizing the repository..."
sudo xbps-install -S

# Install Xlibre
echo "Installing Xlibre..."
sudo xbps-install -Su xlibre

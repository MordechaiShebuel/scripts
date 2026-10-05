#!/bin/bash

# Install lightdm and a greeter (pick one)
# sudo xbps-install -S lightdm lightdm-gtk-greeter

# Or for a GTK3 greeter with better theming
sudo xbps-install -S lightdm lightdm-webkit2-greeter


# Download and extract theme
cd /tmp
wget https://github.com/Litarvan/lightdm-webkit-theme-litarvan/releases/download/v3.2.0/lightdm-webkit-theme-litarvan-3.2.0.tar.gz
sudo mkdir -p /usr/share/lightdm-webkit/themes/litarvan
sudo tar xzf lightdm-webkit-theme-litarvan-3.2.0.tar.gz -C /usr/share/lightdm-webkit/themes/litarvan --strip-components=1

# Configure
sudo tee /etc/lightdm/lightdm-webkit2-greeter.conf > /dev/null << 'EOF'
[webkit2-greeter]
theme = litarvan
EOF

# Disable sddm
sudo ln -sf /dev/null /etc/sv/sddm
# Disable SDDM if running
if [[ -L /var/service/sddm ]]; then
    echo "[*] Disabling SDDM..."
    sudo rm /var/service/sddm
fi

# Enable lightdm
sudo ln -sf /etc/sv/lightdm /var/service/

# Reboot or restart
sudo sv restart lightdm

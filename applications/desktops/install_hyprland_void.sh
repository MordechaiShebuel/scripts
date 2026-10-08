#!/bin/bash
# Hyprland on Void?! (Inspired by DHH and Hyprland)
# HELL YES!
# Backup current .zshrc
# VERSION 0.5.0 - Official Beta
# General cleanup after installing it on two other computers

# Current Feature Requests:\
# 1. Needs to have per user setup copies, for multi-user systems
#   Implemented, need to test - seems to work
# 2. Give user more choice! Maybe they don't want Noctalia, or want different dock?
# 3. Separate out hypr settings, look at Omacom as an example. This way making a change won't override all settings'
#   Implemented, need to test - This also seems to be working
#   Some of these are very system specific like Monitor

# CURRENT BUGS:
# Steam Big Picture is wonky, this is a known issue with Hyprland
#  Trying some window rule improvements to see if I can resolve

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

echo "Updating System before beginning"
# Update repos and system first
sudo xbps-install -Syu

TERMINAL="rio" # can be manually set

# Setup hyprland repo if necessary
if ! {
    test -f /etc/xbps.d/00-repository-main.conf
}; then
    echo "hyprland installer: setting up repo."
    echo "1i repository=https://mirror.black-hole.dev/x86_64/" |
        sudo tee /etc/xbps.d/00-repository-main.conf >/dev/null
    sudo xbps-install -S
fi

# Install Hyprland and dependencies
sudo xbps-install -S \
     hyprland hyprland-guiutils \
     kvantum wl-clipboard wlr-randr \
     xdg-desktop-portal-hyprland xdg-desktop-portal \
     xdg-desktop-portal-gtk $TERMINAL Thunar \
     brightnessctl playerctl pamixer \
     blueman gnome-keyring papirus-icon-theme \
     qt6ct hyprland-qt-support \
     xorg-server-xwayland xorg-fonts \
     noctalia ttf-jetbrains-mono font-awesome

# update user configs
./hyperland/./update_user.sh

echo "Apply fixes for QT theming"
hyprland/./fix_qt_theming.sh

echo "Fix GTK themes"
sudo xbps-install -S nwg-look gnome-themes-extra

echo "Setting up new greeter"
sudo hyprland/./setup_greetd_greeter.sh

echo "You'll need to run nwg-look to set this to a dark theme"

# Setup runit services
echo "Setting up runit services..."
sudo ln -sf /etc/sv/NetworkManager /var/service/ 2>/dev/null
sudo ln -sf /etc/sv/blueman /var/service/ 2>/dev/null

# Create .xinitrc if it doesn't exist
if [[ ! -f ~/.xinitrc ]]; then
    echo "exec Hyprland" > ~/.xinitrc
fi

echo "Apply fix to dbus-session"
hyprland/./fix_dbus.sh

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

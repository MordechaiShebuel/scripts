#!/bin/bash
# Hyprland on Void?! (Inspired by DHH and Hyprland)
# HELL YES!
# Backup current .zshrc
# VERSION 0.5.4 - Official Beta
# General cleanup after installing it on two other computers
# Some more cleanup, with settings
# Changed keybind viewer to use output from LUA load. (JSON)
# Set font to Inter, much nicer looking than Noto and will allow removing that Gulag cruft
# setting up account images, included two stock images
# Trying different terminal

# Current Feature Requests:\
# 1. Needs to have per user setup copies, for multi-user systems
#   Implemented, need to test - seems to work
#   Hyprland has nasty habit of requiring full reboot.
#   Potential fix is in place
#   Added hostname detection to monitor file, so it being copied again won't kill monitor output on my devices
# 2. Give user more choice! Maybe they don't want Noctalia, or want different dock?
#   Have some of this setup in the install_hyperland_void script, needs menus and propagation
# 3. Separate out hypr settings, look at Omacom as an example. This way making a change won't override all settings'
#   Implemented, need to test - This also seems to be working
#   Some of these are very system specific like Monitor (dealt with)

# CURRENT BUGS:
# Resolved: Help screen bug introduced by changing keybind_viewer.
# Steam Big Picture is wonky, this is a known issue with Hyprland
#  Trying some window rule improvements to see if I can resolve
#  Some more attemps to resolve this in place

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

echo "Updating System before beginning"
# Update repos and system first
sudo xbps-install -Syu

# can be manually set
TERMINAL="rio"
FILE_MANAGER="nemo"
SHELL="noctalia"

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
     xdg-desktop-portal-gtk $TERMINAL $FILE_MANAGER \
     brightnessctl playerctl pamixer \
     blueman gnome-keyring papirus-icon-theme \
     qt6ct hyprland-qt-support accountsservice \
     xorg-server-xwayland xorg-fonts \
     $SHELL font-awesome \
     font-inter font-inter-variable

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
# if [[ ! -f ~/.xinitrc ]]; then
#     echo "exec Hyprland" > ~/.xinitrc
# fi

echo "Apply fix to dbus-session"
hyprland/./fix_dbus.sh

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

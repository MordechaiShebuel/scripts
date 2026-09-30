#!/bin/bash
# dwm on Devuan?! (Inspired by DHH and Hyprland and Chris Titus)
# HELL YES!
# Backup current .zshrc
# VERSION 0.0.9 - install works, loads with noctalia
# Alpha version, Dock and Panel "working" but definitely not polished or final

# TODO:
# test audio functionality
# Added functional screenshots, it wasn't working with the package list before.
# Cleaned up packages that aren't needed, still need to do more review here!
# Using Zutty

# Current Feature Requests:
# Need to get shortcuts matching Hyprland setup
# Needs idle/lock/logout functionality similar to Hyprland setup
# Need to confirm QT theme

# CURRENT BUGS:
# 1. no wallpaper util, the wallpaper is stuck on the SDDM login
#   - DONE, need to reboot and see if it works
# 2. I don't see the system tray on the top panel, just the clock in the center.|
#   - IP, some minor issues it is rendering
# 3. the dock isn't centered, it's left aligned with a black bar
#   - IP, centered, but not auto-hiding
# 4. xfce-polkit had an unclear pop up warning, not sure it's actually running, can I test this?
# 5. Not hearing sound, need to test later

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

echo "Updating System before beginning"
# Update repos and system first
sudo apt update && sudo apt upgrade

# First backup shell config
../../bin/./backup_shell_config.sh

# Install WM and dependencies
sudo apt install \
     i3 i3wm i3status polybar rofi plank xfce-polkit \
     xdg-desktop-portal xdg-desktop-portal-gtk zutty thunar \
     brightnessctl playerctl pamixer picom feh \
     blueman gnome-keyring papirus-icon-theme \
     qt6ct fonts-xfree86-nonfree scrot \
     fonts-jetbrains-mono fonts-font-awesome

# Make directory for screenshots:
mkdir -P "$HOME/Pictures/screenshots"

# Create wallpaper directory
mkdir -P "$HOME/Pictures/wallpapers"
i3/./get_stock_wp.sh

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/i3
mkdir -p ~/.config/polybar
mkdir -p ~/.config/picom

# Copy polybar settings to home
cp i3/polybar/polybar-config.ini "$HOME/polybar/config.ini"

# copy compositor settings to home
cp i3/picom.conf "$HOME/.config/picom/picom.conf"

# TODO: Need to create
# Copy shortcut helper
tee "$HOME/.config/i3/show-shortcuts.sh" < dwm/show-shortcuts.sh

# Todo: need to wrap this and function below in safety guard not to create duplicate entries
cat >> ~/.zshrc <<'EOF'cat >> ~/.zshrc <<'EOF'
export EDITOR=nano
export MOZ_ENABLE_WAYLAND=0
EOF

# TODO: this needs to check to see if these are already added, probably should be encapsulated in it's own script
cat >> ~/.zshrc <<'EOF'
# QT Platform and Theme Configuration
export QT_QPA_PLATFORMTHEME=kvantum
export QT_QPA_PLATFORM=wayland
export QT_STYLE_OVERRIDE=kvantum
export QT_AUTO_SCREEN_SCALE_FACTOR=1

# QT5 Support (if still using QT5 apps)
export QT5_QPA_PLATFORMTHEME=kvantum

# Wayland-specific (important for Hyprland)
export QT_WAYLAND_DISABLE_WINDOWDECORATION=0
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/qt6/plugins
EOF

echo "Installation complete!"
echo "You can now start i3 by running 'startx' or configure your display manager."

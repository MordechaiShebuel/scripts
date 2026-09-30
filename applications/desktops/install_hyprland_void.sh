#!/bin/bash
# Hyprland on Void?! (Inspired by DHH and Hyprland)
# HELL YES!
# Backup current .zshrc
# VERSION 0.4.91 - install works, loads with noctalia
# Beta version worthy, function desktop, has dock, sound and help screen.
# Added functional screenshots, it wasn't working with the package list before.
# Cleaned up packages that aren't needed, still need to do more review here!
# Switched from soon to be obsolete .conf to .lua
# Got DBUS properly working, system tray bug now fixed
# refixed audio after converting to LUA, missed that the LLM cut that out of my script.
# Switched launcher from Wofi to Walker. Walker by default looks better, and was easy to theme.
# Using Noctalia launcher, polkit, and dock. Massive clean up in startup script, and theme uniformity
# Switched terminal emulator from alacritty to ghostty, allows for goal of emulating MacOS keybindings
# Switched screenshots to use Noctalia's built-in toolchain
# Fixed bug I created by switching from Alacritty to Ghostty, help screen not displaying

# Current Feature Requests:
# Compare Omarchy shortcuts to my own, take what seems like it could work
# Add screenshots to help screen
# Finish mapping relevant MacOS shortcuts to key bindings
# Make an actual app for help instead of just a terminal

# CURRENT BUGS:
# Help screen needs updated with latest shortcuts
# IP: Occasionaly activating keybind (mac style overlays) results in a looping affect in key presses
#   Potentially fixed, need to do some more testing
# DONE: SUPER+SPACE had two actions assigned, was wondering why it wasn't doing what I expected, thought I misunderstood what "floating" meant.
#   - Fixed
# GHOSTTY is having strange rendering issues with ssh.

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

echo "Updating System before beginning"
# Update repos and system first
sudo xbps-install -Syu

# First backup shell config
../../bin/./backup_shell_config.sh

# Change background?
hyprland/./get_safe_wp.sh

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
     xdg-desktop-portal-gtk ghostty Thunar \
     brightnessctl playerctl pamixer \
     blueman gnome-keyring papirus-icon-theme \
     qt6ct hyprland-qt-support \
     xorg-server-xwayland xorg-fonts \
     noctalia ttf-jetbrains-mono font-awesome

# Make directory for screenshots:
mkdir -P "$HOME/Pictures/screenshots"

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/hypr

# Copy shortcut helper
tee "$HOME/.config/hypr/show-shortcuts.sh" < hyprland/show-shortcuts.sh

# Create/update Hyprland config
tee "$HOME/.config/hypr/hyprland.lua" < hyprland/hyprland.lua

# Create/update hyprlock settings
tee "$HOME/.config/hypr/hyprlock.lua" < hyprlock.lua

# Create/update ghostty settings
tee "$HOME/.config/ghostty/config" < hyprland/ghostty-config

# Create/update Noctalia Config
tee "$HOME/.config/noctalia/noctalia-config.toml" < hyprland/noctalia-config.toml

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

echo "Apply fixes for QT theming"
hyprland/./fix_qt_theming.sh

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

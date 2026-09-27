#!/bin/bash
# Hyprland on Void?! (Inspired by DHH and Hyprland)
# HELL YES!
# Backup current .zshrc
# VERSION 0.40 - install works, loads with noctalia
# Beta version worthy, function desktop, has dock, sound and help screen.
# IP: Theming is not consistent, QT apps are still in light mode, even with colors theming in QT5/QT6 (used qt6ct)
#   Theme is dark, but web pages aren't detecting this and not displaying in dark mode.
#   Dolphin looks like ass. Screen is dark, fonts are black

# Further improvements:
# can I get extension store from Omarchy working?
# IP: Kvantum fixed outer window theming and pop-up dialogs, inner theming is still light mode.
# Lock screen is too vague, no image
# Need to improve Nym-Vpn launcher, presently having to launch from console.
# Add Nym-Vpn to autostart
# Will need to convert setup for 0.57 migration, need to research

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

echo "Updating System before beginning"
# Update repos and system first
sudo xbps-install -Syu

# First backup shell config
hyprland/./backup_shell_config.sh

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
     hyprland hyprland-guiutils swaylock \
     swayidle grim wl-clipboard kvantum\
     mako wofi wl-clipboard wlr-randr \
     xdg-desktop-portal-hyprland xdg-desktop-portal \
     alacritty foot neovim Thunar \
     brightnessctl playerctl pamixer \
     network-manager-applet blueman \
     polkit-gnome gnome-keyring papirus-icon-theme \
     qt6ct hyprland-qt-support \
     xorg-server-xwayland xorg-fonts hyprpolkitagent \
     noctalia swww crystal-dock ttf-jetbrains-mono font-awesome

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/hypr

# Copy shortcut helper
tee "$HOME/.config/hypr/show-shortcuts.sh" < hyprland/show-shortcuts.sh

# Create Hyprland config
tee "$HOME/.config/hypr/hyprland.conf" < hyprland/hyprland.conf

# Fix alacritty settings
# Create Alacritty config file
tee "$HOME/.config/alacritty/alacritty.toml" < hyprland/alacritty.toml

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

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

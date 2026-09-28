#!/bin/bash
# Hyprland on Void?! (Inspired by DHH and Hyprland)
# HELL YES!
# Backup current .zshrc
# VERSION 0.46 - install works, loads with noctalia
# Beta version worthy, function desktop, has dock, sound and help screen.
# Added functional screenshots, it wasn't working with the package list before.
# Cleaned up packages that aren't needed, still need to do more review here!
# Switched from soon to be obsolete .conf to .lua
# Got DBUS properly working, system tray bug now fixed
# refixed audio after converting to LUA, missed that the LLM cut that out of my script.
# Switched launcher from Wofi to Walker. Walker by default looks better, and was easy to theme.
# FIXED: Theming is not consistent, QT apps are still in light mode, even with colors theming in QT5/QT6 (used qt6ct)
#   Theme is dark, but web pages aren't detecting this and not displaying in dark mode.
#   Dolphin looks like GREAT. Screen is dark, fonts are white
# CURRENT BUGS:
# Fixed: Apps (like Nym-VPN) not minimizing to tray, was working on compiling solution
#   hyperland-minimizer (Won't need to work on this project now)
# Further improvements:
# can I get extension store from Omarchy working?
# FIXED: Kvantum fixed outer window theming and pop-up dialogs, inner theming is still light mode.
#   - Created script to fix most theming issues, I'd say over 95%, only seeing issues in a few apps now
# FIXED: Lock screen is too vague, no image - Switched to hyprlock
# FIXED: Need to improve Nym-Vpn launcher, presently having to launch from console. (Wasn't hyprland related, not sure how KDE launchers were working)
# FIXED: Add Nym-Vpn to autostart
# FIXED: Will need to convert setup for 0.57 migration, need to research
# Need to revisit QT Icons, text is better, general theme matches Hyprland/Noctalia - icons are black on grey, making them difficult to see.

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
     hyprland hyprland-guiutils hyprlock \
     swayidle grim grimshot slurp kvantum\
     walker wl-clipboard wlr-randr \
     xdg-desktop-portal-hyprland xdg-desktop-portal \
     alacritty Thunar \
     brightnessctl playerctl pamixer \
     network-manager-applet blueman \
     gnome-keyring papirus-icon-theme \
     qt6ct hyprland-qt-support \
     xorg-server-xwayland xorg-fonts hyprpolkitagent \
     noctalia swww crystal-dock ttf-jetbrains-mono font-awesome

# Make directory for screenshots:
mkdir -P "$HOME/Pictures/screenshots"

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/hypr

# Copy shortcut helper
tee "$HOME/.config/hypr/show-shortcuts.sh" < hyprland/show-shortcuts.sh

# Create Hyprland config
tee "$HOME/.config/hypr/hyprland.lua" < hyprland/hyprland.lua

# Create hyprlock settings
tee "$HOME/.config/hypr/hyprlock.lua" < hyprlock.lua

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

echo "Apply fix to dbus-session"
hyprland/./fix_dbus.sh

echo "Apply fixes for QT theming"
hyprland/./fix_qt_theming.sh

echo "Apply theme fixes for walker"
hyprland/./setup_walker_theme.sh

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

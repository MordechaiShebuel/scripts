#!/bin/bash
# Hyprland on Void?! (Inspired by DHH and Hyprland)
# HELL YES!
# Backup current .zshrc
# VERSION 0.4.96 - install works, loads with noctalia
# Beta version worthy, function desktop, has dock, sound and help screen.
# Added functional screenshots, it wasn't working with the package list before.
# Cleaned up packages that aren't needed, still need to do more review here!
# Switched from soon to be obsolete .conf to .lua
# Got DBUS properly working, system tray bug now fixed
# refixed audio after converting to LUA, missed that the LLM cut that out of my script.
# Switched launcher from Wofi to Walker. Walker by default looks better, and was easy to theme.
# Using Noctalia launcher, polkit, and dock. Massive clean up in startup script, and theme uniformity
# Switched terminal emulator from alacritty to ghostty, allows for goal of emulating MacOS keybindings
# Changed this to RIO, ghostty is just not performant enough for the desktop I want, alacritty not feature rich enough
# Switched screenshots to use Noctalia's built-in toolchain
# Fixed bug I created by switching from Alacritty to Ghostty, help screen not displaying

# Current Feature Requests:
# Compare Omarchy shortcuts to my own, take what seems like it could work
# DONE: Add screenshots to help screen
# DONE: Finish mapping relevant MacOS shortcuts to key bindings
# DONE: Make an actual app for help instead of just a terminal
# DONE: Use Noctalia / greetd or lightdm instead of sddm
#   This has been a massive headache - I think I may have it narrowed down to an agetty conflict, out of tokens.
# DONE: Make shortcut for logout/restart/shutdown popup that is currently activated from panel

# CURRENT BUGS:
# Headphones in Steam don't seem to work, but unplugged and speakers did
#   Headphones work with other apps, Zen - Youtube.
#   Not really sure what's going on here, have to manually select HDMI sink, then USB sink

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
     xdg-desktop-portal-gtk rio Thunar \
     brightnessctl playerctl pamixer \
     blueman gnome-keyring papirus-icon-theme \
     qt6ct hyprland-qt-support \
     xorg-server-xwayland xorg-fonts \
     noctalia ttf-jetbrains-mono font-awesome

echo "Creating configs!"
# Make directory for screenshots:
mkdir -P "$HOME/Pictures/screenshots"

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/hypr

# Copy shortcut helper
cp hyprland/keybind_viewer "$HOME/.config/hypr/keybind_viewer"

# Create/update Hyprland config
cp hyprland/hyprland.lua "$HOME/.config/hypr/hyprland.lua"

cp hyprland/keybind_viewer "$HOME/.config/hypr/keybind_viewer"
chmod +x "$HOME/.config/hypr/keybind_viewer"z

# Create/update hyprlock settings
# cp hyprland/hyprlock.lua "$HOME/.config/hypr/hyprlock.lua"

# Create/update ghostty settings
# cp hyprland/ghostty-config "$HOME/.config/ghostty/config"

# Create/update alacritty settings
# cp hyprland/alacritty.toml "$HOME/.config/alacritty/alacritty.toml"

# create/update alacritty settings
cp hyprland/rio-config.toml "$HOME/.config/rio/config.toml"

# Create/update Noctalia Config
cp hyprland/noctalia-config.toml "$HOME/.config/noctalia/noctalia-config.toml"

echo "Modifying zshrc for QT theme fix"
hyprland/./modify_zshrc.sh

echo "Apply fixes for QT theming"
hyprland/./fix_qt_theming.sh

echo "Fix GTK themes"
sudo xbps-install -S nwg-look gnome-themes-extra

echo "Setting up new greeter"
sudo hyprland/./setup_greetd_greeter.sh

# You'll need to run nwg-look to set this to a dark theme

# Setup runit services
echo "Setting up runit services..."
sudo ln -sf /etc/sv/NetworkManager /var/service/ 2>/dev/null
sudo ln -sf /etc/sv/blueman /var/service/ 2>/dev/null

# Create .xinitrc if it doesn't exist
if [[ ! -f ~/.xinitrc ]]; then
    echo "exec Hyprland" > ~/.xinitrc
fi

echo "Get some wallpapers"
# Change background?
hyprland/./get_stock_wp.sh

echo "Apply fix to dbus-session"
hyprland/./fix_dbus.sh

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

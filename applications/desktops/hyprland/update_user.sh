#!/bin/bash
#
# Update user configs, separated this out so it can be run per user and later on to force config updates.

# First backup shell config
../../../bin/./backup_shell_config.sh

# CHECK for the wallpapers before downloading them again
echo "Get some wallpapers"
# Change background?
./get_stock_wp.sh

echo "Creating/Updating configs!"
# Make directory for screenshots:
mkdir -p "$HOME/Pictures/screenshots"

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/hypr

# Copy hyprland settings
rm -rf "$HOME/.config/hypr/"
cp -r hypr "$HOME/.config/"

# TODO: Let the user choose which terminal they want as as first step
# Create/update ghostty settings
# cp hyprland/ghostty-config "$HOME/.config/ghostty/config"

# Create/update alacritty settings
# cp hyprland/alacritty.toml "$HOME/.config/alacritty/alacritty.toml"

# create/update rio settings
rm -rf "$HOME/.config/rio"
cp -r rio "$HOME/.config/"

# Create/update Noctalia Config
rm -rf "$HOME/.config/noctalia"
cp -r noctalia "$HOME/.config/"

sudo cp -r noctalia-greeter/greeter.toml /var/lib/noctalia-greeter/noctalia-greeter.toml

echo "Modifying zshrc for QT theme fix"
./modify_zshrc.sh

hyprctl reload # Not sure this works from SSH

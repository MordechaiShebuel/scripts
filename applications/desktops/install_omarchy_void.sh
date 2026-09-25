#!/bin/bash
# Omarchy on Void?!
# HELL YES!
# Backup current .zshrc
cp $HOME/.zshrc $HOME/.zshrc-bak

# Change the creepy anime fetish background
# Install a nice wallpaper (example)
mkdir -p ~/.config/wallpapers
wget -O ~/.config/wallpapers/wallpaper.jpg https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80


# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

# Update repos
sudo xbps-install -S

# Setup hyprland repo if necessary
if [[ ! $(command -v hyprland) ]]; then
    echo "hyprland not found, setting up repo."
    echo "repository=https://raw.githubusercontent.com/sofijacom/hyprland-void/repository-x86_64-glibc" | sudo tee /etc/xbps.d/hyprland-void.conf
    sudo xbps-install -S hyprland
fi

# Install Hyprland and dependencies
sudo xbps-install -S \
    hyprland waybar swaylock swayidle grim wl-clipboard \
    mako rofi-wayland wofi wl-clipboard wlr-randr \
    xdg-desktop-portal-hyprland xdg-desktop-portal \
    alacritty kitty foot neovim thunar \
    brightnessctl playerctl pamixer \
    network-manager-applet blueman \
    polkit-gnome gnome-keyring \
    qt5ct qt6ct qt5-styleplugins \
    xorg-server-xwayland xorg-fonts

# Install recommended fonts
sudo xbps-install -S \
    ttf-jetbrains-mono ttf-font-awesome ttf-nerd-fonts-symbols \
    ttf-ubuntu-font-family

# Clone Omarchy config (using a working fork)
if [[ ! -d ~/.config/Omarchy ]]; then
    git clone https://github.com/gh0stzk/Omarchy.git ~/.config/Omarchy || \
    git clone https://github.com/omacom/omadots.git ~/.config/Omarchy
    cd ~/.config/Omarchy
    ./install.sh
fi

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/hypr

# Create Hyprland config
tee ~/.config/hypr/hyprland.conf <<'EOF'
# Wallpaper
exec-once = swww init
exec-once = swww img ~/.config/wallpapers/wallpaper.jpg

# Set DISPLAY manually (runit doesn't handle this automatically)
exec-once = export DISPLAY=:0

# Start services directly (no systemctl)
exec-once = waybar
exec-once = swayidle -w timeout 300 'swaylock -f' before-sleep 'swaylock -f'
exec-once = mako
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Keybinds
$mainMod = SUPER

bind = $mainMod, RETURN, exec, alacritty
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, Q, killactive,
bind = $mainMod, F, fullscreen, 1

# Keybinds
$mainMod = SUPER

# Terminal
bind = $mainMod, RETURN, exec, alacritty

# App Launcher (wofi)
bind = $mainMod, D, exec, wofi --show drun

# Close window
bind = $mainMod, Q, killactive,

# Fullscreen
bind = $mainMod, F, fullscreen, 1

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5

# Move windows between workspaces
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
EOF

# Create Waybar config directory if it doesn't exist
mkdir -p ~/.config/waybar

# Create Waybar config
tee ~/.config/waybar/config <<'EOF'
{
  "layer": "top",
  "modules-left": ["hyprland/workspaces", "hyprland/window"],
  "modules-center": ["tray"],
  "modules-right": ["network", "cpu", "memory", "temperature", "battery", "clock"],
  "tray-position": "right"
}
EOF

# Create Waybar style file
tee ~/.config/waybar/style.css <<'EOF'
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 12px;
    background-color: #282828;
    color: #ebdbb2;
}
EOF

# Setup runit services
echo "Setting up runit services..."
sudo ln -sf /etc/sv/NetworkManager /var/service/ 2>/dev/null
sudo ln -sf /etc/sv/blueman /var/service/ 2>/dev/null

# Create .xinitrc if it doesn't exist
if [[ ! -f ~/.xinitrc ]]; then
    echo "exec Hyprland" > ~/.xinitrc
fi

echo "Installing quickshell"
sudo xbps-install -S \
    cmake ninja gcc gcc-objc++ \
    pkg-config \
    wayland-devel \
    libxkbcommon-devel \
    libinput-devel \
    libseat-devel \
    qt6-shadertools \
    qt6-base-devel \
    qt6-declarative-devel \
    qt6-wayland-devel \
    qt6-svg-devel \
    qt6-tools

git clone https://github.com/quickshell-mirror/quickshell.git ~/quickshell
cd ~/quickshell
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release
cmake --install build
sudo make install


# Install swww (wallpaper utility)
sudo xbps-install -S swww

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

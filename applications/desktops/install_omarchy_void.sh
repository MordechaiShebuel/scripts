#!/bin/bash
# Omarchy on Void?!
# HELL YES!
# Backup current .zshrc
# VERSION 0.2 - install works, loads with noctalia
# BUGS: What doesn't work
# FIXED: SUPER+D doesn't open launcher - most of the other binds are working
# IP: Theming is not consistent, QT apps are still in light mode, even with colors theming in QT5/QT6 (used qt6ct)
# Sound is not functioning - this could be similar to the problem I was having with COSMIC.
# Applications that have a SUDO style popup, that log in prompt is not appearing. (EX: VPN app)

# Further improvements:
# INSTALL floating dock
# can I get extension store from Omarchy working?

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

# DISABLE THIS SECTION, custom hyprland repo is having ABI issues

# Setup hyprland repo if necessary
# if [[ ! $(command -v hyprland) ]]; then
#    echo "hyprland not found, setting up repo."
#    echo "repository=https://raw.githubusercontent.com/sofijacom/hyprland-void/repository-x86_64-glibc" | sudo tee /etc/xbps.d/hyprland-void.conf
#    sudo xbps-install -S hyprland
# fi

# Install Hyprland and dependencies
sudo xbps-install -S \
    hyprland hyprland-guiutils waybar swaylock \
    swayidle grim wl-clipboard wofi\
    mako rofi-wayland wofi wl-clipboard wlr-randr \
    xdg-desktop-portal-hyprland xdg-desktop-portal \
    alacritty kitty foot neovim thunar \
    brightnessctl playerctl pamixer \
    network-manager-applet blueman \
    polkit-gnome gnome-keyring papirus-icon-theme \
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
# ============================================================================
# HYPRLAND CONFIG - Omarchy on Void (Compatible with older Hyprland versions)
# ============================================================================

# Monitor configuration
monitor = ,preferred,auto,1

# ============================================================================
# AUTOSTART
# ============================================================================

exec-once = noctalia
exec-once = waybar
exec-once = swayidle -w timeout 300 'swaylock -f' before-sleep 'swaylock -f'
exec-once = mako
exec-once = nm-applet --indicator
exec-once = blueman-applet
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec-once = swww init
exec-once = swww img ~/.config/wallpapers/wallpaper.jpg

# ============================================================================
# INPUT CONFIGURATION (Older Hyprland compatible)
# ============================================================================

input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
}

# ============================================================================
# GENERAL
# ============================================================================

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = 0xff89b4fa
    col.inactive_border = 0xff45475a
    layout = dwindle
    allow_tearing = false
}

decoration {
    rounding = 10
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 5, myBezier
    animation = windowsOut, 1, 5, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 5, default
    animation = workspaces, 1, 6, default
}

dwindle {
    preserve_split = true
}

# KEYBINDS
# ============================================================================

$mainMod = SUPER

# Terminal
bind = $mainMod, Return, exec, alacritty

# App Launcher
bind = $mainMod, D, exec, wofi --show drun

# Close window
bind = $mainMod, Q, killactive,

# Fullscreen
bind = $mainMod, F, fullscreen, 1

# Toggle floating
bind = $mainMod, Space, togglefloating,

# Move focus with arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspaces (1-5)
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5

# Move windows to workspaces
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

# Volume control (if available)
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t

# Brightness control (if available)
bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Screenshot
bind = $mainMod, Print, exec, grim -g "$(slurp)" - | wl-copy
bind = , Print, exec, grim ~/Pictures/screenshot-$(date +%s).png

# Lock screen
bind = $mainMod CTRL, L, exec, swaylock -f
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

# Noctalia shell based option:
sudo xbps-install -S noctalia

# Install swww (wallpaper utility)
sudo xbps-install -S swww

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

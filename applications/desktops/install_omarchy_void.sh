#!/bin/bash
# Omarchy on Void?!
# HELL YES!
# Backup current .zshrc
# VERSION 0.35 - install works, loads with noctalia
# BUGS: What doesn't work
# FIXED: SUPER+D doesn't open launcher - most of the other binds are working
# IP: Theming is not consistent, QT apps are still in light mode, even with colors theming in QT5/QT6 (used qt6ct)
#   Theme is dark, but web pages aren't detecting this and not displaying in dark mode.
#   Dolphin looks like ass. Screen is dark, fonts are black
# FIXED/IP: Sound is functioning - this could be similar to the problem I was having with COSMIC, I bet COSMIC needs a similar startup script.
#   Still some minor issues here, not seeing my main sound board or HDMI outputs as options.
#   When USB headphones are unplugged it auto switches to HDMI output
# FIXED: Applications that have a SUDO style popup, that log in prompt is not appearing. (EX: VPN app)

# Further improvements:
# DONE: INSTALL floating dock
#   crystal-dock is being a bit finicky, will start but seems to crash or quit for some reason
#   Dock icons are borked after trying to fiddle with KDE Dark settings. May need to remove that Python script and service
# DONE: Able to change wallpaper from console. (Make Graphical option?)
# can I get extension store from Omarchy working?
# DONE: Font in Alacritty looks like ass
# IP: Kvantum fixed outer window theming and pop-up dialogs, inner theming is still light mode.
# Lock screen is too vague, no image
# Need to improve Nym-Vpn launcher, presently having to launch from console.
# Add Nym-Vpn to autostart

cp $HOME/.zshrc $HOME/.zshrc-bak

# Change the creepy anime fetish background
# Install a nice wallpaper (example)
mkdir -p ~/.config/wallpapersa
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
     noctalia swww crystal-dock

# Install recommended fonts
sudo xbps-install -S \
    ttf-jetbrains-mono font-awesome

# Create Hyprland configs directory if it doesn't exist
mkdir -p ~/.config/hypr

# Create Hyprland config
tee ~/.config/hypr/hyprland.conf <<'EOF'
# ============================================================================
# HYPRLAND CONFIG - Omarchy on Void (Compatible with older Hyprland versions)
# ============================================================================

# Monitor configuration
monitor = ,preferred,auto,1
env = WAYLAND_DISPLAY,wayland-1
env = XDG_CURRENT_DESKTOP,Hyprland

# ============================================================================
# AUTOSTART
# ============================================================================

exec-once = /usr/bin/pipewire &
exec-once = /usr/bin/pipewire -c pipewire-pulse.conf &
exec-once = noctalia &
exec-once = waybar &
exec-once = swayidle -w timeout 300 'swaylock -f' before-sleep 'swaylock -f' &
exec-once = mako &
exec-once = nm-applet --indicator &
exec-once = /usr/bin/octoxbps-notifier &
exec-once = /usr/libexec/hyprpolkitagent &
exec-once = swww init &
exec-once = swww img ~/.config/wallpapers/wallpaper.jpg &
exec-once = sleep 2 && crystal-dock &

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
$secondMod = ALT

# Terminal
bind = $mainMod, Return, exec, alacritty

# App Launcher
bind = $mainMod, D, exec, wofi --show drun
bind = $secondMod, SPACE, exec, wofi --show drun

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
  "modules-right": ["network", "cpu", "memory", "temperature", "clock"],
  "tray-position": "right"
}
EOF

# Create Waybar style file
tee ~/.config/waybar/style.css <<'EOF'
* {
    font-family: "CaskaydiaCove Nerd Font";
    font-size: 12px;
    background-color: #282828;
    color: #ebdbb2;
}
EOF

# Fix alacritty settings
# Create Alacritty config file
tee ~/.config/alacritty/alacritty.toml <<'EOF'
[general]
live_config_reload = true
working_directory = "None"

# Active theme — managed by theme-apply.sh, do not edit manually.
# Change the theme in ~/.config/dwm-titus/themes.toml instead.
import = [
  "~/.config/alacritty/active-theme.toml",
  "~/.config/alacritty/keybinds.toml"
]

[window]
title = "Alacritty"
decorations = "none"
blur = true
opacity = 0.9
padding.x = 10
padding.y = 10

[window.dimensions]
columns = 100
lines = 30

[cursor.style]
shape= "Beam"
blinking = "Never"

[colors]
#transparent_background_colors = true
draw_bold_text_with_bright_colors = true

[env]
TERM = "xterm-256color"

[font]
normal.family = "JetBrains Mono"
normal.style = "Regular"
size = 11.0

[font.bold]
family = "JetBrains Mono"
style = "Bold"

[font.italic]
family = "JetBrains Mono"
style = "Italic"

[font.bold_italic]
family = "JetBrains Mono"
style = "Bold Italic"
EOF

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

# Fix KDE settings;
cat > ~/.local/bin/kde-appearance-dbus-service << 'EOF'
#!/usr/bin/env python3
"""
Advertise org.freedesktop.appearance.ColorScheme via dbus-python's service module.
Uses Properties interface properly registered.
"""

import sys
import subprocess
import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

def get_color_scheme():
    try:
        result = subprocess.run(
            ['kreadconfig6', '--file', 'kdeglobals',
             '--group', 'Colors:Window', '--key', 'BackgroundNormal'],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode == 0:
            bg_str = result.stdout.strip()
            r, g, b = map(int, bg_str.split(','))
            luminance = (0.299 * r + 0.587 * g + 0.114 * b)
            return 0 if luminance < 128 else 1
    except Exception as e:
        print(f"Error reading color scheme: {e}", file=sys.stderr)
    return 0

class AppearanceService(dbus.service.Object):
    def __init__(self, bus, path):
        super().__init__(bus, path)
        self._color_scheme = get_color_scheme()

    @dbus.service.method('org.freedesktop.DBus.Introspectable', out_signature='s')
    def Introspect(self):
        return '''<!DOCTYPE node PUBLIC "-//freedesktop//DTD D-BUS Object Introspection 1.0//EN"
"http://www.freedesktop.org/standards/dbus/1.0/introspect.dtd">
<node name="/org/freedesktop/appearance/desktop">
  <interface name="org.freedesktop.DBus.Introspectable">
    <method name="Introspect">
      <arg name="xml_data" type="s" direction="out"/>
    </method>
  </interface>
  <interface name="org.freedesktop.DBus.Properties">
    <method name="Get">
      <arg name="interface_name" type="s" direction="in"/>
      <arg name="property_name" type="s" direction="in"/>
      <arg name="value" type="v" direction="out"/>
    </method>
    <method name="GetAll">
      <arg name="interface_name" type="s" direction="in"/>
      <arg name="properties" type="a{sv}" direction="out"/>
    </method>
  </interface>
  <interface name="org.freedesktop.appearance">
    <property name="ColorScheme" type="u" access="read"/>
  </interface>
</node>
'''

    @dbus.service.method('org.freedesktop.DBus.Properties',
                         in_signature='ss', out_signature='v')
    def Get(self, interface_name, property_name):
        if interface_name == 'org.freedesktop.appearance':
            if property_name == 'ColorScheme':
                return dbus.UInt32(get_color_scheme())
            else:
                raise dbus.exceptions.DBusException(
                    f'org.freedesktop.DBus.Error.InvalidArgs: No such property: {property_name}')
        else:
            raise dbus.exceptions.DBusException(
                f'org.freedesktop.DBus.Error.InvalidArgs: No such interface: {interface_name}')

    @dbus.service.method('org.freedesktop.DBus.Properties',
                         in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface_name):
        if interface_name == 'org.freedesktop.appearance':
            return {'ColorScheme': dbus.UInt32(get_color_scheme())}
        else:
            raise dbus.exceptions.DBusException(
                f'org.freedesktop.DBus.Error.InvalidArgs: No such interface: {interface_name}')

def main():
    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()

    # Request the service name
    try:
        bus_name = dbus.service.BusName('org.freedesktop.appearance', bus=bus)
    except dbus.exceptions.DBusException as e:
        print(f"Error: Could not acquire bus name: {e}", file=sys.stderr)
        sys.exit(1)

    # Register the object
    obj = AppearanceService(bus, '/org/freedesktop/appearance/desktop')

    print("org.freedesktop.appearance service started", file=sys.stderr)
    print(f"Color scheme: {'dark' if get_color_scheme() == 0 else 'light'}", file=sys.stderr)
    sys.stderr.flush()

    # Run the main loop
    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        print("Shutting down...", file=sys.stderr)

if __name__ == '__main__':
    main()
EOF

chmod +x ~/.local/bin/kde-appearance-dbus-service


# Start service:
mkdir -p ~/.local/service/kde-appearance-dbus

cat > ~/.local/service/kde-appearance-dbus/run << 'EOF'
#!/bin/sh
exec 2>&1
exec ~/.local/bin/kde-appearance-dbus-service.py
EOF

chmod +x ~/.local/service/kde-appearance-dbus/run

ln -s ~/.local/service/kde-appearance-dbus ~/service/kde-appearance-dbus # does not work, no service folder in my user space

echo "Installation complete!"
echo "You can now start Hyprland by running 'startx' or configure your display manager."

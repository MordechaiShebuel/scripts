#!/bin/sh
# Fix Hyprland SDDM session to start with a proper D-Bus session bus
# Safe for Void Linux + SDDM

set -e

SRC="/usr/share/wayland-sessions/hyprland.desktop"
DEST_DIR="/usr/local/share/wayland-sessions"
DEST="$DEST_DIR/hyprland.desktop"

echo "==> Creating local override for Hyprland session..."

# Create directory if needed
sudo mkdir -p "$DEST_DIR"

# Write the fixed desktop entry
sudo tee "$DEST" > /dev/null << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=dbus-run-session /usr/bin/start-hyprland
Type=Application
DesktopNames=Hyprland
Keywords=tiling;wayland;compositor;
EOF

echo "==> Override created at: $DEST"
echo
echo "Contents:"
cat "$DEST"
echo
echo "Done. Log out completely (or reboot) and select Hyprland in SDDM."
echo "After login, verify with:"
echo "  echo \$DBUS_SESSION_BUS_ADDRESS"
echo "  busctl --user status"

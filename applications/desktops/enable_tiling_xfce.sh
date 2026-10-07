#!/usr/bin/env bash
set -Eeuo pipefail
REPO_SRC="$HOME/src"

mkdir "$REPO_SRC"
cd "$REPO_SRC"
git clone https://github.com/jaywilkas/xpytile.git

SCRIPT_DIR="$REPO_SRC/xpytile"
CONFIG_DIR="${XDG_CONFIG_HOME:-"$HOME/.config"}"
AUTOSTART_DIR="$CONFIG_DIR/autostart"

XPYTILE_SCRIPT="$SCRIPT_DIR/xpytile.py"
XPYTILE_CONFIG="$SCRIPT_DIR/xpytilerc"
AUTOSTART_FILE="$AUTOSTART_DIR/xpytile.desktop"

if [[ ! -f "$XPYTILE_SCRIPT" ]]; then
    echo "Error: xpytile.py was not found in $SCRIPT_DIR" >&2
    exit 1
fi

if [[ ! -f "$XPYTILE_CONFIG" ]]; then
    echo "Error: xpytilerc was not found in $SCRIPT_DIR" >&2
    exit 1
fi

mkdir -p "$CONFIG_DIR" "$AUTOSTART_DIR"

# Copy the configuration file to the XDG configuration directory.
install -m 0644 "$XPYTILE_CONFIG" "$CONFIG_DIR/xpytilerc"

# Make sure the Python program is executable.
chmod +x "$XPYTILE_SCRIPT"

# Create an XFCE/session autostart entry.
cat > "$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=xpytile
Comment=Automatic window tiling for XFCE
Exec=/usr/bin/env python3 $XPYTILE_SCRIPT
Terminal=false
StartupNotify=false
X-GNOME-Autostart-enabled=true
EOF

chmod 0644 "$AUTOSTART_FILE"

echo "xpytile installed successfully."
echo "Configuration: $CONFIG_DIR/xpytilerc"
echo "Autostart entry: $AUTOSTART_FILE"
echo
echo "Start it now with:"
echo "  python3 \"$XPYTILE_SCRIPT\""

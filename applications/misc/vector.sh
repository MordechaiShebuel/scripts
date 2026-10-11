#!/bin/bash
#
# Appimage dump
#
# Add update / uninstall / install options

VER=0.4.4
PROD_NAME="VectorPrivacyChat"
APP_IMG_DIR="$HOME/apps/$PROD_NAME"
appimage="VectorChat.AppImage"
appimage_url="https://github.com/VectorPrivacy/Vector/releases/download/v0.4.4/Vector_0.4.4_amd64.AppImage"
icon="vector-logo.svg"
icon_url="https://raw.githubusercontent.com/VectorPrivacy/Vector/refs/heads/master/src/icons/vector-logo.svg"
appname="vector_chat"

OPTION="${1:-install}"

# If uninstall or update, remove prior code
if [[ $OPTION == "uninstall" || $OPTION == "update" ]]; then
    rm -rf "$APP_IMG_DIR"
    rm -f "$HOME/bin/$appname"
    rm -f "$HOME/.local/share/applications/$appname.desktop"
    rm -rf "$HOME/.cache/vectorchat-appimage"
fi

if [[ $OPTION == "uninstall" ]]; then
    echo "Finished uninstalling."
    exit 0
fi

# Download App Image to local directory
echo "Downloading App Image for $appimage"
mkdir -p "$APP_IMG_DIR"
curl -fL -# "$appimage_url" -o "$APP_IMG_DIR/$appimage"
# Make AppImage executable
chmod +x "$APP_IMG_DIR/$appimage"
curl -fL -# "$icon_url" -o "$APP_IMG_DIR/$icon"

# Create local bin / fix EGL Wayland issue:
#
echo "Applying Patch for AppImage"
LOCALBIN="$HOME/bin" # Need to make sure you have path to this
mkdir -p "$LOCALBIN"

tee "$LOCALBIN/$appname" <<'EOF'
#!/bin/bash

set -e

EXTRACT_DIR="$HOME/.cache/vectorchat-appimage"
APPIMAGE="$HOME/apps/VectorPrivacyChat/VectorChat.AppImage"
ROOT="$EXTRACT_DIR/squashfs-root"

if [ ! -x "$ROOT/AppRun" ]; then
    rm -rf "$ROOT"
    mkdir -p "$EXTRACT_DIR"

    (
        cd "$EXTRACT_DIR"
        "$APPIMAGE" --appimage-extract
    )

    rm -f "$ROOT/usr/lib/libwayland-"*.so*
    rm -f "$ROOT/usr/lib/libEGL"*.so*
    rm -f "$ROOT/usr/lib/libGL"*.so*
fi

exec "$ROOT/AppRun" "$@"
EOF
chmod +x "$LOCALBIN/$appname"

# Create Desktop Shortcut
# create desktop entry
tee "$HOME/.local/share/applications/$appname.desktop" <<EOF
[Desktop Entry]
Categories=Utilities;
Comment=Local Password Management
Exec=$LOCALBIN/$appname %U
Icon=$APP_IMG_DIR/$icon
Name=$PROD_NAME
NoDisplay=false
Path=
PrefersNonDefaultGPU=false
StartupNotify=true
StartupWMClass=$appname
Terminal=false
TerminalOptions=
Type=Application
Version=$VER
X-KDE-SubstituteUID=false
X-KDE-Username=
EOF

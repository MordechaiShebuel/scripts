#!/usr/bin/env bash

set -Eeuo pipefail

SERVICE_NAME="avahi-daemon"
SERVICE_SOURCE="/etc/sv/$SERVICE_NAME"
SERVICE_DIR="/etc/runit/runsvdir/default"
SERVICE_LINK="$SERVICE_DIR/$SERVICE_NAME"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Install Avahi if necessary
if ! xbps-query -p pkgver avahi >/dev/null 2>&1; then
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    INSTALLER="$SCRIPT_DIR/../bin/inst.sh"

    [ -x "$INSTALLER" ] ||
        die "Installer not found or not executable: $INSTALLER"

    "$INSTALLER" avahi
else
    echo "avahi is already installed."
fi

[ -d "$SERVICE_SOURCE" ] ||
    die "Missing service directory: $SERVICE_SOURCE"

[ -x "$SERVICE_SOURCE/run" ] ||
    die "Missing or non-executable run script: $SERVICE_SOURCE/run"

# Remove stale supervise symlink left by a previous failed attempt
if [ -L "$SERVICE_SOURCE/supervise" ]; then
    sudo rm -f "$SERVICE_SOURCE/supervise"
fi

echo "Enabling $SERVICE_NAME..."
sudo rm -f "$SERVICE_LINK"
sudo ln -s "$SERVICE_SOURCE" "$SERVICE_LINK"

for _ in {1..15}; do
    status="$(sudo sv status "$SERVICE_NAME" 2>&1 || true)"

    if [[ "$status" == run:* ]]; then
        echo "$status"
        echo "$SERVICE_NAME is running."
        break
    fi

    sleep 1
done

echo "ERROR: $SERVICE_NAME failed to start." >&2
sudo sv status "$SERVICE_NAME" || true
exit 1

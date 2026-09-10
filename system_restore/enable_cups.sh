#!/usr/bin/env bash

set -Eeuo pipefail

SERVICE_NAME="cupsd"
SERVICE_SOURCE="/etc/sv/$SERVICE_NAME"
SERVICE_DIR="/etc/runit/runsvdir/default"
SERVICE_LINK="$SERVICE_DIR/$SERVICE_NAME"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Install and enable CUPS
if ! xbps-query -p pkgver cups >/dev/null 2>&1; then
    sudo xbps-install -S
    sudo xbps-install -y cups cups-filters print-manager system-config-printer
else
    echo "CUPS is already installed."
fi

# Confirm that the package supplied the runit service
[ -d "$SERVICE_SOURCE" ] ||
    die "Missing service directory: $SERVICE_SOURCE"

[ -x "$SERVICE_SOURCE/run" ] ||
    die "Missing or non-executable run script: $SERVICE_SOURCE/run"

# Remove stale supervision state only if it's a broken symlink
if [ -L "$SERVICE_SOURCE/supervise" ] && [ ! -e "$SERVICE_SOURCE/supervise" ]; then
    sudo rm -f "$SERVICE_SOURCE/supervise"
fi


# Recreate the service link in the directory watched by runit
echo "Enabling $SERVICE_NAME..."
sudo rm -f "$SERVICE_LINK"
sudo ln -s "$SERVICE_SOURCE" "$SERVICE_LINK"

# Wait for runit to discover and start the service
sleep 2
for _ in {1..15}; do
    if sudo sv status "$SERVICE_NAME" >/dev/null 2>&1; then
        echo "$(sudo sv status "$SERVICE_NAME")"
        echo "$SERVICE_NAME is running."
        break
    fi

    sleep 1
done

echo "ERROR: $SERVICE_NAME failed to start." >&2
sudo sv status "$SERVICE_NAME" || true
exit 1

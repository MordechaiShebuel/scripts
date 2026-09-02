#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root."
    exit 1
fi

SERVER="10.0.0.147"
REMOTE_PATH="/home/media/shared"
USERNAME="${1:?Usage: $0 nezmahb}"

# Look up the user and home directory
USER_INFO="$(getent passwd "$USERNAME" || true)"

if [[ -z "$USER_INFO" ]]; then
    echo "User not found: $USERNAME" >&2
    exit 1
fi

USER_HOME="$(cut -d: -f6 <<< "$USER_INFO")"

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    echo "Home directory does not exist: $USER_HOME" >&2
    exit 1
fi

MOUNT_POINT="$USER_HOME/shared/local-server"
FSTAB_LINE="$SERVER:/ $MOUNT_POINT nfs defaults,_netdev 0 0"

# Create the mount-point directory if necessary
install -d \
    -o "$USERNAME" \
    -g "$(id -gn "$USERNAME")" \
    "$MOUNT_POINT"

# Add the fstab entry only if an identical line does not already exist
if grep -Fqx -- "$FSTAB_LINE" /etc/fstab; then
    echo "fstab entry already exists:"
    echo "$FSTAB_LINE"
else
    printf '%s\n' "$FSTAB_LINE" >> /etc/fstab
    echo "Added fstab entry:"
    echo "$FSTAB_LINE"
fi

# Mount it if it is not already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "Already mounted: $MOUNT_POINT"
else
    mount "$MOUNT_POINT"
    echo "Mounted: $MOUNT_POINT"
fi

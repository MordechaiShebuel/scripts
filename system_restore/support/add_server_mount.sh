#!/usr/bin/env bash
set -euo pipefail

SERVER="10.0.0.147"
REMOTE_PATH="/home/media/shared"
USERNAME="${1:?Usage: $0 username}"

# Get the user's home directory from the local account database
USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"

if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    echo "User or home directory not found: $USERNAME" >&2
    exit 1
fi

MOUNT_POINT="$USER_HOME/shared/local-server"
FSTAB_LINE="$SERVER:$REMOTE_PATH $MOUNT_POINT nfs defaults,_netdev 0 0"

# Ensure the directory exists and belongs to the user
install -d -o "$USERNAME" -g "$(id -gn "$USERNAME")" "$MOUNT_POINT"

# Append the fstab entry only if it is not already present
if ! grep -Fqx "$FSTAB_LINE" /etc/fstab; then
    printf '%s\n' "$FSTAB_LINE" >> /etc/fstab
    echo "Added entry to /etc/fstab"
    echo "$FSTAB_LINE"
else
    echo "Entry already exists in /etc/fstab"
    echo "$FSTAB_LINE"
fi

# Mount this entry
mount "$MOUNT_POINT"

echo "Mounted $MOUNT_POINT"

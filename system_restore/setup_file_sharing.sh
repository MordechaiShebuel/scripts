#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script as root."
    exit 1
fi

SERVER="10.0.0.147"
REMOTE_PATH="/home/media/shared"
USERNAME="${1:?Usage: $0 username}"

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
FSTAB_LINE="$SERVER:/ $MOUNT_POINT nfs defaults,_netdev,timeo=50,retrans=2 0 0"

# Create the mount-point directory if necessary
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir -p "$MOUNT_POINT"
fi

# Only change ownership while it is not mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    chown "$USERNAME:$(id -gn "$USERNAME")" "$MOUNT_POINT"
fi

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

echo "Creating cron job for shared mount check"
# Create Chron job to mount if lost
SCRIPT="/usr/local/sbin/check-shared-mount"
CRON_LINE="*/5 * * * * /usr/local/sbin/check-shared-mount"

# Create the mount-check script if it does not exist
if [ ! -e "$SCRIPT" ]; then
    tee "$SCRIPT" >/dev/null <<EOF
#!/bin/sh

MOUNTPOINT="/home/${USERNAME}/shared/local-server"
LOGFILE="/var/log/check-shared-mount.log"

if ! /usr/bin/mountpoint -q "\$MOUNTPOINT"; then
    printf '%s: Mount is unavailable; attempting to mount it\n' "\$(date)" >> "\$LOGFILE"

    if /usr/bin/mount "\$MOUNTPOINT" >> "\$LOGFILE" 2>&1; then
        printf '%s: Mount succeeded\n' "\$(date)" >> "\$LOGFILE"
    else
        printf '%s: Mount failed\n' "\$(date)" >> "\$LOGFILE"
    fi
fi
EOF

    chmod 755 "$SCRIPT"
else
    echo "$SCRIPT already exists; leaving it unchanged"
fi

# Add the cron job if it does not already exist
if ! crontab -l 2>/dev/null | grep -Fqx "$CRON_LINE"; then
    (
        crontab -l 2>/dev/null
        printf '%s\n' "$CRON_LINE"
    ) | crontab -

    echo "Cron job added"
else
    echo "Cron job already exists; leaving it unchanged"
fi

echo "Cron setup complete: $(crontab -l)"

echo "Done"

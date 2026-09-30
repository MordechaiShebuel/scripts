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
FSTAB_LINE="$SERVER:/ $MOUNT_POINT nfs defaults,_netdev,nofail,timeo=50,retrans=2 0 0"

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
    echo "Mounting: $MOUNT_POINT"

    if timeout 30 mount -v "$MOUNT_POINT"; then
        echo "Mounted: $MOUNT_POINT"
    else
        status=$?
        echo "Mount failed or timed out after 30 seconds: $MOUNT_POINT" >&2
        exit "$status"
    fi
fi

echo "Creating cron job for shared mount check"
# Create Chron job to mount if lost
SCRIPT="/usr/local/sbin/check-shared-mount"
CRON_LINE="*/2 * * * * /usr/local/sbin/check-shared-mount"

# Create the mount-check script if it does not exist
if [ ! -e "$SCRIPT" ]; then
    tee "$SCRIPT" >/dev/null <<EOF
#!/bin/sh

MOUNTPOINT="/home/mshalom/shared/local-server"
LOGFILE="/var/log/check-shared-mount.log"
LOCKDIR="/run/check-shared-mount.lock"
SERVER="10.0.0.147"

if ! mkdir "$LOCKDIR" 2>/dev/null; then
    exit 0
fi

trap 'rmdir "$LOCKDIR"' EXIT INT TERM

log() {
    printf '%s: %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOGFILE"
}

vpn_active() {
    /usr/bin/ip link show tun0 >/dev/null 2>&1 ||
    /usr/bin/ip link show tun1 >/dev/null 2>&1
}

is_mounted() {
    /usr/bin/mountpoint -q "$MOUNTPOINT"
}

# Disconnect the NFS mount whenever either VPN tunnel is active.
if vpn_active; then
    if is_mounted; then
        log "VPN active; lazily unmounting NFS share"
        /usr/bin/umount -l "$MOUNTPOINT" >> "$LOGFILE" 2>&1
    else
        log "VPN active; NFS share is not mounted"
    fi
    exit 0
fi

# If it is mounted, check if it's responding.
if is_mounted; then
    if /usr/bin/timeout 5 /usr/bin/stat "$MOUNTPOINT/." \
        >/dev/null 2>&1; then
        log "NFS mount is healthy and responding"
        exit 0
    else
        # Mount is stale; unmount it before retrying
        log "NFS mount is stale; lazily unmounting"
        /usr/bin/umount -l "$MOUNTPOINT" >> "$LOGFILE" 2>&1
        sleep 2
    fi
fi

# Do not mount unless TCP/2049 is accepting connections.
if ! /usr/bin/timeout 5 /usr/bin/nc -z "$SERVER" 2049 \
    >/dev/null 2>&1; then
    log "NFS port 2049 is unavailable; skipping mount"
    exit 0
fi

if ! is_mounted; then
    log "NFS share is not mounted; attempting to mount it"

    if /usr/bin/timeout -k 2 20 /usr/bin/mount "$MOUNTPOINT" \
        >> "$LOGFILE" 2>&1; then
        log "Mount succeeded"
    else
        log "Mount failed or timed out"
    fi
fi
EOF

    chmod 755 "$SCRIPT"
    sudo touch /var/log/check-shared-mount.log
    sudo chmod 644 /var/log/check-shared-mount.log
    echo "Created: $SCRIPT"
else
    echo "$SCRIPT already exists; leaving it unchanged"
fi

# Add the cron job if it does not already exist
if ! crontab -l 2>/dev/null | grep -Fqx "$CRON_LINE"; then
    (
        crontab -l 2>/dev/null
        sudo printf '%s\n' "$CRON_LINE"
    ) | crontab -

    echo "Cron job added"
else
    echo "Cron job already exists; leaving it unchanged"
fi

echo "Cron setup complete: $(crontab -l)"

echo "Done"

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
CRON_LINE="*/5 * * * * /bin/sh -c 'exec /usr/local/sbin/check-shared-mount'"

# Create the mount-check script if it does not exist
if [ ! -e "$SCRIPT" ]; then
    tee "$SCRIPT" >/dev/null <<'EOF'
#!/bin/bash
set -u

MOUNT_POINT="/home/USERNAME/shared/local-server"
VPN_INTERFACES=(wg0 tun0)

LOCKFILE="/run/check-shared-mount.lock"
LOGFILE="/var/log/check-shared-mount.log"

exec 9>"$LOCKFILE" || exit 1
/usr/bin/flock -n 9 || exit 0

log() {
    printf '%s: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOGFILE"
}

is_mounted() {
    /usr/bin/findmnt -rn -M "$MOUNT_POINT" >/dev/null 2>&1
}

VPN_INTERFACES=(tun0 tun1)

vpn_is_up() {
    local iface flags
    for iface in "${VPN_INTERFACES[@]}"; do
        [[ -r "/sys/class/net/$iface/flags" ]] || continue
        flags=$(<"/sys/class/net/$iface/flags")
        (( flags & 1 )) && return 0  # IFF_UP
    done
    return 1
}

if vpn_is_up; then
    if is_mounted; then
        log "VPN interface is up; lazily detaching NFS mount"
        if /usr/bin/timeout -k 2 5 /usr/bin/umount -l -- "$MOUNT_POINT"; then
            log "Lazy unmount completed"
        else
            log "Lazy unmount failed or timed out"
        fi
    else
        log "VPN interface is up; NFS mount is not listed as mounted"
    fi
    exit 0
fi

if is_mounted; then
    log "VPN interface is down; NFS mount is already listed as mounted"
    exit 0
fi

log "VPN interface is down; attempting NFS mount"
if /usr/bin/timeout -k 2 20 /usr/bin/mount -- "$MOUNT_POINT" >>"$LOGFILE" 2>&1; then
    log "Mount succeeded"
else
    status=$?
    log "Mount failed or timed out (status $status)"
    exit "$status"
fi
EOF

    sudo -v
    sudo chmod 755 "$SCRIPT"
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
        printf '%s\n' "$CRON_LINE"
    ) | crontab -

    echo "Cron job added"
else
    echo "Cron job already exists; leaving it unchanged"
fi

echo "Cron setup complete: $(crontab -l)"

echo "Done"

#!/bin/sh

MOUNTPOINT_M="/home/$USER_1/shared/local-server"
MOUNTPOINT_N="/home/$USER_2/shared/local-server"
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
    /usr/bin/mountpoint -q "$MOUNTPOINT_M"
    /usr/bin/mountpoint -q "$MOUNTPOINT_N"
}

# Disconnect the NFS mount whenever either VPN tunnel is active.
if vpn_active; then
    if is_mounted; then
        log "VPN active; lazily unmounting NFS share"
        /usr/bin/umount -l "$MOUNTPOINT_M" >> "$LOGFILE" 2>&1
	/usr/bin/umount -l "$MOUNTPOINT_N" >> "$LOGFILE" 2>&1
    else
        log "VPN active; NFS share is not mounted"
    fi
    exit 0
fi

# If it is mounted, check if it's responding.
if is_mounted; then
    if /usr/bin/timeout 5 /usr/bin/stat "$MOUNTPOINT_M/." \
        >/dev/null 2>&1; then
        log "NFS mount is healthy and responding"
        exit 0
    else
        # Mount is stale; unmount it before retrying
        log "NFS mount is stale; lazily unmounting"
        /usr/bin/umount -l "$MOUNTPOINT_M" >> "$LOGFILE" 2>&1
        sleep 2
    fi
    if /usr/bin/timeout 5 /usr/bin/stat "$MOUNTPOINT_N/." \
        >/dev/null 2>&1; then
        log "NFS mount is healthy and responding"
        exit 0
    else
        # Mount is stale; unmount it before retrying
        log "NFS mount is stale; lazily unmounting"
        /usr/bin/umount -l "$MOUNTPOINT_N" >> "$LOGFILE" 2>&1
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

    if /usr/bin/timeout -k 2 20 /usr/bin/mount "$MOUNTPOINT_M" \
        >> "$LOGFILE" 2>&1; then
        log "Mount succeeded"
    else
        log "Mount failed or timed out"
    fi
    if /usr/bin/timeout -k 2 20 /usr/bin/mount "$MOUNTPOINT_N" \
        >> "$LOGFILE" 2>&1; then
        log "Mount succeeded"
    else
        log "Mount failed or timed out"
    fi
fi

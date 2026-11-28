#!/usr/bin/env bash
set -Eeuo pipefail

EXPORT_PATH="/var/home/mshalom/shared"
EXPORT_NET="10.0.0.0/24"
EXPORT_OPTIONS="rw,sync,no_subtree_check,fsid=0"
EXPORTS_FILE="/etc/exports"

if (( EUID != 0 )); then
    echo "Run as root: sudo $0" >&2
    exit 1
fi

if ! command -v rum >/dev/null 2>&1; then
    echo "The 'rum' package manager was not found." >&2
    exit 1
fi

echo "Installing NFS utilities..."
rum install nfs-utils

echo "Creating export directory..."
mkdir -p "$EXPORT_PATH"

echo "Configuring $EXPORTS_FILE..."
touch "$EXPORTS_FILE"

# Replace an existing entry for this path, or append one.
tmp_file=$(mktemp)
awk -v path="$EXPORT_PATH" '$1 != path' "$EXPORTS_FILE" > "$tmp_file"
printf '%s %s(%s)\n' "$EXPORT_PATH" "$EXPORT_NET" "$EXPORT_OPTIONS" >> "$tmp_file"
cat "$tmp_file" > "$EXPORTS_FILE"
rm -f "$tmp_file"

echo "Enabling and starting NFS..."
systemctl enable --now nfs-server.service
exportfs -rav

if command -v firewall-cmd >/dev/null 2>&1 &&
   systemctl is-active --quiet firewalld; then
    echo "Allowing NFS through firewalld..."
    firewall-cmd --permanent --add-service=nfs
    firewall-cmd --reload
else
    echo "firewalld is not active; skipping firewall changes."
fi

echo
echo "Active export:"
exportfs -v | grep -F "$EXPORT_PATH" || true

echo
echo "Client mount command:"
echo "  sudo mount -t nfs -o vers=4 server.lan:/ /mnt/shared"

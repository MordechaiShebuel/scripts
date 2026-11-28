#!/bin/sh
# setup_server_file_share
# Sets up NFS server on a Devuan (runit) box to share /home/media/shared
# Usage: sudo ./setup_server_file_share

[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
set -e

EXPORT_PATH="/home/media/shared"
EXPORT_NET="10.0.0.0/24"
NFS_THREADS=8
SERVICE_NAME="nfsd"

echo "=== NFS Server Setup ==="

# 1. Ensure nfs-kernel-server is installed
if ! dpkg -s nfs-kernel-server >/dev/null 2>&1; then
    echo "Installing nfs-kernel-server..."
    apt install -y nfs-kernel-server
fi

# 2. Create export directory if it doesn't exist
if [ ! -d "$EXPORT_PATH" ]; then
    echo "Creating $EXPORT_PATH"
    mkdir -p "$EXPORT_PATH"
fi

# 3. Configure /etc/exports
echo "Configuring /etc/exports..."
if ! grep -q "^$EXPORT_PATH" /etc/exports 2>/dev/null; then
    echo "$EXPORT_PATH $EXPORT_NET(rw,sync,no_subtree_check,fsid=0)" >> /etc/exports
else
    # Update existing line
    sed -i "\|^$EXPORT_PATH|d" /etc/exports
    echo "$EXPORT_PATH $EXPORT_NET(rw,sync,no_subtree_check,fsid=0)" >> /etc/exports
fi

# 4. Create runit service
echo "Setting up runit service..."
mkdir -p "/etc/sv/$SERVICE_NAME"

cat > "/etc/sv/$SERVICE_NAME/run" << EOF
#!/bin/sh
exec 2>&1
modprobe nfsd
mount -t nfsd nfsd /proc/fs/nfsd 2>/dev/null || true
/usr/sbin/rpc.nfsd $NFS_THREADS
exportfs -ra
exec /usr/sbin/rpc.mountd
EOF
chmod +x "/etc/sv/$SERVICE_NAME/run"

# 5. Enable the service
if [ ! -e "/etc/service/$SERVICE_NAME" ]; then
    ln -s "/etc/sv/$SERVICE_NAME" "/etc/service/$SERVICE_NAME"
    echo "Service enabled: $SERVICE_NAME"
fi

# 6. Start/restart
echo "Starting $SERVICE_NAME..."
if [ -e "/etc/service/$SERVICE_NAME" ]; then
    sv restart "$SERVICE_NAME" 2>/dev/null || sv start "$SERVICE_NAME"
else
    # Service dir exists but not linked yet (shouldn't happen, but just in case)
    sv up "/etc/sv/$SERVICE_NAME"
fi

# 7. Verify
echo ""
echo "=== Verification ==="
sleep 1

echo -n "nfsd port 2049: "
if ss -tlnp | grep -q ":2049 "; then
    echo "OK"
else
    echo "FAIL"
fi

echo -n "mountd registered: "
if rpcinfo -p 2>/dev/null | grep -q "mountd"; then
    echo "OK"
else
    echo "FAIL"
fi

echo -n "Export active: "
if exportfs -v 2>/dev/null | grep -q "$EXPORT_PATH"; then
    echo "OK"
else
    echo "FAIL"
fi

echo ""
echo "Done. Test from a client:"
echo "  sudo mount -t nfs -o vers=3 $(hostname -I | awk '{print $1}'):$(echo "$EXPORT_PATH" | sed 's|^/||') /mnt/test"

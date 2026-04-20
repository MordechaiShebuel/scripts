#!/bin/sh
# install-jellyfin-openrc.sh
# Usage:
#   sudo MEDIA_DIR=/path/to/media ./install-jellyfin-openrc.sh
# or edit the MEDIA_DIR below.

set -eu

# --- Configuration (edit or override via env) ---
IMAGE="docker.io/jellyfin/jellyfin:latest"
CONTAINER_NAME="jellyfin"
SERVICE_NAME="jellyfin-podman"
JELLYFIN_HTTP_PORT=8096
JELLYFIN_HTTPS_PORT=8920
MEDIA_DIR="${MEDIA_DIR:-/srv/media}"   # <--- set this or export MEDIA_DIR before running
CONFIG_DIR="${CONFIG_DIR:-/var/lib/jellyfin/config}"
CACHE_DIR="${CACHE_DIR:-/var/lib/jellyfin/cache}"
PODMAN_BIN="${PODMAN_BIN:-/usr/bin/podman}"
OPENRC_INIT_DIR="${OPENRC_INIT_DIR:-/etc/init.d}"

# --- Basic checks ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root or via sudo."
  exit 1
fi

if [ ! -x "$PODMAN_BIN" ]; then
  echo "podman not found at $PODMAN_BIN. Install podman first."
  exit 1
fi

# Ensure media dir exists
mkdir -p "$MEDIA_DIR" "$CONFIG_DIR" "$CACHE_DIR"
chown -R 1000:1000 "$MEDIA_DIR" "$CONFIG_DIR" "$CACHE_DIR" || true

# --- Pull image ---
echo "Pulling Jellyfin image: $IMAGE"
$PODMAN_BIN pull "$IMAGE"

# --- Create container if not exists ---
if $PODMAN_BIN container exists "$CONTAINER_NAME"; then
  echo "Container '$CONTAINER_NAME' already exists."
else
  echo "Creating container '$CONTAINER_NAME' with port mappings (LAN-only)."
  $PODMAN_BIN create \
    --name "$CONTAINER_NAME" \
    --restart=always \
    -p ${JELLYFIN_HTTP_PORT}:8096/tcp \
    -p ${JELLYFIN_HTTPS_PORT}:8920/tcp \
    -v "${CONFIG_DIR}":/config \
    -v "${CACHE_DIR}":/cache \
    -v "${MEDIA_DIR}":/media:ro \
    "$IMAGE"
  echo "Container created."
fi

# --- Create OpenRC service script ---
INIT_PATH="${OPENRC_INIT_DIR}/${SERVICE_NAME}"
cat > "$INIT_PATH" <<'EOF'
#!/sbin/openrc-run
description="Manage Jellyfin (Podman container)"

name="jellyfin-podman"
command="/usr/bin/podman"
command_args="start -a jellyfin"
pidfile="/run/${RC_SVCNAME}.pid"

depend() {
  need localmount
  use net
}

start_pre() {
  # Ensure container exists (no-op if already present)
  /usr/bin/podman container exists jellyfin || /usr/bin/podman create \
    --name jellyfin \
    --restart=always \
    -p 8096:8096/tcp \
    -p 8920:8920/tcp \
    -v /var/lib/jellyfin/config:/config \
    -v /var/lib/jellyfin/cache:/cache \
    -v /srv/media:/media:ro \
    docker.io/jellyfin/jellyfin:latest
}
EOF

chmod +x "$INIT_PATH"
echo "OpenRC service script written to $INIT_PATH"

# --- Enable service in default runlevel and start it ---
rc-update add "$SERVICE_NAME" default >/dev/null 2>&1 || true
rc-service "$SERVICE_NAME" start || {
  echo "Warning: starting service failed; try 'rc-service $SERVICE_NAME start' manually."
}

# --- Output OPNSense / firewall guidance (LAN-only) ---
HOST_IP_HINT="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
echo
echo "Jellyfin should now be created and started (container name: $CONTAINER_NAME)."
echo
echo "Access (LAN): http://${HOST_IP_HINT:-<host-ip>}:${JELLYFIN_HTTP_PORT}  (or https on port ${JELLYFIN_HTTPS_PORT})"
echo
echo "OPNSense firewall instructions (LAN access only):"
echo " - Allow TCP ports ${JELLYFIN_HTTP_PORT} and ${JELLYFIN_HTTPS_PORT} to this host's LAN IP (${HOST_IP_HINT:-<host-ip>})."
echo " - If you manage OPNSense via SSH, you must still set rules in the web UI; OPNSense does not accept firewall rule creation via SSH by default."
echo
echo "If you prefer to open ports automatically via SSH, you can script the OPNSense API calls — this script does not attempt to modify OPNSense."
echo
echo "Variables used:"
echo " MEDIA_DIR=$MEDIA_DIR"
echo " CONFIG_DIR=$CONFIG_DIR"
echo " CACHE_DIR=$CACHE_DIR"
echo
echo "Notes:"
echo " - SELinux is NOT enabled (per your input); no :Z labels used."
echo " - Media is mounted read-only into the container (/media). Adjust permissions if Jellyfin needs write access."
echo " - To change networking (host network mode) replace container create options with '--network host' and remove -p mappings."
echo
echo "To manage container manually:"
echo " $PODMAN_BIN ps -a"
echo " $PODMAN_BIN logs -f $CONTAINER_NAME"
echo " $PODMAN_BIN stop $CONTAINER_NAME"
echo " $PODMAN_BIN start $CONTAINER_NAME"

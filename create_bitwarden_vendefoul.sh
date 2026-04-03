#!/bin/bash
# =============================================================================
# Vaultwarden setup - Rootless Podman + OpenRC + Bridge Network
# For Vendefoul (10.0.0.3) with other services (Pi-hole, Nomad/Plex, etc.)
# =============================================================================

set -euo pipefail

echo "=== Vaultwarden private server setup (Podman rootless + Bridge Network) ==="

# ================== Configuration ==================
SERVICE_NAME="vaultwarden"
USER="vaultwarden"
DATA_DIR="/var/lib/${SERVICE_NAME}"
ENV_FILE="${DATA_DIR}/env"
NETWORK_NAME="vaultwarden-bridge"
HOST_IP="10.0.0.3"          # Your Vendefoul machine IP
PORT_HOST=8081
DOMAIN="http://${HOST_IP}:${PORT_HOST}"

ADMIN_TOKEN_FILE="${DATA_DIR}/admin_token"
# ==================================================

# 1. Prerequisites
if ! command -v podman >/dev/null 2>&1; then
    echo "❌ Podman not found. Install it first."
    exit 1
fi

# 2. Create dedicated user (if missing)
if ! id "${USER}" >/dev/null 2>&1; then
    echo "→ Creating system user '${USER}' ..."
    if command -v useradd >/dev/null 2>&1; then
        useradd -r -s /sbin/nologin -d "${DATA_DIR}" -m "${USER}"
    else
        adduser -S -H -s /sbin/nologin -D "${USER}"
    fi
fi

# 3. User namespaces (subuid/subgid)
if ! grep -q "^${USER}:" /etc/subuid 2>/dev/null; then
    echo "→ Configuring user namespaces ..."
    echo "${USER}:100000:65536" >> /etc/subuid
    echo "${USER}:100000:65536" >> /etc/subgid
fi

# 4. Data directory & permissions
mkdir -p "${DATA_DIR}/data"
chown -R "${USER}:${USER}" "${DATA_DIR}"
chmod 700 "${DATA_DIR}"

# Generate ADMIN_TOKEN (once)
if [[ ! -f "${ADMIN_TOKEN_FILE}" ]]; then
    echo "→ Generating ADMIN_TOKEN ..."
    openssl rand -hex 32 > "${ADMIN_TOKEN_FILE}"
    chmod 600 "${ADMIN_TOKEN_FILE}"
fi
ADMIN_TOKEN=$(cat "${ADMIN_TOKEN_FILE}")

# 5. Environment file
cat > "${ENV_FILE}" <<EOF
DOMAIN=${DOMAIN}
SIGNUPS_ALLOWED=false
WEBSOCKET_ENABLED=true
ADMIN_TOKEN=${ADMIN_TOKEN}
# Add other settings here (e.g. ROCKET_ADDRESS=0.0.0.0 is default)
EOF
chown "${USER}:${USER}" "${ENV_FILE}"
chmod 600 "${ENV_FILE}"

echo "→ Configuration:"
echo "   Access URL : ${DOMAIN}"
echo "   Bridge net : ${NETWORK_NAME}"
echo "   Host IP    : ${HOST_IP}:${PORT_HOST}"

# 6. Create custom bridge network (as the service user)
echo "→ Creating bridge network '${NETWORK_NAME}' ..."
su -s /bin/sh -c "podman network create ${NETWORK_NAME} || true" "${USER}"

# 7. Pull image
echo "→ Pulling vaultwarden/server:latest ..."
su -s /bin/sh -c "podman pull vaultwarden/server:latest" "${USER}"

# 8. OpenRC init script (bridge-aware)
INIT_SCRIPT="/etc/init.d/${SERVICE_NAME}"
cat > "${INIT_SCRIPT}" <<EOF
#!/sbin/openrc-run

description="Vaultwarden (rootless Podman on bridge network)"
command="/usr/bin/podman"
command_user="vaultwarden"
pidfile="/run/vaultwarden.pid"

start() {
    ebegin "Starting Vaultwarden on bridge ${NETWORK_NAME}"

    su -s /bin/sh -c "\${command} run \
        --name vaultwarden \
        --rm \
        --replace \
        -d \
        --network ${NETWORK_NAME} \
        --volume ${DATA_DIR}/data:/data:z \
        --env-file ${ENV_FILE} \
        -p ${HOST_IP}:${PORT_HOST} \
        vaultwarden/server:latest" \${command_user}

    eend \$?
}

stop() {
    ebegin "Stopping Vaultwarden"
    su -s /bin/sh -c "\${command} stop vaultwarden" \${command_user} 2>/dev/null || true
    eend 0
}

status() {
    su -s /bin/sh -c "\${command} ps --filter name=vaultwarden" \${command_user}
}
EOF

chmod +x "${INIT_SCRIPT}"

# 9. Enable & start
rc-update add "${SERVICE_NAME}" default
rc-service "${SERVICE_NAME}" restart

echo ""
echo "✅ Vaultwarden is running on the bridge network!"
echo ""
echo "Access from LAN: ${DOMAIN}"
echo "Admin panel   : ${DOMAIN}/admin"
echo ""
echo "Useful commands:"
echo "   rc-service vaultwarden restart"
echo "   sudo -u vaultwarden podman logs -f vaultwarden"
echo "   sudo -u vaultwarden podman network inspect ${NETWORK_NAME}"
echo ""
echo "To let other containers communicate with Vaultwarden:"
echo "   Run them with --network ${NETWORK_NAME} and use hostname 'vaultwarden'"
echo ""
echo "Recommendation: Put a reverse proxy (Caddy/Nginx) on the same bridge network"
echo "for clean HTTPS and a nice domain (e.g. vault.yourlan.local)."
echo ""
echo "Your other services (Pi-hole at 10.0.0.2, Nomad/Plex at 10.0.0.3) can reach it via ${HOST_IP}:8081."

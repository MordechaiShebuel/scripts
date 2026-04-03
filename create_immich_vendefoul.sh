#!/bin/bash
#VARIABLES
IMMICHDIR="/var/lib/immich/library" # (or your preferred path on a large disk)

# 1. Setup podman and podman-compose


# 2. Check and install requirements
echo "→ Checking podman, curl and git"
NEEDS_INSTALL=()
if ! command -v git >/dev/null 2>&1; then
    NEEDS_INSTALL+=("git")
fi
if ! command -v podman >/dev/null 2>&1; then
    NEEDS_INSTALL+=("podman")
fi
if ! command -v curl >/dev/null 2>&1; then
    NEEDS_INSTALL+=("curl")
fi

if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
    echo "   Installing: ${NEEDS_INSTALL[*]}"
    sudo apt update
    sudo apt install -y "${NEEDS_INSTALL[@]}"
else
    echo "   ✅ podman and curl are already installed"
fi

rc-update add podman
rc-service podman start

# Optional: Allow a non-root user to run podman (rootless) - add your user
# usermod -aG podman $USER   # then log out/in

# 2. Download and prepare Immich
sudo mkdir -p /opt/immich
cd /opt/immich

# Download official files
sudo wget -O docker-compose.yml https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
sudo wget -O .env https://github.com/immich-app/immich/releases/latest/download/example.env

# Edit .env
sudo nano .env
# Set UPLOAD_LOCATION=/var/lib/immich/library (or your preferred path on a large disk)
# Set a strong DB_PASSWORD
# Adjust IMMICH_PORT=2283 if needed
# Other settings (Redis, Postgres, etc.) can stay default for now

sudo mkdir -p $"IMMICHDIR" /var/lib/immich/postgres /var/lib/immich/redis
sudo chown -R 911:911 /var/lib/immich

# 3. OpenRC Init script for Immich
sudo bash -c 'cat > /etc/init.d/immich << "EOF"
#!/sbin/openrc-run

description="Immich self-hosted photo and video server (Podman Compose)"
supervisor="supervise-daemon"

command="/usr/bin/podman-compose"
command_args="-f /opt/immich/docker-compose.yml up"
command_background=true
pidfile="/run/${RC_SVCNAME}.pid"

extra_commands="logs pull down"

depend() {
    need podman
    use net
}

start_pre() {
    cd /opt/immich || return 1
    ebegin "Pulling latest Immich images with Podman"
    podman-compose -f /opt/immich/docker-compose.yml pull --quiet || eend 1
    eend 0
}

stop() {
    ebegin "Stopping Immich"
    cd /opt/immich
    podman-compose -f /opt/immich/docker-compose.yml down
    eend $?
}

restart() {
    stop
    start
}

logs() {
    cd /opt/immich
    podman-compose -f /opt/immich/docker-compose.yml logs -f
}

pull() {
    cd /opt/immich
    podman-compose -f /opt/immich/docker-compose.yml pull
}

down() {
    cd /opt/immich
    podman-compose -f /opt/immich/docker-compose.yml down -v
}
EOF'

sudo chmod +x /etc/init.d/immich

#4 Enable and Start the Service
sudo rc-update add immich default
sudo rc-service immich start

# Check the Status:
sudo rc-service immich status
sudo rc-service immich logs

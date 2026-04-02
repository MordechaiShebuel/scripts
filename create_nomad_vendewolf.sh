#!/bin/bash
set -euo pipefail

echo "=== Project N.O.M.A.D. - Podman + OpenRC Setup (Systemd-free) ==="

# 1. Setup aliases
echo "→ Setting up docker → podman alias"
if [[ "$SHELL" == *zsh* ]]; then
    PROFILE="$HOME/.zshrc"
else
    PROFILE="$HOME/.bashrc"
fi

if ! grep -q "alias docker=podman" "$PROFILE" 2>/dev/null; then
    echo 'alias docker=podman' >> "$PROFILE"
    echo "   Alias added to $PROFILE"
fi

if [ ! -f /usr/local/bin/docker ]; then
    sudo ln -sf /usr/bin/podman /usr/local/bin/docker
    echo "   System-wide docker symlink created"
fi

source "$PROFILE" 2>/dev/null || true

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

# Install podman-compose (needed for the stack)
if ! command -v podman-compose >/dev/null 2>&1; then
    echo "   Installing podman-compose"
    sudo apt install -y python3-pip
    pip3 install --break-system-packages podman-compose
fi

# 3. Setup Podman socket (OpenRC)
echo "→ Setting up Podman socket service"
sudo mkdir -p /etc/init.d

sudo bash -c 'cat > /etc/init.d/podman-socket << "EOF"
#!/sbin/openrc-run
name="podman-socket"
description="Podman API socket for Project N.O.M.A.D."
command="/usr/bin/podman"
command_args="system service --time=0 unix:///run/podman/podman.sock"
command_background=true
pidfile="/run/${RC_SVCNAME}.pid"

depend() {
    need networking
    after networking
}

start_pre() {
    mkdir -p /run/podman
    chmod 755 /run/podman
}
EOF'

sudo chmod +x /etc/init.d/podman-socket
sudo rc-update add podman-socket default
sudo rc-service podman-socket restart || echo "   ⚠️ Podman socket started (check with rc-service podman-socket status)"

# 4 & 5. Remove old script + download fresh install_nomad.sh
echo "→ Downloading fresh install_nomad.sh"
cd /tmp
rm -f install_nomad.sh

curl -fsSL https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/install_nomad.sh -o install_nomad.sh

if [ ! -s install_nomad.sh ]; then
    echo "❌ Failed to download install_nomad.sh"
    exit 1
fi

# 6. Replace the entire ensure_docker_installed function with a clean Podman version
python patch_nomad.py

echo "Function patched out"

# 7. Run the modified installer
echo "→ Running the modified Project N.O.M.A.D. installer"
sudo bash patched_install_nomad.sh

# 8. Create OpenRC service for the stack
echo "→ Creating OpenRC service for Project N.O.M.A.D."
sudo bash -c 'cat > /etc/init.d/project-nomad << "EOF"
#!/sbin/openrc-run

name="project-nomad"
description="Project N.O.M.A.D. stack via podman-compose"

command="/usr/local/bin/podman-compose"
command_args="-f /opt/project-nomad/compose.yml up -d --remove-orphans"
command_background=false

depend() {
    need networking podman-socket
    after podman-socket
}

start_pre() {
    mkdir -p /opt/project-nomad
}

stop() {
    cd /opt/project-nomad
    /usr/local/bin/podman-compose -f compose.yml down
}
EOF'

sudo chmod +x /etc/init.d/project-nomad
sudo rc-update add project-nomad default

IFS=$'\n' ip_array=($(ip addr show eth0 | awk '/inet/ {print $2}' | cut -d/ -f1))

echo "=== Setup completed! ==="
echo ""
echo "Next steps:"
echo "1. cd /opt/project-nomad"
echo "2. Review/edit compose.yml (set strong APP_KEY, correct URLs, passwords, etc.)"
echo "3. Test the stack:   sudo rc-service project-nomad start"
echo "   or manually:     podman-compose -f /opt/project-nomad/compose.yml up -d"
echo ""
echo "Useful commands:"
echo "   podman ps"
echo "   rc-service project-nomad status"
echo "   rc-service project-nomad restart"
echo "   rc-service podman-socket status"
echo ""
echo "The dashboard should be available at http://$"ip_array[1]":8080 (check compose.yml for the exact port)"
echo ""
echo "If you see errors during the first start, paste them here and we’ll adjust the compose file or OpenRC service."

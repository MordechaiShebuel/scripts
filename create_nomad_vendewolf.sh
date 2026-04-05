#!/bin/bash
# Version 5
set -euo pipefail

echo "=== Project N.O.M.A.D. - Podman + OpenRC Setup with Dedicated Bridge ==="

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
for pkg in git podman curl; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        NEEDS_INSTALL+=("$pkg")
    fi
done

if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
    echo "   Installing: ${NEEDS_INSTALL[*]}"
    sudo apt update
    sudo apt install -y "${NEEDS_INSTALL[@]}"
else
    echo "   ✅ Requirements already installed"
fi

# Install podman-compose
if ! command -v podman-compose >/dev/null 2>&1; then
    echo "   Installing podman-compose"
    sudo apt install -y python3-pip
    pip3 install --break-system-packages podman-compose
fi

# 3. Setup Podman socket
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
sudo rc-service podman-socket restart || echo "   ⚠️ Podman socket started (check manually if needed)"

# 4. Create dedicated bridge for Project N.O.M.A.D. (bridged networking)
echo "→ Creating dedicated bridge br-nomad for the stack (own IP on LAN)"
sudo apt install -y bridge-utils

# Detect main interface (first one with IP, skipping lo)
MAIN_IFACE=$(ip -4 addr show | awk '/inet/ && !/127.0.0.1/ {print $NF; exit}')

if [ -z "$MAIN_IFACE" ]; then
    echo "⚠️ Could not detect main network interface. Using eth0 as fallback."
    MAIN_IFACE="eth0"
fi

echo "   Main interface detected: $MAIN_IFACE"

# Create bridge config (persistent via /etc/network/interfaces)
sudo bash -c "cat >> /etc/network/interfaces << EOF

# Bridge for Project N.O.M.A.D. - assign static IP here (e.g. 10.0.0.3/24)
auto br-nomad
iface br-nomad inet static
    address 10.0.0.3/24          # <<< CHANGE THIS TO YOUR DESIRED STATIC IP
    gateway 10.0.0.1              # Your router
    bridge_ports none             # We attach containers via podman network / compose
    bridge_stp off
    bridge_fd 0
    up ip link set br-nomad up
EOF"

sudo ip link add br-nomad type bridge 2>/dev/null || true
sudo ip link set br-nomad up 2>/dev/null || true

sudo rc-update add networking default
sudo rc-service networking restart || echo "   Networking restarted"

# 5. Download + patch installer (your python patch_nomad.py)
echo "→ Downloading fresh install_nomad.sh"
cd /tmp
rm -f install_nomad.sh patched_install_nomad.sh

curl -fsSL https://raw.githubusercontent.com/Crosstalk-Solutions/project-nomad/refs/heads/main/install/install_nomad.sh -o install_nomad.sh

if [ ! -s install_nomad.sh ]; then
    echo "❌ Failed to download install_nomad.sh"
    exit 1
fi

python3 patch_nomad.py   # python patch script (assumes it creates patched_install_nomad.sh)

echo "   Installer patched"

# 6. Run the modified installer
echo "→ Running the modified Project N.O.M.A.D. installer"
sudo bash patched_install_nomad.sh

# 7. Create OpenRC service for the stack
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
    /usr/local/bin/podman-compose -f compose.yml down || true
}
EOF'

sudo chmod +x /etc/init.d/project-nomad
sudo rc-update add project-nomad default

# Get bridge IP for display
BRIDGE_IP=$(ip -4 addr show br-nomad 2>/dev/null | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n1)

echo "=== Setup completed! ==="
echo ""
echo "Bridge Status:"
echo "   Bridge: br-nomad"
echo "   IP:     ${BRIDGE_IP}:-Not yet assigned (edit /etc/network/interfaces)"
echo ""
echo "Next steps:"
echo "1. Edit the bridge IP if needed:"
echo "   sudo nano /etc/network/interfaces   # change address 10.0.0.50/24"
echo "   sudo rc-service networking restart"
echo ""
echo "2. cd /opt/project-nomad"
echo "3. Review/edit compose.yml (set strong APP_KEY, correct URLs, passwords, etc.)"
echo "   → Consider adding networks: section with external bridge if possible"
echo ""
echo "4. Test the stack:   sudo rc-service project-nomad start"
echo ""
echo "Dashboard should be reachable at: http://${BRIDGE_IP}:8080"
echo ""
echo "Useful commands:"
echo "   podman ps"
echo "   rc-service project-nomad status"
echo "   rc-service podman-socket status"
echo ""
echo "If the compose file needs bridge network configuration or you get port/IP issues, paste the error."

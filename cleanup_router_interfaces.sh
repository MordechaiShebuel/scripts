#!/bin/bash
# =============================================================================
# OPNsense & Podman Environment Fix
# =============================================================================

# 1. Create the Podman OpenRC Service
echo "1. Configuring Podman OpenRC service..."
sudo bash -c 'cat > /etc/init.d/podman-socket << "EOF"
#!/sbin/openrc-run
name="podman-socket"
description="Podman API socket"
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

# 2. Fix the Networking Conflict (The "Double IP" Issue)
echo "2. Fixing bridge networking..."

# Clear the physical IP so it stops fighting the bridge
sudo ip addr flush dev eth0
sudo ip link set eth0 master br-wan 2>/dev/null || true

# 3. Update the permanent config so it stays fixed after reboot
sudo bash -c 'cat > /etc/network/interfaces << "EOF"
# Physical WAN
iface eth0 inet manual

# Bridge WAN
auto br-wan
iface br-wan inet dhcp
    bridge_ports eth0
    bridge_stp off
    bridge_fd 0

# Bridge LAN (Keep your internal setup here)
auto br-lan
iface br-lan inet manual
    bridge_ports enx803f5d048742
    bridge_stp off
    bridge_fd 0
EOF'

# 4. Apply changes and restart VM
echo "3. Restarting network and OPNsense..."
sudo ifdown br-wan && sudo ifup br-wan
sudo virsh reboot opnsense

echo "Done! Check br-wan IP with: ip addr show br-wan"

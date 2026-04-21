#!/bin/bash
# =============================================================================
# Pi-hole Setup on Vendefoul Host (10.0.0.2)
# Run AFTER OPNsense is installed and LAN is at 10.0.0.1
# =============================================================================

set -euo pipefail

echo "=== Pi-hole Setup on Vendefoul Host (IP 10.0.0.2) ==="

# 1. Add static IP 10.0.0.2 to the LAN bridge
echo "1. Adding host IP 10.0.0.2 on br-lan..."
cat >> /etc/network/interfaces <<EOF

# Host management IP for Pi-hole (on OPNsense LAN)
auto br-lan:1
iface br-lan:1 inet static
    address 10.0.0.2
    netmask 255.255.255.0
EOF

ifup br-lan:1 || true

echo "   Host IP configured: 10.0.0.2"

# 2. Install Pi-hole
echo "2. Running Pi-hole installer..."
curl -sSL https://install.pi-hole.net | bash

# 3. Enable services on boot (OpenRC)
echo "3. Enabling Pi-hole services..."
rc-update add lighttpd default 2>/dev/null || true
rc-update add pihole-FTL default 2>/dev/null || true

rc-service lighttpd restart 2>/dev/null || true
rc-service pihole-FTL restart 2>/dev/null || true

echo ""
echo "=== Pi-hole Installation Complete! ==="
echo ""
echo "Pi-hole web interface: http://10.0.0.2/admin"
echo ""
echo "Next steps in OPNsense web GUI (https://10.0.0.1):"
echo "   1. Go to Services → DHCPv4"
echo "   2. Set 'DNS servers' to: 10.0.0.2"
echo "   3. (Optional but recommended) Enable DHCP server if not already:"
echo "        Range: 10.0.0.100 – 10.0.0.250"
echo "        Gateway: 10.0.0.1"
echo "   4. Save & Apply"
echo ""
echo "Your internal clients will now get 10.x.x.x addresses and automatic DNS ad-blocking via Pi-hole."
echo ""
echo "You can manage everything through the OPNsense web GUI for routing/firewall and Pi-hole dashboard for blocking."

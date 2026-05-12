# Install missing DHCP client (Devuan/Vendefoul)
# version 2

apt-get update
apt-get install -y isc-dhcp-client net-tools

# Restore original network config
cp /etc/network/interfaces.bak /etc/network/interfaces 2>/dev/null || true

# Clean up any broken bridges
ifdown --force br-wan br-lan 2>/dev/null || true
ip link set br-wan down 2>/dev/null || true
ip link set br-lan down 2>/dev/null || true
brctl delbr br-wan 2>/dev/null || true
brctl delbr br-lan 2>/dev/null || true

# Bring back eth0 with DHCP
ifdown --force eth0 2>/dev/null || true
ip addr flush dev eth0
ip link set eth0 up
dhclient eth0

echo "Waiting for DHCP lease from 192.168.1.1..."
sleep 8
ip addr show eth0 | grep "inet "
ping -c 3 8.8.8.8 && echo "✅ Internet restored!" || echo "Still no ping — run dhclient eth0 again"

#!/bin/bash
# =============================================================================
# Vendefoul OpenRC + OPNsense VM Setup - Combined Safe Script
# eth0          = WAN (connected to 192.168.1.1)
# enx803f5d048742 = LAN (internal 10.x.x.x network)
#
# Download + checksum check happens FIRST on original network.
# Bridges and VM creation only happen if checksum is valid.
# =============================================================================
# Version 5.4

set -euo pipefail

echo "=== Vendefoul OPNsense Router Setup (Safe Combined Version) ==="

OPNVersion="26.1.2"
OPNVariant="nano"
OPNImage="OPNsense-${OPNVersion}-${OPNVariant}-amd64.img"
WAN_IF="eth0"
LAN_IF="enx803f5d048742"
IMAGE_DIR="/var/lib/libvirt/images"
BZ2_FILE="${IMAGE_DIR}/${OPNImage}.bz2"
IMG_FILE="${IMAGE_DIR}/${OPNImage}"

EXPECTED_SHA256="24ae4c3f178bcc53475ab0b2ec50a7b06e9541f5080c156e5aa967c12a8d343e"

# 0. Clean up prior attempts
echo "0. Removing BZ2 or image files of prior install attempts"
mkdir -p "$IMAGE_DIR"
cd "$IMAGE_DIR"

rm -rf $BZ2_FILE
rm -rf $IMG_FILE

# 1. Install required packages (if not already present)
echo "1. Installing KVM/libvirt and tools..."
./update
# apt-get install -y -qq qemu-kvm libvirt-daemon-system libvirt-clients virtinst bridge-utils curl net-tools isc-dhcp-client
# Check and install requirements
echo "→ Checking OPNSense App Reqs"
for pkg in qemu-kvm libvirt-daemon-system libvirt-clients virtinst bridge-utils curl net-tools isc-dhcp-client; do
    if ! command -v "$pkg" >/dev/null 2>&1; then
        echo "   Installing: ${pkg}"
        ./install.sh
        #NEEDS_INSTALL+=("$pkg")
    else
        echo "   ✅ ${pkg} Requirements already installed"
    fi
done

rc-update add libvirtd default
rc-service libvirtd start || true

# 2. Download OPNsense image (on original network)

if [ ! -f "$IMG_FILE" ]; then
    echo "2. Downloading OPNsense 26.1.2 Nano image (~520 MB)..."
    curl -L --retry 10 --retry-delay 20 --continue-at - --max-time 3600 \
         -o "$BZ2_FILE" \
         "https://pkg.opnsense.org/releases/26.1.2/${OPNImage}.bz2"
else
    echo "2. Image already decompressed — skipping download."
fi

# 3. Verify checksum of the .bz2 file
echo "3. Verifying SHA256 checksum of downloaded file..."
if [ -f "$BZ2_FILE" ]; then
    ACTUAL_SHA256=$(sha256sum "$BZ2_FILE" | awk '{print $1}')

    if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
        echo "❌ CHECKSUM MISMATCH!"
        echo "Expected:  $EXPECTED_SHA256"
        echo "Actual:    $ACTUAL_SHA256"
        echo ""
        echo "The download is corrupted or incomplete."
        echo "Please run this script again — it will resume the download."
        exit 1
    else
        echo "✅ Checksum verification passed!"
    fi
else
    echo "❌ .bz2 file not found after download."
    exit 1
fi

# 4. Decompress if needed
if [ ! -f "$IMG_FILE" ]; then
    echo "4. Decompressing image..."
    bunzip2 -v -f "$BZ2_FILE"
fi

# 5. Set up bridges (only if we reached here = checksum OK)
# 5. Set up bridges (only if we reached here = checksum OK)
echo "5. Configuring Linux bridges..."
cp /etc/network/interfaces /etc/network/interfaces.bak 2>/dev/null || true

# Write the config ONCE with eth0 explicitly set to manual
cat > /etc/network/interfaces <<EOF
# Physical WAN
auto $WAN_IF
iface $WAN_IF inet manual

# Bridge WAN (Gets the IP)
auto br-wan
iface br-wan inet dhcp
    bridge_ports $WAN_IF
    bridge_stp off
    bridge_fd 0

# Physical LAN
auto $LAN_IF
iface $LAN_IF inet manual

# Bridge LAN
auto br-lan
iface br-lan inet manual
    bridge_ports $LAN_IF
    bridge_stp off
    bridge_fd 0
EOF

echo "   Cleaning up physical interface IPs..."
# Flush the physical interfaces to ensure they don't hold onto old IPs
ip addr flush dev "$WAN_IF" || true
ip addr flush dev "$LAN_IF" || true

echo "   Bringing bridges up..."
# Force restart the networking service or just the specific interfaces
ifdown --force br-wan br-lan "$WAN_IF" "$LAN_IF" 2>/dev/null || true
ifup br-wan br-lan "$WAN_IF" "$LAN_IF"

echo "   Waiting for DHCP lease on br-wan..."
for i in {1..25}; do
    if ip addr show br-wan | grep -q "inet "; then
        echo "   ✅ br-wan has IP: $(ip addr show br-wan | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
        break
    fi
    sleep 3
done

# Final check: Ensure the physical WAN hasn't snuck an IP back on
if ip addr show "$WAN_IF" | grep -q "inet "; then
    echo "   ⚠️ Warning: $WAN_IF still has an IP. Flushing again..."
    ip addr flush dev "$WAN_IF"
fi


# 6. Enable IP forwarding
echo "6. Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-forwarding.conf
sysctl -p /etc/sysctl.d/99-forwarding.conf

# 6.5 Convert image
sudo qemu-img convert -f raw -O qcow2 "OPNsense-${OPNVersion}-nano-amd64.img" opnsense.qcow2
sudo qemu-img resize opnsense.qcow2 8G # you may choose another disk size, 8G is the minimum
sudo rm -rf $IMG_FILE

# 7. Create the OPNsense VM
echo "7. Creating OPNsense VM (2 vCPU, 4 GB RAM)..."
virt-install \
  --name opnsense \
  --os-variant freebsd14.0 \
  --memory 4096 \
  --vcpus 2 \
  --disk path="${IMAGE_DIR}/opnsense.qcow2",format=raw,bus=virtio \
  --network bridge=br-wan,model=virtio \
  --network bridge=br-lan,model=virtio \
  --graphics none \
  --console pty,target_type=serial \
  --boot hd \
  --import \
  --autostart || echo "   VM already exists (safe to continue)"

echo ""
echo "=== SETUP COMPLETE! ==="
echo ""
echo "Next steps:"
echo "   virsh start opnsense"
echo "   virsh console opnsense     (exit console with Ctrl + ])"
echo ""
echo "In the OPNsense installer:"
echo "   • First NIC  → WAN (DHCP from 192.168.1.1)"
echo "   • Second NIC → LAN"
echo "   • Set LAN IP: 10.0.0.1 / 24"
echo ""

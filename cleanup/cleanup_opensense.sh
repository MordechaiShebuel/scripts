#!/bin/bash
# =============================================================================
# OPNsense VM Cleanup Script
# This will stop the VM and delete all associated storage files.
# =============================================================================

VM_NAME="opnsense"
IMAGE_DIR="/var/lib/libvirt/images"

echo "=== Starting OPNsense Cleanup ==="

# 1. Force stop the VM if it is running
if virsh list --all | grep -q "$VM_NAME"; then
    echo "1. Stopping VM: $VM_NAME..."
    virsh destroy "$VM_NAME" 2>/dev/null || echo "   VM already stopped."

    # 2. Remove the VM definition and all managed storage
    echo "2. Undefining VM and removing storage volumes..."
    virsh undefine "$VM_NAME" --remove-all-storage --snapshots-metadata --managed-save
else
    echo "   VM '$VM_NAME' not found in virsh. Skipping virsh commands."
fi

# 3. Manually remove any leftover image files in the directory
echo "3. Cleaning up leftover files in $IMAGE_DIR..."
sudo rm -f "${IMAGE_DIR}/opnsense.qcow2"
sudo rm -f "${IMAGE_DIR}"/OPNsense-*-amd64.img*

echo "=== Cleanup Complete! You can now run your install script. ==="

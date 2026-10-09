#!/bin/bash

# Guard: require both arguments
if [ $# -lt 2 ]; then
  echo "Usage: $0 <REMOTE_HOST> <KERNEL_RELEASE>" >&2
  exit 1
fi

KERNEL_RELEASE=$1 # REQUIRED
REMOTE_HOST=$2
ARCH=$3

INSTALL_SCRIPT="$(mktemp)"

cat > "$INSTALL_SCRIPT" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

KERNEL_RELEASE="$1"
ARCH="$2"
echo "Installing ${KERNEL_RELEASE}"
cd /tmp
tar -xzf "kernel-${KERNEL_RELEASE}-${ARCH}.tar.gz"

test -f "arch/x86/boot/bzImage"
test -f "System.map"
test -d "modules/lib/modules/${KERNEL_RELEASE}"

echo "Installing kernel image..."
install -m 0644 \
    "arch/x86/boot/bzImage" \
    "/boot/vmlinuz-${KERNEL_RELEASE}"

install -m 0644 \
    "System.map" \
    "/boot/System.map-${KERNEL_RELEASE}"

echo "Installing modules..."
cp -a \
    "modules/lib/modules/${KERNEL_RELEASE}" \
    "/lib/modules/"

echo "Running depmod..."
depmod "${KERNEL_RELEASE}"

echo "Generating initramfs..."
dracut --force \
    "/boot/initramfs-${KERNEL_RELEASE}.img" \
    "${KERNEL_RELEASE}"

echo "Updating GRUB..."
grub-mkconfig -o /boot/grub/grub.cfg

echo "Kernel installation complete!"
SCRIPT

# If remote host specified, push and install
if [[ -n "$REMOTE_HOST" ]]; then
    echo "Pushing kernel to $REMOTE_HOST..."

    scp "$HOME/tmp/kernel-$KERNEL_RELEASE-$ARCH.tar.gz" "$REMOTE_HOST:/tmp/" || {
        echo "SCP failed to copy kernel tar.gz" >&2
        exit 1
    }
    scp "$INSTALL_SCRIPT" "$REMOTE_HOST:/tmp/install-kernel.sh" || {
        echo "SCP failed to copy install script" >&2
        exit 1
    }

    ssh -tt "$REMOTE_HOST" \
        "sudo bash /tmp/install-kernel.sh '$KERNEL_RELEASE' '$ARCH'
         status=\$?

         if [ \$status -eq 0 ]; then
             if sudo grep -R -F -q '$KERNEL_RELEASE' \
                 /boot/grub/grub.cfg \
                 /boot/grub2/grub.cfg \
                 /boot/loader/entries 2>/dev/null; then
                 echo 'Verified: boot configuration contains $KERNEL_RELEASE'
             else
                 echo 'Install script succeeded, but no boot entry for $KERNEL_RELEASE was found' >&2
                 status=1
             fi
         fi

         rm -f /tmp/install-kernel.sh
         exit \$status" || {
        status=$?
        rm -f "$INSTALL_SCRIPT"
        echo "Installation or boot-entry verification failed on $REMOTE_HOST (status $status)" >&2
        exit "$status"
    }

    rm -f "$INSTALL_SCRIPT"
    echo "Done. Kernel installed and boot entry verified on $REMOTE_HOST"
else
    echo "Kernel tarball created: $HOME/tmp-$KERNEL_RELEASE-$ARCH.tar.gz"
    echo "To install on remote system:"
    echo "  scp $HOME/src/kernel-$KERNEL_RELEASE-$ARCH.tar.gz user@server.lan:/tmp/"
    echo "  ssh user@server.lan 'cd /tmp && tar -xzf kernel-$KERNEL_RELEASE-$ARCH.tar.gz && sudo make modules_install && ...'"
fi

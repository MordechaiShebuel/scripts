#!/bin/bash
#
CPU_ARCH=${1:-ZEN3}
REMOTE_HOST=${2:-}  # Optional: user@server.lan

# Make sure podman is installed
if ! $(fd podman | ag "\[\*\] podman" >/dev/null 2>&1);
then
    inst podman
fi

mkdir -p $HOME/src

podman build -t void-kernel-builder -f Containerfile .

podman run --rm -it \
  --userns=keep-id \
  -v "$HOME/src:/src:z" \
  -e SRC=/src \
  -e CPU_ARCH="$CPU_ARCH" \
  void-kernel-builder \
  bash -c 'cd /src && exec bash /home/builder/create_void_kernel.sh "$CPU_ARCH" TRUE'

# Extract kernel release from the build
KERNEL_RELEASE=$(cat $HOME/src/linux/include/config/kernel.release 2>/dev/null || echo "unknown")

if [[ "$KERNEL_RELEASE" == "unknown" ]]; then
    echo "Error: Could not determine kernel release" >&2
    exit 1
fi

echo "Kernel release: $KERNEL_RELEASE"

echo "Make the modules:"
cd "$HOME/src/linux"

# KERNEL_RELEASE="$(make -s kernelrelease)"
STAGE="$(mktemp -d)"

echo "Kernel release: $KERNEL_RELEASE"
echo "Staging modules in: $STAGE/modules"

make -C "$HOME/src/linux" -j"$(nproc)" modules
make -C "$HOME/src/linux" modules_install \
  INSTALL_MOD_PATH="$STAGE/modules"

test -d "$STAGE/modules/lib/modules/$KERNEL_RELEASE"

MODDIR="$STAGE/modules/lib/modules/$KERNEL_RELEASE"

rm -f "$MODDIR/build" "$MODDIR/source"

# Create distributable tar
tar -czf "$HOME/src/linux/kernel-$KERNEL_RELEASE.tar.gz" \
  -C "$HOME/src/linux" \
  arch/x86/boot/bzImage \
  System.map \
  -C "$STAGE" \
  modules

INSTALL_SCRIPT="$(mktemp)"

cat > "$INSTALL_SCRIPT" <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

KERNEL_RELEASE="$1"
echo "Installing ${KERNEL_RELEASE}"
cd /tmp
tar -xzf "kernel-${KERNEL_RELEASE}.tar.gz"

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
    scp "$HOME/src/linux/kernel-$KERNEL_RELEASE.tar.gz" "$REMOTE_HOST:/tmp/" || {
        echo "SCP failed to copy kernel tar.gz" >&2
        exit 1
    }
    scp "$INSTALL_SCRIPT" "$REMOTE_HOST:/tmp/install-kernel.sh" || {
        echo "SCP failed to copy install script" >&2
        exit 1
    }
    ssh -tt "$REMOTE_HOST" \
        "sudo bash /tmp/install-kernel.sh '$KERNEL_RELEASE'; status=\$?; rm -f /tmp/install-kernel.sh; exit \$status"

    rm -f "$INSTALL_SCRIPT"
    echo "Done. Kernel installed on $REMOTE_HOST"
else
    echo "Kernel tarball created: $HOME/src/kernel-$KERNEL_RELEASE.tar.gz"
    echo "To install on remote system:"
    echo "  scp $HOME/src/kernel-$KERNEL_RELEASE.tar.gz user@server.lan:/tmp/"
    echo "  ssh user@server.lan 'cd /tmp && tar -xzf kernel-$KERNEL_RELEASE.tar.gz && sudo make modules_install && ...'"
fi

#!/bin/bash
#
CPU_ARCH=${1:-ZEN3}
REMOTE_HOST=${2:-}  # Optional: user@server.lan

# Podman stage

# Make sure podman is installed
if ! command -v podman >/dev/null 2>&1;
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

# Module stage
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
  INSTALL_MOD_PATH="$STAGE/modules" \
  INSTALL_MOD_STRIP=1

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

# Install stage

modules_size=$(du -sh "$STAGE/modules")
read -p "MODULES BUILT, READY TO INSTALL - size of MODULES: $modules_size "
./install_tar.sh

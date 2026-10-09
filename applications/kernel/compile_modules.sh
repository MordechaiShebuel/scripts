#!/bin/bash
#
# Module stage
# Extract kernel release from the build
KERNEL_RELEASE=$1
ARCH=$2

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

mkdir -p "$HOME/tmp"

# Create distributable tar
tar -czf "$HOME/tmp/kernel-$KERNEL_RELEASE-$ARCH.tar.gz" \
  -C "$HOME/src/linux" \
  arch/x86/boot/bzImage \
  System.map \
  -C "$STAGE" \
  modules

# Install stage

modules_size=$(du -sh "$STAGE/modules")
read -p "MODULES BUILT, READY TO INSTALL - size of MODULES: $modules_size "

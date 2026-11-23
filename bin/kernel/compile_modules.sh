#!/bin/bash
#
# Module stage
# Extract kernel release from the build
BUILD_CPU="${1:-prime}"

# Guard: require correct arguments
if [ $# -lt 1 ]; then
  echo "Usage: $0 <BUILD_CPU>" >&2
  exit 1
fi

. "./.$BUILD_CPU"

echo " ===> Creating Modules to install for $KERNEL_RELEASE"

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

echo "===> Compressing Kernel image for $CPU_ARCH and $KERNEL_RELEASE"

# Create distributable tar
tar -czf "$HOME/tmp/kernel-$KERNEL_RELEASE-$CPU_ARCH.tar.gz" \
  -C "$HOME/src/linux" \
  arch/x86/boot/bzImage \
  System.map \
  -C "$STAGE" \
  modules

# Install stage

modules_size=$(du -sh "$STAGE/modules")
tar_size=$(du -sh "$HOME/tmp/kernel-$KERNEL_RELEASE-$CPU_ARCH.tar.gz")
echo "MODULES BUILT, READY TO INSTALL"
echo "size of MODULES: $modules_size"
echo "size of TAR: $tar_size"

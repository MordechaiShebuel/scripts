#!/bin/bash
set -Eeuo pipefail

SRC="$HOME/src"
LINUX_SRC="$SRC/linux"
CACHY_PATCH_SRC="$SRC/cachy-patches"

LINUX_VERSION="v7.2.6"
OLD_KERNEL="$(uname -r)"

KVER="${LINUX_VERSION#v}"
K_V="${KVER%.*}"

PATCH_GROUPS=(
    cachyos-fixes-patches-v8
    cpu-cachyos-patches
    bore-patches
    # gaming-sched-patches-v2
)

# Dependencies
sudo xbps-install -Syu \
    base-devel git bc kmod elfutils-devel bash cpio xz lz4 zstd \
    flex bison openssl-devel curl pahole tar python3 patch wget rsync \
    dracut grub -y

# Clone kernel source
if [ ! -d "$LINUX_SRC/.git" ]; then
    git clone \
        --depth 1 \
        --branch "$LINUX_VERSION" \
        https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git \
        "$LINUX_SRC"
fi

# Clone Cachy patch repository
if [ ! -d "$CACHY_PATCH_SRC/.git" ]; then
    git clone \
        https://github.com/sirlucjan/kernel-patches.git \
        "$CACHY_PATCH_SRC"
fi

cd "$LINUX_SRC"

# Make sure the requested kernel revision is checked out
git checkout "$LINUX_VERSION"

# clean prior potential builds
git reset --hard "$LINUX_VERSION"
git clean -fdx

# Set local kernel suffix
sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION = -cachy/' Makefile

# Apply Void's fixdep patch
FIXDEP_PATCH="fixdep-largefile.patch"

wget -O "$FIXDEP_PATCH" \
    "https://github.com/void-linux/void-packages/raw/refs/heads/master/srcpkgs/linux$K_V/patches/fixdep-largefile.patch"

patch -p1 -N --batch < "$FIXDEP_PATCH" || \
    echo "Warning: fixdep patch did not apply"

# Locate matching Cachy patch directory
PATCH_DIR="$CACHY_PATCH_SRC/$K_V"

if [ ! -d "$PATCH_DIR" ]; then
    echo "No Cachy patch directory found: $PATCH_DIR" >&2
    exit 1
fi

echo "Applying Cachy patches from: $PATCH_DIR"

for group in "${PATCH_GROUPS[@]}"; do
    PATCH_GROUP_DIR="$PATCH_DIR/$group"

    if [ ! -d "$PATCH_GROUP_DIR" ]; then
        echo "Missing patch group: $PATCH_GROUP_DIR" >&2
        exit 1
    fi

    while IFS= read -r -d '' patch_file; do
        echo "Applying: $patch_file"

        patch -p1 --forward --batch < "$patch_file" || {
            echo "Failed to apply: $patch_file" >&2
            exit 1
        }
    done < <(
        find "$PATCH_GROUP_DIR" \
            -maxdepth 1 \
            -type f \
            -name '*.patch' \
            -print0 |
        sort -z
    )
done

# Configure kernel
echo "Configuring kernel..."

if [ -r "/boot/config-$OLD_KERNEL" ]; then
    echo "Using config from: /boot/config-$OLD_KERNEL"
    cp "/boot/config-$OLD_KERNEL" .config
else
    echo "No existing kernel config found; using x86_64 defconfig"
    make x86_64_defconfig
fi

# Enable Zen 3 option only if it exists
if grep -Rqs '^config MZEN3$' arch/x86 Kconfig* 2>/dev/null; then
    echo "Enabling CONFIG_MZEN3"
    ./scripts/config -e CONFIG_MZEN3
fi

# Enable HDCP
./scripts/config -e CONFIG_DRM_HDCP
./scripts/config -e CONFIG_DRM_HDCP_HELPER

# Resolve dependencies and obtain the real release string
make olddefconfig
KERNEL_RELEASE="$(make -s kernelrelease)"

echo "Building kernel: $KERNEL_RELEASE"

# Build once
make -j"$(nproc)" bzImage modules

# Install modules
sudo make modules_install

# Install kernel image
sudo cp "arch/x86/boot/bzImage" \
    "/boot/vmlinuz-$KERNEL_RELEASE"

# Save the actual config for future builds
sudo cp .config "/boot/config-$KERNEL_RELEASE"

# Generate initramfs
sudo depmod "$KERNEL_RELEASE"
sudo dracut --force \
    "/boot/initramfs-$KERNEL_RELEASE.img" \
    "$KERNEL_RELEASE"

if [ ! -s "/boot/initramfs-$KERNEL_RELEASE.img" ]; then
    echo "ERROR: initramfs creation failed" >&2
    exit 1
fi

# Update GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg

if ! sudo grep -Fq "$KERNEL_RELEASE" /boot/grub/grub.cfg; then
    echo "WARNING: Kernel $KERNEL_RELEASE not found in GRUB config" >&2
    exit 1
fi

echo
echo "Kernel build and installation complete"
echo
echo "Verify installation:"
echo "  ls -la /boot/vmlinuz-$KERNEL_RELEASE"
echo "  ls -la /boot/initramfs-$KERNEL_RELEASE.img"
echo "  grep CONFIG_DRM_HDCP /boot/config-$KERNEL_RELEASE"
echo
echo "Then reboot and run: hdcp_check.sh"

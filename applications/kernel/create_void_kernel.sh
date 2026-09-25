#!/bin/bash
set -Eeuo pipefail

SRC="$HOME/src"
LINUX_SRC="$SRC/linux"
CACHY_PATCH_SRC="$SRC/cachy-patches"

LINUX_VERSION="v7.2.7"
OLD_KERNEL="$(uname -r)"

KVER="${LINUX_VERSION#v}"
K_V="${KVER%.*}"

require_space_gib() {
    local path="$1"
    local required_gib="$2"
    local available_kib

    available_kib=$(df -Pk "$path" | awk 'NR==2 {print $4}')

    if (( available_kib < required_gib * 1024 * 1024 )); then
        echo "ERROR: insufficient free space on $(df -P "$path" | awk 'NR==2 {print $6}')" >&2
        echo "Required: at least ${required_gib} GiB" >&2
        echo "Available: $((available_kib / 1024 / 1024)) GiB" >&2
        exit 1
    fi
}

mkdir -p $SRC

require_space_gib "$HOME/src" 16 # 25 is recommended amount of space free

## Download and Apply Patches
PATCH_GROUPS=(
    cachyos-fixes-patches-v8
    cpu-cachyos-patches
    bore-patches
    # gaming-sched-patches-v2
)

PATCH_FILES=(
    0001-cachyos-fixes-patches.patch
    0001-CACHY-Add-x86_64-ISA-and-Zen4-compiler-optimizations.patch
    0001-linux7.2-bore6.8.0.patch
)

# Dependencies
sudo xbps-install -Syu \
    base-devel git bc kmod elfutils-devel bash cpio xz lz4 zstd \
    flex bison openssl-devel curl pahole tar python3 patch wget rsync \
    dracut grub -y

# Clone kernel source
if [ ! -d "$LINUX_SRC/.git" ]; then
    echo "Fetching Linux $LINUX_VERSION into $SRC"

    mkdir -p "$LINUX_SRC"
    cd "$LINUX_SRC"

    git init
    git remote add origin \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git

    git fetch \
        --depth=1 \
        origin \
        "refs/tags/$LINUX_VERSION:refs/tags/$LINUX_VERSION"

    git checkout --detach "$LINUX_VERSION"
fi

cd "$LINUX_SRC"
mkdir -p patches

# Download patches individually instead of entire repo
for PATCH_GROUP in "${PATCH_GROUPS[@]}"; do
    for PATCH_FILE in "${PATCH_FILES[@]}"; do
        echo "Downloading $PATCH_FILE from $PATCH_GROUP..."
        wget -O "patches/$PATCH_FILE" \
            "https://github.com/sirlucjan/kernel-patches/raw/refs/heads/master/$K_V/$PATCH_GROUP/$PATCH_FILE" || {
            echo "Failed to download: $PATCH_FILE from $PATCH_GROUP" >&2
            continue
        }
    done
done

# clean prior potential builds
git reset --hard "$LINUX_VERSION"
git clean -fdx

# Set local kernel suffix
sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION = -cachy/' Makefile

# Apply Void's fixdep patch
FIXDEP_PATCH="fixdep-largefile.patch"

wget -O "$FIXDEP_PATCH" \
    "https://github.com/void-linux/void-packages/raw/refs/heads/master/srcpkgs/linux$K_V/patches/fixdep-largefile.patch"

# Locate matching Cachy patch directory
echo "Applying patches from: ./patches"

# Apply patches
echo "Applying patches..."
for patch_file in patches/*.patch; do
    if [[ -f "$patch_file" ]]; then
        echo "Applying: $(basename "$patch_file")"
        patch -p1 --forward --batch < "$patch_file" || {
            echo "Failed to apply: $patch_file" >&2
            exit 1
        }
    fi
done

echo "All patches applied successfully!"

# Configure kernel
echo "Configuring kernel..."

if [ -r "/boot/config-$OLD_KERNEL" ]; then
    echo "Using config from: /boot/config-$OLD_KERNEL"
    cp "/boot/config-$OLD_KERNEL" .config
else
    echo "No existing kernel config found; using x86_64 defconfig"
    make x86_64_defconfig
fi

# Preserve the original configuration.
cp .config .config.before-localmodconfig

# Trim drivers not used by the running system.
# Load old config
cp "/boot/config-$OLD_KERNEL" .config

# Force NVMe drivers to be built-in (=y), not modules (=m)
./scripts/config -e CONFIG_NVME
./scripts/config -e CONFIG_NVME_CORE
./scripts/config -e CONFIG_NVME_KEYRING
./scripts/config -e CONFIG_NVME_AUTH

# Also ensure ext4 is built-in (for your root filesystem)
./scripts/config -e CONFIG_EXT4_FS
./scripts/config -e CONFIG_EXT4_FS_POSIX_ACL

# Apply your customizations
./scripts/config -e CONFIG_MZEN3 2>/dev/null || true
./scripts/config -e CONFIG_DRM_HDCP
./scripts/config -e CONFIG_DRM_HDCP_HELPER

# SKIP localmodconfig entirely — it removes needed drivers
# Instead, use olddefconfig to handle new config options
make olddefconfig

echo "Configuration entries:"
grep -c '^CONFIG_' .config || true

KERNEL_RELEASE="$(make -s kernelrelease)"

echo "Building kernel: $KERNEL_RELEASE"

# Build once
make -j$(($(nproc)/2)) bzImage modules

# Install modules
sudo -v
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
echo "Then reboot and enjoy"

# Remove downloaded source repositories after a successful installation.
echo
echo "Cleaning up downloaded source repositories..."

cd "$HOME"

rm -rf -- "$LINUX_SRC" "$CACHY_PATCH_SRC"

echo "Removed:"
echo "  $LINUX_SRC"
echo "  $CACHY_PATCH_SRC"

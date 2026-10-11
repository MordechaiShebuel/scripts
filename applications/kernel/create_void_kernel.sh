#!/bin/bash
set -Eeuo pipefail

if [[ -d /src ]]; then
    # Container build
    SRC=/src
else
    # Native host build
    SRC="${SRC:-"$HOME/src"}"
fi

if [[ "$(id -u)" -eq 0 || "$(id -un)" == "builder" ]]; then
    SUDO=()
    KERNEL_CONFIG=/home/builder/config
else
    command -v sudo >/dev/null 2>&1 || {
        echo "Error: sudo is required for privileged operations." >&2
        exit 1
    }

    sudo -v
    SUDO=(sudo)
fi

export SRC
cd "$SRC"

echo "Source directory: $SRC"
echo "Build user: $(id -un)"

LINUX_SRC="$SRC/linux"
CACHY_PATCH_SRC="$SRC/cachy-patches"

LINUX_VERSION="v7.2.9"
OLD_KERNEL="$(uname -r)"

KVER="${LINUX_VERSION#v}"
K_V="${KVER%.*}"

CONTAINER_BUILD=${2:-false}

require_space_gib() {
    local path="$1"
    local required_gib="$2"
    local available_kib

    available_kib="$(df -Pk "$path" | awk 'NR == 2 { print $4 }')"

    if [[ -z "$available_kib" || ! "$available_kib" =~ ^[0-9]+$ ]]; then
        echo "ERROR: could not determine available space on $path" >&2
        exit 1
    fi

    if (( available_kib < required_gib * 1024 * 1024 )); then
        local mountpoint
        mountpoint="$(df -P "$path" | awk 'NR == 2 { print $6 }')"

        echo "ERROR: insufficient free space on $mountpoint" >&2
        echo "Required: at least ${required_gib} GiB" >&2
        echo "Available: $((available_kib / 1024 / 1024)) GiB" >&2
        exit 1
    fi
}

echo "REMOVING $LINUX_SRC"
rm -rf $LINUX_SRC

require_space_gib "$SRC" 16 # 25 is recommended amount of space free

## Download and Apply Patches
declare -A PATCHES=(
    [cachyos-fixes-patches-v9]="0001-cachyos-fixes-patches.patch"
    [cpu-cachyos-patches]="0001-CACHY-Add-x86_64-ISA-and-Zen4-compiler-optimizations.patch"
    [bore-patches]="0001-linux7.2-bore6.8.0.patch"
    # [gaming-sched-patches-v2]="your-patch-file.patch"
)

if [[ "$CONTAINER_BUILD" == "false" ]]; then
    # Dependencies
    "${SUDO[@]}" xbps-install -Syu \
        base-devel git bc kmod elfutils-devel bash cpio xz lz4 zstd \
        flex bison openssl-devel curl pahole tar python3 patch wget rsync \
        dracut grub -y
fi

echo "Making ${LINUX_SRC}"
mkdir -p "${LINUX_SRC}"
cd "${LINUX_SRC}"

# Clone kernel source
if [ ! -d "$LINUX_SRC/.git" ]; then
    echo "Initialize git for ${LINUX_SRC}"
    git init
    git remote add origin \
    https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git

    echo "Fetching Linux $LINUX_VERSION into $LINUX_SRC"
    git fetch \
        --depth=1 \
        origin \
        "refs/tags/${LINUX_VERSION}:refs/tags/${LINUX_VERSION}"

    git checkout --detach "${LINUX_VERSION}"
else
    echo "${LINUX_SRC} was not properly removed/reset"
    exit 1
fi

# clean prior potential builds (SHOULDN'T REALLY BE NECESSARY WITH THE FOLDER DELETE AT TOP OF FILE
git reset --hard "$LINUX_VERSION"
git clean -fdx

mkdir -p patches

# This needs to rethought out, it tries downlaading nine times for three files
# Download patches individually instead of entire repo
for PATCH_GROUP in "${!PATCHES[@]}"; do
    PATCH_FILE=${PATCHES[$PATCH_GROUP]}

    echo "Downloading $PATCH_FILE from $PATCH_GROUP..."
    wget -O "patches/$PATCH_FILE" \
        "https://github.com/sirlucjan/kernel-patches/raw/refs/heads/master/$K_V/$PATCH_GROUP/$PATCH_FILE" ||
        echo "Failed to download: $PATCH_FILE from $PATCH_GROUP" >&2
done

# Set local kernel suffix
sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION = -cachy/' Makefile

# Apply Void's fixdep patch
FIXDEP_PATCH="fixdep-largefile.patch"

wget -O "$FIXDEP_PATCH" \
    "https://github.com/void-linux/void-packages/raw/refs/heads/master/srcpkgs/linux$K_V/patches/fixdep-largefile.patch"

# Locate matcLINUX_VERSIONhing Cachy patch directory
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

CONFIG_FILE="${KERNEL_CONFIG:-}"
echo "Config File: ${CONFIG_FILE}"
if [[ -n "$CONFIG_FILE" && -r "$CONFIG_FILE" ]]; then
    echo "Using supplied config from: $CONFIG_FILE"
    cp "$CONFIG_FILE" .config
elif [[ -r "/boot/config-$(uname -r)" && \
        ! -e /.containerenv && \
        ! -e /.dockerenv ]]; then
    CONFIG_FILE="/boot/config-$(uname -r)"
    echo "Using host config from: $CONFIG_FILE"
    cp "$CONFIG_FILE" .config
else
    echo "Using x86_64_defconfig"
    make x86_64_defconfig
fi

STAGE="$(mktemp -d)"

# Preserve the original configuration.
cp .config .config.before-localmodconfig

# Trim drivers not used by the running system.
# Load old config
# cp "/boot/config-$OLD_KERNEL" .config

# Force NVMe drivers to be built-in (=y), not modules (=m)
./scripts/config -e CONFIG_NVME
./scripts/config -e CONFIG_NVME_CORE
./scripts/config -e CONFIG_NVME_KEYRING
./scripts/config -e CONFIG_NVME_AUTH

# Also ensure ext4 is built-in (for your root filesystem)
./scripts/config -e CONFIG_EXT4_FS
./scripts/config -e CONFIG_EXT4_FS_POSIX_ACL

# Apply your customizations
set_cpu_arch() {
    local arch="${1:-ZEN3}"

    case "$arch" in
        ZEN)
            ./scripts/config -e CONFIG_MZEN
            ;;
        ZEN2)
            ./scripts/config -e CONFIG_MZEN2
            ;;
        ZEN3)
            ./scripts/config -e CONFIG_MZEN3
            ;;
        *)
            # Non-Zen CPU or unrecognized — just proceed
            ;;
    esac
}

echo "Configuring CPU architecture"
set_cpu_arch "${1:-ZEN3}"

# DRM crap
./scripts/config -e CONFIG_DRM_HDCP
./scripts/config -e CONFIG_DRM_HDCP_HELPER

# Strongly recommended for size + boot reliability
./scripts/config -e CONFIG_MODULES          # keep modules support
scripts/config --disable CONFIG_DEBUG_INFO \
                         --disable CONFIG_DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT \
                         --disable CONFIG_DEBUG_INFO_REDUCED \
                         --disable CONFIG_DEBUG_INFO_BTF \
                         --disable CONFIG_DEBUG_VM \
                         --disable CONFIG_DEBUG_KERNEL \
                         --disable CONFIG_PROVE_LOCKING \
                         --disable CONFIG_LOCK_STAT \
                         --disable CONFIG_LATENCYTOP
./scripts/config -e CONFIG_CC_OPTIMIZE_FOR_SIZE
./scripts/config -e CONFIG_MODULE_COMPRESS
./scripts/config -e CONFIG_MODULE_COMPRESS_ZSTD   # Compress Modules

# olddefconfig to handle new config options
make olddefconfig

echo "Configuration entries:"
grep -c '^CONFIG_' .config || true

KERNEL_RELEASE="$(make -s kernelrelease)"

echo "Building kernel: $KERNEL_RELEASE"

# Build once
make clean
make -j$(($(nproc)/2)) bzImage modules

# NEED TO PAUSE HERE WAIT FOR HUMAN
read -p "Compile portion completed, Press [Enter] key to continue with kernel install..."

# Install modules
# # ONLY DO INSTALL LOCALLY!
if [[ "$CONTAINER_BUILD" == "TRUE" ]]; then
    echo "CONTAINER BUILD COMPLETED!"
    exit 0
fi

# THESE COMMANDS SHOULD NOT RUN IN CONTAINER
sudo -v
sudo make -C "$HOME/src/linux" modules_install \
  INSTALL_MOD_STRIP=1

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

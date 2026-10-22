#!/bin/bash
#
BUILD_CPU=$1
MODE=$2 # Optional: if set to BUILD, will skip install stage

if [[ -z "$BUILD_CPU" || -z "$MODE" ]]; then
    echo "Usage: $0 <build_cpu> <mode>"
    echo "build_cpu: file name with build parameters; "
    echo "REMOTE_HOST=\"user@host.lan\""
    echo " CPU=INTEL"
    echo " CPU_ARCH=INTEL"
    echo " KERNEL_RELEASE=\"7.2.12-cachy_1+\""
    echo "The Kernel line is optional, the script will overwrite that with the new version when it completes."
    echo "mode: build/install - if build only builds up to tar. If install will attempt to connect to remote host and install."
    exit 1
fi

# Read distribution information.
if [[ ! -r "./.$BUILD_CPU" ]]; then
    echo "BUILD CPU MATCHES NO EXISTING FILE." >&2
    exit 1
fi

. "./.$BUILD_CPU" #expand build variables from associated dot file
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

# get kernel name:
KERNEL_RELEASE=$(cat $HOME/src/linux/include/config/kernel.release 2>/dev/null || echo "unknown")

cat > ".$BUILD_FILE" <<EOF
REMOTE_HOST="$REMOTE_HOST"
CPU="$CPU_ARCH"
CPU_ARCH="$CPU_ARCH"
KERNEL_RELEASE="$KERNEL_RELEASE"
EOF

if [[ "$KERNEL_RELEASE" = "unknown" ]]; then
    echo "Cannot find KERNEL_RELEASE for this build, unable to continue." >&2
    exit 1
fi

./compile_modules.sh $BUILD_CPU

if [[ $MODE == "build" ]]; then
    echo "Kernel $KERNEL_RELEASE completed, ready for install."
    echo "Run installer, .install_tar.sh $BUILD_CPU"
    exit 0
fi

# check created tar exists and has appropriate size
TAR="$HOME/tmp/kernel-$KERNEL_RELEASE-$CPU_ARCH.tar.gz"
MIN_SIZE=$((90 * 1024 * 1024)) # 90 MiB

if [[ -f "$TAR" ]] && (( $(wc -c < "$TAR") > MIN_SIZE )); then
    if ping -c 1 "$REMOTE_HOST" >/dev/null 2>&1; then
        ./install_tar.sh "$BUILD_CPU"
    else
        echo "Unable to install: remote host is not reachable."
        echo "Run ./install_tar.sh \"$KERNEL_RELEASE\" \"$REMOTE_HOST\" \"$CPU_ARCH\" when the machine is accessible."
    fi
else
    echo "Likely an issue with the kernel compile. Tarball size:"
    if [[ -f "$TAR" ]]; then
        du -h "$TAR"
    else
        echo "Tarball not found: $TAR"
    fi
fi

if $(du -h "$HOME/tmp/kernel-$KERNEL_RELEASE-$ARCH.tar.gz" | # split string on M | # size compare) # should be greater than 90M; then
    if # Check $REMOTE_HOST is accessible, ping?; then
        ./install_tar.sh $BUILD_CPU
    else
        echo "Unable to install, remote host not accessible."
        echo "Make sure to run ./install_tar.sh $BUILD_CPU when the machine is accesible"
    fi
else
    echo "Likely an issue with the kernel compile, the size is:"
    echo "$$(du -h "$HOME/tmp/kernel-$KERNEL_RELEASE-$CPU_ARCHARCH.tar.gz" | # split string on M | # size compare)"
fi

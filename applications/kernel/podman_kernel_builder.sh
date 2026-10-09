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

# get kernel name:
KERNEL_RELEASE=$(cat $HOME/src/linux/include/config/kernel.release 2>/dev/null || echo "unknown")


if [[ "$KERNEL_RELEASE" = "unknown" ]]; then
    echo "Cannot find KERNEL_RELEASE for this build, unable to continue." >&2
    exit 1
fi

./compile_modules.sh $KERNEL_RELEASE $CPU_ARCH

# check created tar exists and has appropriate size
TAR="$HOME/tmp/kernel-$KERNEL_RELEASE-$ARCH.tar.gz"
MIN_SIZE=$((90 * 1024 * 1024)) # 90 MiB

if [[ -f "$TAR" ]] && (( $(wc -c < "$TAR") > MIN_SIZE )); then
    if ping -c 1 "$REMOTE_HOST" >/dev/null 2>&1; then
        ./install_tar.sh "$KERNEL_RELEASE" "$REMOTE_HOST" "$CPU_ARCH"
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
        ./install_tar.sh $KERNEL_RELEASE $REMOTE_HOST $CPU_ARCH
    else
        echo "Unable to install, remote host not accessible."
        echo "Make sure to run ./install_tar.sh $KERNEL_RELEASE $REMOTE_HOST $CPU_ARCH when the machine is accesible"
    fi
else
    echo "Likely an issue with the kernel compile, the size is:"
    echo "$$(du -h "$HOME/tmp/kernel-$KERNEL_RELEASE-$CPU_ARCHARCH.tar.gz" | # split string on M | # size compare)"
fi

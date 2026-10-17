#!/bin/bash
set -euo pipefail

if ! command -v podman >/dev/null; then
    echo "podman not found – install it first"
    exit 1
fi

# Host paths
REPO_HOST="/home/media/shared/Users/mshalom/repos/repository"
SRC_HOST="$HOME/src"
mkdir -p "$SRC_HOST"

# Architecture (override with: CPU_ARCH=aarch64 ./build_repo.sh)
CPU_ARCH="${CPU_ARCH:-x86_64}"

echo "==> Check PEM file :"

# Make sure the signing key exists
if [[ ! -f "$HOME/private.pem" ]]; then
    echo "ERROR: $HOME/private.pem not found."
    echo "Generate one with:"
    echo "  ssh-keygen -t rsa -b 4096 -m PEM -f ~/private.pem"
    exit 1
fi

echo "==> Build Container :"
podman build -t void-repo-builder -f Containerfile .

echo "==> Start Container :"
podman run --rm -it \
    --userns=keep-id \
    -v "$SRC_HOST:/src:z" \
    -v "$REPO_HOST:$REPO_HOST:z" \
    -v "$HOME/private.pem:/home/builder/private.pem:ro" \
    -e SRC=/src \
    -e HOME=/home/builder \
    void-repo-builder \
    bash -c "exec /home/builder/repo_builder.sh '$CPU_ARCH' TRUE"

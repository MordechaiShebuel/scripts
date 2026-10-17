#!/bin/bash
set -euo pipefail

# Arguments coming from the podman run line
CPU_ARCH="${1:-x86_64}"          # e.g. x86_64, aarch64, x86_64-musl …
SIGN="${2:-FALSE}"               # TRUE → sign the repo (requires key)

# Paths inside the container
SRC_DIR="${SRC:-/src}"
REPO_SRC="/home/media/shared/Users/mshalom/repos/repository"   # host path – will be mounted
OUT_DIR="${SRC_DIR}/binpkgs"                                   # where finished packages land
HOSTDIR="${SRC_DIR}/hostdir"

echo "==> Architecture : $CPU_ARCH"
echo "==> Source tree  : $REPO_SRC"
echo "==> Output       : $OUT_DIR"

mkdir -p "$OUT_DIR" "$HOSTDIR"

# ------------------------------------------------------------------
# 1. Make sure we have a void-packages tree
# ------------------------------------------------------------------
if [[ ! -d "$REPO_SRC/xbps-src" ]]; then
    echo "No void-packages tree found – cloning a shallow copy…"
    git clone --depth=1 https://github.com/void-linux/void-packages.git "$REPO_SRC"
fi

cd "$REPO_SRC"

# Optional: pull latest templates
# git pull --ff-only || true

# ------------------------------------------------------------------
# 2. Bootstrap the masterdir (only needed once per architecture)
# ------------------------------------------------------------------
if [[ ! -d "masterdir-${CPU_ARCH}" ]]; then
    echo "==> Bootstrapping masterdir for $CPU_ARCH"
    ./xbps-src -a "$CPU_ARCH" -m "masterdir-${CPU_ARCH}" binary-bootstrap
fi

# ------------------------------------------------------------------
# 3. Build the packages you care about
#    Edit the list below, or pass them as extra arguments.
# ------------------------------------------------------------------
PKGS=(
    # example: linux6.12          # custom kernel
    # example: my-custom-app
)

# If you pass extra args after the two positional ones they are treated as packages
shift 2 || true
PKGS+=("$@")

if [[ ${#PKGS[@]} -eq 0 ]]; then
    echo "No packages specified – nothing to build."
    echo "Usage: repo_builder.sh <arch> <SIGN:TRUE|FALSE> [pkg1 pkg2 …]"
    exit 0
fi

for pkg in "${PKGS[@]}"; do
    echo "==> Building $pkg ($CPU_ARCH)"
    ./xbps-src -a "$CPU_ARCH" -m "masterdir-${CPU_ARCH}" \
        -H "$HOSTDIR" \
        pkg "$pkg"
done

# ------------------------------------------------------------------
# 4. Collect binary packages into a clean repository layout
# ------------------------------------------------------------------
# void-packages puts them under hostdir/binpkgs (and subdirs for nonfree, etc.)
find "$HOSTDIR/binpkgs" -name '*.xbps' -exec cp -av {} "$OUT_DIR/" \;

cd "$OUT_DIR"

# ------------------------------------------------------------------
# 5. Index the repository
# ------------------------------------------------------------------
echo "==> Indexing repository"
xbps-rindex -a ./*.xbps

# ------------------------------------------------------------------
# 6. Optional signing (required for any remote/HTTP repository)
# ------------------------------------------------------------------
if [[ "$SIGN" == "TRUE" ]]; then
    if [[ ! -f "$HOME/private.pem" ]]; then
        echo "ERROR: signing requested but $HOME/private.pem not found."
        echo "Generate one with:"
        echo "  ssh-keygen -t rsa -b 4096 -m PEM -f ~/private.pem"
        exit 1
    fi
    echo "==> Signing repository"
    xbps-rindex --privkey "$HOME/private.pem" \
                --signedby "Your Name <you@example.com>" \
                --sign .
    xbps-rindex --privkey "$HOME/private.pem" --sign-pkg ./*.xbps
fi

echo "==> Done. Packages are in $OUT_DIR"
ls -l

#!/usr/bin/env bash
# Installer for Lunduke City

set -euo pipefail
trap 'echo "ERROR: Installation failed on line $LINENO." >&2' ERR

REPO_DIR="$HOME/src/LundukeCity"

echo "==> Installing build dependencies..."
sudo xbps-install -S \
    base-devel \
    git \
    meson \
    ninja \
    pkg-config \
    gtkmm-devel

echo "==> Preparing source directory..."
mkdir -p "$HOME/src"

if [[ -d "$REPO_DIR/.git" ]]; then
    echo "==> Repository already exists at $REPO_DIR"
    echo "==> Updating repository..."
    git -C "$REPO_DIR" pull --ff-only
else
    echo "==> Cloning Lunduke City..."
    git clone https://github.com/BryanLunduke/LundukeCity.git "$REPO_DIR"
fi

cd "$REPO_DIR"

echo "==> Configuring the build..."
if [[ -d build ]]; then
    meson setup --reconfigure build
else
    meson setup build
fi

echo "==> Compiling Lunduke City..."
meson compile -C build

echo "==> Build completed successfully."

echo "==> Installing Lunduke City..."
sudo meson install -C build

echo "==> Lunduke City was installed successfully."

echo "==> Launching Lunduke City..."
./build/src/lunduke-city

#!/bin/bash

sudo apt-get install build-essential libncurses-dev bison flex libssl-dev libelf-dev

OLD_VER="6.18.59"
NEW_VER="6.18.60"

rm -f "linux-${NEW_VER}.tar.xz"

cd "$HOME/tmp"
wget -O "linux-${NEW_VER}.tar.xz" "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${NEW_VER}.tar.xz"

# Verify the download succeeded
if [ ! -f "linux-${NEW_VER}.tar.xz" ]; then
  echo "Download failed!"
  exit 1
fi

# Clean up old extraction if it exists
rm -rf "linux-${NEW_VER}"

tar -xf "linux-${NEW_VER}.tar.xz"
cd "linux-${NEW_VER}"

# Use your current config
cp "/boot/config-${OLD_VER}" .config

# Update for the new version
make oldconfig  # Just hit Enter for new options

# Build (30-90 min depending on CPU)
make -j$(nproc)
sudo make modules_install
sudo make install

# Update bootloader
sudo update-grub
# sudo reboot

#!/bin/bash

cd ~/src/linux
make clean
make mrproper
cp /usr/lib/modules/6.18.5-1-cachyos/build/.config .config
make oldconfig  # or olddefconfig

# Modify config FIRST
./scripts/config -e CONFIG_DRM_HDCP
./scripts/config -e CONFIG_DRM_HDCP_HELPER

# Verify
./scripts/config -s CONFIG_DRM_HDCP
./scripts/config -s CONFIG_DRM_HDCP_HELPER

# THEN build with the finalized config
make -j$(nproc)
sudo make modules_install
sudo cp arch/x86_64/boot/bzImage /boot/vmlinuz-6.19.14
sudo depmod 6.19.14
sudo dracut --force /boot/initramfs-6.19.14.img 6.19.14
sudo grub-mkconfig -o /boot/grub/grub.cfg

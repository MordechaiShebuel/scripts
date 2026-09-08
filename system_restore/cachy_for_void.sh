#!/usr/bin/env bash
# DEPENDENCIES
xbps-install -Syu --repository=https://repo-de.voidlinux.org/current/ base-devel git bc kmod elfutils-devel bash cpio xz lz4 zstd flex bison openssl-devel curl pahole tar python3 patch wget rsync -y

# CLONE REPO
git clone --depth 1 --branch v7.1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux-src
cd linux-src
sed -i 's/^EXTRAVERSION =.*/EXTRAVERSION = -cachy/' Makefile

# Apply config
wget -O .config https://codeberg.org/javiercplus/cachy-void/raw/branch/main/config
wget -O fixdep-largefile.patch https://github.com/void-linux/void-packages/raw/refs/heads/master/srcpkgs/linux7.1/patches/fixdep-largefile.patch
patch -p1 -N --batch < fixdep-largefile.patch
make olddefconfig

# Compile
make -j$(nproc)
make -j$(nproc) bzImage modules

# Install
make install

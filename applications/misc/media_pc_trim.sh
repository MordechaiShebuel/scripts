#!/bin/sh
# media-trim
# Trims a machine down to a lighter media/usage-focused setup
# - Removes development packages
# - Keeps only Zen browser
# - Keeps mpv, removes VLC
# - Removes KVIrc, KTorrent, Telegram, Bitwarden

set -e

echo "==> Removing development packages..."
sudo xbps-remove -Ry \
  base-devel \
  binutils \
  bison \
  cmake \
  flex \
  meson \
  ninja \
  pahole \
  strace \
  \
  SDL2-devel \
  SDL2_image-devel \
  SDL2_mixer-devel \
  SDL2_net-devel \
  SDL2_ttf-devel \
  SPIRV-Tools-devel \
  aquamarine-devel \
  elfutils-devel \
  glslang-devel \
  gtkmm-devel \
  hyprcursor-devel \
  hyprlang-devel \
  hyprutils-devel \
  lcms2-devel \
  libcurl-devel \
  libei-devel \
  libgme-devel \
  libinput-devel \
  libopenmpt-devel \
  miniupnpc-devel \
  muparser-devel \
  ncurses-devel \
  openssl-devel \
  pango-devel \
  re2-devel \
  tomlplusplus-devel \
  xcb-util-errors-devel \
  xcb-util-wm-devel \
  \
  linux-cachyos-headers \
  gobject-introspection \
  nim \
  zig \
  nodejs \
  python3-pipenv

echo "==> Removing extra browsers (keeping only Zen)..."
sudo xbps-remove -Ry \
  brave-origin \
  falkon

echo "==> Removing VLC (keeping mpv)..."
sudo xbps-remove -Ry vlc

echo "==> Removing unwanted applications..."
sudo xbps-remove -Ry \
  kvirc \
  ktorrent \
  telegram-desktop \
  bitwarden-desktop

echo "==> Cleaning orphaned packages..."
sudo xbps-remove -o

echo "==> Done — media-trim complete."
echo "Kept: zen-browser, mpv"
echo "Removed: all -devel packages, Brave, Falkon, VLC, KVIrc, KTorrent, Telegram, Bitwarden"

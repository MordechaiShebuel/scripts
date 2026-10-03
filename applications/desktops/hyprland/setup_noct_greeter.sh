#!/bin/bash

sudo xbps-install -Su
sudo xbps-install meson ninja pkg-config git \
  greetd dbus \
  wayland-devel wayland-protocols wlroots-devel libepoxy-devel \
  MesaLib-devel libglvnd-devel cairo-devel \
  pango-devel fontconfig-devel freetype-devel harfbuzz-devel \
  tomlplusplus-devel nlohmann-json-devel stb \
  libxkbcommon-devel libwebp-devel librsvg-devel libxml2-devel

git clone https://github.com/noctalia-dev/noctalia-greeter.git
cd noctalia-greeter

meson setup build-release --prefix=/usr --buildtype=release
meson compile -C build-release
sudo meson install -C build-release
sudo ./scripts/setup_greeter_system.sh

sudo mkdir -p /etc/greetd
# sudo nano /etc/greetd/config.toml

# TEE or CAT this in
# [terminal]
# vt = 1
#
# [default_session]
# command = "noctalia-greeter-session"
# user = "greeter"

sudo sv down sddm # OR LIGHTDM
sudo rm -f /var/service/sddm

sudo ln -s /etc/sv/greetd /var/service/greetd

sudo sv status greetd

sudo touch /etc/sv/greetd/down
sudo rm -f /var/service/sddm
sudo ln -s /etc/sv/greetd /var/service/greetd
sudo rm -f /etc/sv/greetd/down

sudo sv restart greetd

# REBOOT

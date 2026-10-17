#!/bin/bash
# 0.05 OXWM setup script
# Tried setting menu up in Wayland-Sessions, for Noctalia greeter.
# Launches into black screen
# Decided to make this to setup tiling in X11. It may help solve some of the issues my older computer is having with steam.
#
# 1. Install dependencies. (Requires lazylinux repo)

sudo xbps-install -Syu

sudo xbps-install -S \
    oxwm \
    wofi \
    nemo \
    maim \
    xclip \
    i3lock-color \
    dunst \
    picom \
    plank \
    nitrogen \
    feh \
    gruvbox-material-theme \
    flameshot

#2. copy setups to local user config
# Current setups are not working, need troubleshooting.

cp -r oxwm "$HOME/.config/oxwm"

DEST_DIR="/usr/local/share/wayland-sessions"
DEST="$DEST_DIR/oxwm.desktop"

c

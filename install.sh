#!/usr/bin/env bash

linux=$(uname -a)
pkg=$1
option=$2

if [[ "$linux" == *"omlx"* ]]; then # Need to verify this is correct
    ## Open Mandrive Update
    sudo dnf in -y "$pkg"
fi

if [[ "$linux" == *"artix"* ]]; then
    ## Artix update
    pamac install "$pkg" --no-confirm
fi

if [[ "$linux" == *"deb13"* ]]; then
    ## vendefoul
    sudo apt-get install -y "$pkg"
fi

if [[ "$linux" == *"OpenWrt"* ]]; then
    ## OpenWRT
    opkg install -y
fi

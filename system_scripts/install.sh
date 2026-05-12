#!/usr/bin/env bash

linux=$(uname -a)
pkg=$1
option=$2

if [[ "$linux" == *"omlx"* ]]; then # Need to verify this is correct
    ## Open Mandrive Install
    sudo dnf in -y "$pkg"
fi

if [[ "$linux" == *"artix"* ]]; then
    ## Artix Install
    if [[ "$option" == "aur" ]]; then
        trizen -S "${pkg}" --noconfirm
    else
        pamac install "$pkg" --no-confirm
    fi
fi

if [[ "$linux" == *"deb13"* ]]; then
    ## vendefoul
    sudo apt-get install -y "$pkg"
fi

if [[ "$linux" == *"OpenWrt"* ]]; then
    ## OpenWRT
    opkg install -y
fi

#!/usr/bin/env bash

linux=$(uname -a)

if [[ "$linux" == *"omlx"* ]]; then # Need to verify this is correct
    ## Open Mandrive Update
    sudo dnf clean all ; sudo dnf dsync --allowerasing -x kernel-desktop
fi

if [[ "$linux" == *"artix"* ]]; then
    ## Artix update
    trizen -Syu
fi

if [[ "$linux" == *"deb13"* ]]; then
    ## vendefoul
    sudo apt-get update && sudo apt-get upgrade
fi

if [[ "$linux" == *"OpenWrt"* ]]; then
    ## OpenWRT
    opkg update && opkg list-upgradable | cut -f1 -d ' ' | xargs -r opkg upgrade
fi

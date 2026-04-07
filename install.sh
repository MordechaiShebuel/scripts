#!/usr/bin/env bash

linux=$(uname -r)
pkg=$1

if [[ "$linux" == *"omlx"* ]]; then # Need to verify this is correct
    ## Open Mandrive Update
    sudo dnf in "$pkg"
fi

if [[ "$linux" == *"artix"* ]]; then
    ## Artix update
    pamac install "$pkg"
fi

if [[ "$linux" == *"deb13"* ]]; then
    ## vendefoul
    sudo apt-get install "$pkg"
fi

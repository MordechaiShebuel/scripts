#!/usr/bin/env bash

if [[ "$(uname -r)" == *"omlx"* ]]; then # Need to verify this is correct
    ## Open Mandrive Update
    sudo dnf clean all ; sudo dnf dsync --allowerasing -x kernel-desktop
fi

if [[ "$(uname -r)" == *"artix"* ]]; then
    ## Artix update
    sudo pacman -Syu
fi

if [[ "$(uname -r)" == *"vendefoul"* ]]; then
    ## vendefoul
    sudo apt-get update && sudo apt-get upgrade
fi

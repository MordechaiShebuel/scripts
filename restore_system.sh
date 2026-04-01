#!/usr/bin/env bash

if [[ "$(uname -r)" == *"omlx"* ]]; then
    # Open Mandriva
    sudo dnf clean all ; sudo dnf dsync --allowerasing -x kernel-desktop
    sudo dnf in zsh steam vivaldi gimp obs-studio git dvd+rw-tools lib64dvdnav4 lib64dvdread lib64dvdcss vlc curl

    sudo chsh -s $(which zsh) mbuel
fi

if [[ "$(uname -r)" == *"artix"* ]]; then
    # Artix
    #update first
    sudo pacman -Syu

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]

    sudo pacman -S fastfetch libdvdcss libdvdnav libdvdread vlc steam git obs-studio gimp curl
fi

if [[ "$(uname -r)" == *"vendefoul"* ]]; then

    # Vendewolf
    # After installing
    sudo apt-get update && sudo apt-get upgrade

    sudo apt-get install fastfetch libdvdcss libdvdnav libdvdread vlc steam git gimp curl podman podman-compose
    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi


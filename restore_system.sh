#!/usr/bin/env bash

pkg_list=("zsh steam vivaldi gimp obs-studio git vlc curl")
linux=$(uname -r)

if [[ "$linux" == *"omlx"* ]]; then
    # Open Mandriva

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "dvd+rw-tools" "lib64dvdnav4" "lib64dvdread" "lib64dvdcss")

    ./update.sh
    # IFS=' ' read -ra my_strings <<< "$pkg_list"
    sudo dnf in "${pkg_list[@]}"

    sudo chsh -s $(which zsh) mbuel
fi

if [[ "$linux" == *"artix"* ]]; then
    # Artix
    #update first
    ./update.sh

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "libdvdcss" "libdvdnav" "libdvdread")

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]

    sudo pacman -S "${pkg_list[@]}"
fi

if [[ "$linux" == *"vendefoul"* ]]; then

    # Vendewolf
    # After installing
    ./update.sh

        # Linux specific packages
    pkg_list=("$pkg_list[@]" "libdvdcss" "libdvdnav" "libdvdread" "podman" "podman-composes")

    sudo apt-get install -y "${pkg_list[@]}"
    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi


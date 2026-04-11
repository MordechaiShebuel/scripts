#!/usr/bin/env bash

pkg_list=("zsh steam gimp obs-studio git vlc curl vlc-plugins*")
linux=$(uname -r)

if [[ "$linux" == *"omlx"* ]]; then
    # Open Mandriva

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "dvd+rw-tools" "lib64dvdnav4" "lib64dvdread" "lib64dvdcss")

    ./update.sh
    # IFS=' ' read -ra my_strings <<< "$pkg_list"
    for pkg in ${pkg_list[@]}; do
        sudo dnf in "${pkg}"
    done

    sudo chsh -s $(which zsh) mbuel
fi

if [[ "$linux" == *"artix"* ]]; then
    # Artix
    #update first - enable multilib for Steam
    ./update.sh
    ./enable_multilib.sh

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "libdvdcss" "libdvdnav" "libdvdread" "pamac" "trizen" "fakeroot")

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]
    for pkg in ${pkg_list[@]}; do
        sudo pacman -S "${pkg}"
    done

    sudo python install_nym.py
fi

if [[ "$linux" == *"deb13"* ]]; then

    # Vendewolf
    # After installing
    ./update.sh

        # Linux specific packages
    pkg_list=("$pkg_list[@]" "podman" "podman-compose")

    for pkg in ${pkg_list[@]}; do
        sudo apt-get install -y "${pkg}"
    done
    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi


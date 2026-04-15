#!/usr/bin/env bash

pkg_list=("zsh steam gimp obs-studio git vlc curl")
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
    sudo ./enable_multilib.sh

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "base-devel" "cmake" "libdvdcss" "libdvdnav" "libdvdread" "pamac" "trizen" "fakeroot" "bibletime" "signal-desktop" "telegram-desktop" "vivaldi" "vlc-plugins-all" "the_silver_searcher")

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]
    for pkg in ${pkg_list[@]}; do
        sudo pacman -S "${pkg} --noconfirm"
    done

    aur_pkg_list=("pamac-tray-icon-plasma" "ente-auth-bin" "ringracers" "srb2-bin" "firedragon-bin" "zen-browser-bin" "brave-bin")

    for pkg in ${aur_pkg_list[@]}; do
        trizen -S "${pkg} --noconfirm"
    done

    sudo python install_nym.py


fi

if [[ "$linux" == *"deb13"* ]]; then

    # Vendewolf
    # After installing
    ./update.sh

        # Linux specific packages
    pkg_list=("$pkg_list[@]" "podman" "podman-compose" "vlc-plugins*")

    for pkg in ${pkg_list[@]}; do
        sudo apt-get install -y "${pkg}"
    done
    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi


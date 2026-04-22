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
        if ! command -v "$pkg" >/dev/null 2>&1; then
            ./install.sh "${pkg}"
        fi
    done

    sudo chsh -s $(which zsh) mbuel
fi

if [[ "$linux" == *"artix"* ]]; then
    # Pre-setup for Artix / enable multilib and arch support
    sudo pacman -S pamac artix-archlinux-support --noconfirm
    sudo ./enable_multilib.sh
    sudo ./enable_extra.sh

    # Artix
    #update first
    ./update.sh

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "base-devel" "cmake" "libdvdcss" "libdvdnav" "libdvdread" "trizen" "fakeroot" "bibletime" "signal-desktop" "telegram-desktop" "vivaldi" "vlc-plugins-all" "the_silver_searcher")

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]
    for pkg in ${pkg_list[@]}; do
        # Check if app is already installed before trying to re-install it
        # pamac install "${pkg}" --no-confirm
        if ! command -v "$pkg" >/dev/null 2>&1; then
            ./install.sh "${pkg}"
        else
            echo "Skipping install of ${pkg} - it is already installed."
        fi
    done

    aur_pkg_list=("pamac-tray-icon-plasma" "ente-auth-bin" "ringracers" "srb2-bin" "firedragon-bin" "zen-browser-bin" "brave-bin" "zsh-syntax-highlighting")

    for pkg in ${aur_pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            ./install.sh "${pkg}" aur
        else
            echo "Skipping install of ${pkg} - it is already installed."
        fi
        # trizen -S "${pkg}" --noconfirm
    done

    python install_nym.py

    sudo ln -s /usr/share/zsh/plugins/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    # ERROR: warning: config file /etc/pacman.d/mirrorlist, line 101: directive 'Server' in section 'options' not recognized.

fi

if [[ "$linux" == *"deb13"* ]]; then

    # Vendewolf
    # After installing
    ./update.sh

        # Linux specific packages
    pkg_list=("$pkg_list[@]" "podman" "podman-compose" "vlc-plugins*")

    for pkg in ${pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            ./install "${pkg}"
        fi
    done
    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi

# copy setup files you want on this system, for example local scripts, ssh pub file, etc
cp -r support/* ~/

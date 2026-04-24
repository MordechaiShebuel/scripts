#!/usr/bin/env bash
# TODO: Try expanding other systems to make this platform agnostic


pkg_list=("zsh" "steam" "gimp" "obs-studio" "git" "vlc" "curl")
linux=$(uname -r)

if [[ "$linux" == *"omlx"* ]]; then
    # Open Mandriva

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "dvd+rw-tools" "lib64dvdnav4" "lib64dvdread" "lib64dvdcss")

    ./update.sh
    # IFS=' ' read -ra my_strings <<< "$pkg_list"
    for pkg in ${pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            NEEDS_INSTALL+=("$pkg")
            # ./install.sh "${pkg}"
        fi
    done

    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        sudo dnf in "${NEEDS_INSTALL[@]}"
    fi


    sudo chsh -s $(which zsh) mbuel
fi

if [[ "$linux" == *"artix"* ]]; then
    # Pre-setup for Artix / enable multilib and arch support
    sudo pacman -S pamac artix-archlinux-support --noconfirm
    sudo ./enable_repo.sh lib32
    sudo ./enable_repo.sh extra
    sudo ./enable_repo.sh multilib

    sudo pacman-key --init
    sudo pacman-key --populate archlinux
    sudo pacman -Sy

    # Artix
    #update first
    ./update.sh

    # Linux specific packages
    pkg_list=("$pkg_list[@]" "base-devel" "opus" "cmake" "libdvdcss" "libdvdnav" "libdvdread" "trizen" "fakeroot" "bibletime" "signal-desktop" "telegram-desktop" "vivaldi" "vlc-plugins-all" "the_silver_searcher")

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]
    for pkg in ${pkg_list[@]}; do
        # Check if app is already installed before trying to re-install it
        # pamac install "${pkg}" --no-confirm
        if ! pamac list --installed --quiet | grep -xFq "$pkg"; then
            NEEDS_INSTALL+=("$pkg")
        fi
    done
    pamac install "${NEEDS_INSTALL[@]}"

    # TODO:s ringracers error: -- Could NOT find Opus (missing: Opus_DIR) (should be fixed, need to test.)
    aur_pkg_list=("pamac-tray-icon-plasma" "ente-auth-bin" "ringracers" "srb2-bin" "firedragon-bin" "zen-browser-bin" "brave-bin" "zsh-syntax-highlighting")

    for pkg in ${aur_pkg_list[@]}; do
        if ! pamac list --installed --quiet | grep -xFq "$pkg"; then
            NEEDS_INSTALL+=("$pkg")
        fi
    done
    trizen -S "${NEEDS_INSTALL[@]}" --noconfirm

    python install_nym.py

    desired="/usr/share/zsh/plugins/zsh-syntax-highlighting"
    dest="$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

    if [ -L "$dest" ]; then
        if [ "$(readlink "$dest")" = "$desired" ]; then
            echo "Correct symlink already present"
        else
            echo "Symlink points to a different target ($(readlink "$dest")), updating..."
            ln -sf "$desired" "$dest"
        fi
    elif [ -e "$dest" ]; then
        echo "A file or directory exists at $dest; not creating symlink"
    else
        ln -s "$desired" "$dest"
        echo "Symlink created"
    fi

fi

if [[ "$linux" == *"deb13"* ]]; then

    # Vendewolf
    # After installing
    ./update.sh

        # Linux specific packages
    pkg_list=("$pkg_list[@]" "podman" "podman-compose" "vlc-plugins*")

    for pkg in ${pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            NEEDS_INSTALL+=("$pkg")
        fi
    done
    sudo dnf install "${NEEDS_INSTALL[@]}"
    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi

# copy setup files you want on this system, for example local scripts, ssh pub file, etc
cp -r support/* ~/

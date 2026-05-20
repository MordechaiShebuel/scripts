#!/usr/bin/env bash
# TODO: Try expanding other systems to make this platform agnostic


pkg_list=("zsh" "steam" "gimp" "obs-studio" "git" "vlc" "curl" "ktorrent")
linux=$(uname -r)

if [[ "$linux" == *"omlx"* ]]; then
    # Open Mandriva

    # Linux specific packages
    pkg_list=("${pkg_list[@]}" "dvd+rw-tools" "lib64dvdnav4" "lib64dvdread" "lib64dvdcss")

    ../system_scripts/./update.sh
    # IFS=' ' read -ra my_strings <<< "$pkg_list"

    NEEDS_INSTALL=()
    for pkg in ${pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            NEEDS_INSTALL+=("$pkg")
            ./install.sh "${pkg}"
        fi
    done

    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        sudo dnf in "${NEEDS_INSTALL[@]}"
    fi

fi

if [[ "$linux" == *"artix"* ]]; then
    # Pre-setup for Artix / enable multilib and arch support
    pre_requisites=("pamac" "artix-archlinux-support" "doas" "trizen")

    NEEDS_INSTALL=()
    for pkg in ${pre_requisites[@]}; do
        if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
            NEEDS_INSTALL+=("$pkg")
        fi
    done

    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        sudo pacman -S "${NEEDS_INSTALL[@]}" --noconfirm
    fi

    if ! pacman -Q pamac &>/dev/null 2>&1; then
        echo "Warning: pamac not installed. Unable to continue."
        exit 1
    fi

    # Enable lib32 and multilib
    output1=$(sudo ./enable_repo.sh lib32)
    output2=$(sudo ./enable_repo.sh extra)
    output3=$(sudo ./enable_repo.sh multilib)

    # Check if all three returned the expected message
    if [[ "$output1" == *"Appended [lib32] block."* ]] || \
       [[ "$output2" == *"Appended [extra] block."* ]] || \
       [[ "$output3" == *"Appended [multilib] block."* ]]; then
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
        sudo pacman -Sy
    fi

    # Artix
    #update first
    ../system_scripts/./update.sh

    # Linux specific packages
    pkg_list=("${pkg_list[@]}" "flameshot" "base-devel" "opus" "cmake" "libdvdcss" "libdvdnav" "libdvdread" "fakeroot" "bibletime" "telegram-desktop" "vlc-plugins-all" "the_silver_searcher")

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]
    NEEDS_INSTALL=()
    for pkg in ${pkg_list[@]}; do
        # Check if app is already installed before trying to re-install it
        # pamac install "${pkg}" --no-confirm
        if ! pamac list --installed --quiet | grep -xFq "$pkg"; then
            NEEDS_INSTALL+=("$pkg")
        fi
    done

    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        pamac install "${NEEDS_INSTALL[@]}"
    fi

    chsh -s $(which zsh)

    # TODO:s ringracers error: -- Could NOT find Opus (missing: Opus_DIR) (should be fixed, need to test.)
    aur_pkg_list=("pamac-tray-icon-plasma" "ente-auth-bin" "ringracers" "srb2-bin" "zen-browser-bin" "brave-bin" "zsh-syntax-highlighting" "collabora-office")

    NEEDS_INSTALL=()
    for pkg in ${aur_pkg_list[@]}; do
        if ! pamac list --installed --quiet | grep -xFq "$pkg"; then
            NEEDS_INSTALL+=("$pkg")
        fi
    done

    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        trizen -S "${NEEDS_INSTALL[@]}" --noconfirm
    fi

    # Application that setups up Nym VPN and it's OpenRC Daemon
    python install_nym.py

    # Application that setups up SSH and it's OpenRC Daemon
    python setup_remote_ssh.py

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
    # Check and add contrib repository if needed
    if ! grep -q "contrib" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "Adding contrib repository..."
        sudo sed -i 's/^deb \(.*\) main$/deb \1 main contrib non-free/' /etc/apt/sources.list
        sudo apt-get update
    fi

    # After installing
    ../system_scripts/./update.sh

    # Linux specific packages
    pkg_list=("${pkg_list[@]}" "podman" "podman-compose" "vlc-plugins*" "libdvd-pkg")

    NEEDS_INSTALL=()
    for pkg in ${pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            NEEDS_INSTALL+=("$pkg")
        fi
    done

    if [ ${#NEEDS_INSTALL[@]} -gt 0 ]; then
        sudo apt-get install "${NEEDS_INSTALL[@]}"
    fi

    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi


# copy setup files you want on this system, for example local scripts, ssh pub file, etc
yes |/bin/cp -rf support/* ~/

#!/usr/bin/env bash
# TODO: Try expanding other systems to make this platform agnostic


pkg_list=("flameshot" "htop" "wget" "zsh" "gimp" "obs-studio" "git" "vlc" "curl" "ktorrent" "system-config-printer" "hplip")
linux=$(uname -r)

if [[ "$linux" == *"omlx"* ]]; then
    # Open Mandriva

    # Linux specific packages
    pkg_list=("${pkg_list[@]}" "dvd+rw-tools" "lib64dvdnav4" "lib64dvdread" "lib64dvdcss")

    ../system_scripts/./update.sh
    # IFS=' ' read -ra my_strings <<< "$pkg_list"

    for pkg in ${pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            sudo dnf in "$pkg"
        fi
    done

fi

if [[ "$linux" == *"artix"* ]]; then
    # Pre-setup for Artix / enable multilib and arch support
    pre_requisites=("pamac" "artix-archlinux-support" "doas" "trizen")

    for pkg in ${pre_requisites[@]}; do
        if ! pacman -Q "$pkg" &>/dev/null 2>&1; then
            sudo pacman -S "$pkg"
        fi
    done

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
    pkg_list=("${pkg_list[@]}" "nss-mdns" "gvfs-smb" "samba" "smbclient" "kcalc" "steam" "base-devel" "opus" "cmake" "libdvdcss" "libdvdnav" "libdvdread" "fakeroot" "bibletime" "telegram-desktop" "vlc-plugins-all" "the_silver_searcher")

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]
    for pkg in ${pkg_list[@]}; do
        # Check if app is already installed before trying to re-install it
        # pamac install "${pkg}" --no-confirm
        if ! pamac list --installed --quiet | grep -xFq "$pkg"; then
            pamac install "$pkg"
        fi
    done

    chsh -s $(which zsh)

    # TODO:s ringracers error: -- Could NOT find Opus (missing: Opus_DIR) (should be fixed, need to test.)
    aur_pkg_list=("pamac-tray-icon-plasma" "ente-auth-bin" "ringracers" "srb2-bin" "zen-browser-bin" "brave-bin" "zsh-syntax-highlighting" "collabora-office" "zsh-autocomplete-git")

    for pkg in ${aur_pkg_list[@]}; do
        if ! pamac list --installed --quiet | grep -xFq "$pkg"; then
            trizen -S "$pkg"
        fi
    done

fi

if [[ "$linux" == *"deb13"* ]]; then

    # Enable 32-bit repos
    sudo dpkg --add architecture i386

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
    pkg_list=("${pkg_list[@]}" "zsh-syntax-highlighting" "smbclient" "gvfs" "python" "hplip" "podman" "podman-compose" "vlc-plugins*" "bibletime" "libdvd-pkg" "silversearcher-ag" "steam-libs-i386:386" "steam-installer" "zsh-syntax-highlighting")

    for pkg in ${pkg_list[@]}; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            sudo apt-get install "$pkg"
        fi
    done

    # Zen Browser:
    if ! command -v "zen-browser" >/dev/null 2>&1; then
        bash <(curl -fsSL https://raw.githubusercontent.com/MalikHw/zb-installer-script/main/install-zen.sh)
    fi

    # Brave Browser:
    if ! command -v "brave" >/dev/null 2>&1; then
        sudo apt update
        sudo apt install curl ca-certificates -y
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
        sudo apt update
        sudo apt install brave-browser -y
    fi

    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi

if [[ -d ~/.oh-my-zsh ]]; then
    # do nothing
    echo "Oh My ZSH already installed\!"
else
    echo "Installing OMZ\!"
    if curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | sh; then
        echo "OMZ Install complete."
    else
        echo "OMZ Install failes.">&2
        exit 1
    fi
fi


# Application that setups up Nym VPN and it's OpenRC Daemon (OLD METHOD)
# python install_nym.py

# Application that setups up
# Artix path (Debian requires adding repo for Nym)
python setup_app.py --service-name nym-vpnd --apps nym-vpnd-bin,nym-vpn-app-bin,nym-vpnc-bin
# Application that setups up scanner sharing
python sane_sharing.py

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

# copy setup files you want on this system, for example local scripts, ssh pub file, etc
yes | /bin/cp -rf ../support/* ~/

#!/usr/bin/env bash
# Version 2 of restore script, goal is to make it easier to add platforms.

set -u

# Read distribution information.
if [[ ! -r /etc/os-release ]]; then
    echo "Cannot determine the operating system." >&2
    exit 1
fi

. /etc/os-release

# Common packages.
pkg_list=(
    flameshot
    htop
    wget
    zsh
    gimp
    git
    vlc
    curl
    ktorrent
    smbclient
    bibletime
    zsh-syntax-highlighting
)

browser_installed() {
    local browser

    for browser in "$@"; do
        if command -v "$browser" >/dev/null 2>&1; then
            return 0
        fi
    done

    return 1
}

install_zen() {
    if browser_installed zen zen-browser; then
        echo "Zen Browser is already installed."
        return 0
    fi

    echo "Installing Zen Browser..."

    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required to install Zen Browser." >&2
        return 1
    fi

    bash <(curl -fsSL \
        https://raw.githubusercontent.com/MalikHw/zb-installer-script/main/install-zen.sh)

    if browser_installed zen zen-browser; then
        echo "Zen Browser installed!"
    else
        echo "Zen Browser installation failed." >&2
        return 1
    fi
}

install_brave_debian() {
    if browser_installed brave brave-browser; then
        echo "Brave Browser is already installed."
        return 0
    fi

    echo "Installing Brave Browser on Debian..."

    sudo apt-get update
    sudo apt-get install -y curl ca-certificates

    sudo curl -fsSLo \
        /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    sudo curl -fsSLo \
        /etc/apt/sources.list.d/brave-browser-release.sources \
        https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

    sudo apt-get update
    sudo apt-get install -y brave-browser

    if browser_installed brave brave-browser; then
        echo "Brave Browser installed!"
    else
        echo "Brave Browser installation failed." >&2
        return 1
    fi
}

install_brave_pacman() {
    if browser_installed brave brave-browser; then
        echo "Brave Browser is already installed."
        return 0
    fi

    echo "Checking for a Brave package in the configured repositories..."

    local brave_package=""

    if pacman -Si brave >/dev/null 2>&1; then
        brave_package="brave"
    elif pacman -Si brave-bin >/dev/null 2>&1; then
        brave_package="brave-bin"
    fi

    if [[ -z "$brave_package" ]]; then
        echo "Brave Browser was not found in the configured pacman repositories."
        echo "Install a compatible Brave package manually, for example through an"
        echo "AUR helper, then run this script again."
        return 1
    fi

    sudo pacman -Syu --needed "$brave_package"

    if browser_installed brave brave-browser; then
        echo "Brave Browser installed!"
    else
        echo "Brave Browser installation failed." >&2
        return 1
    fi
}

install_packages_apt() {
    local package
    local -a to_install=()

    pkg_list+=(
        python-is-python3
        pipenv
        silversearcher-ag
        steam-installer
        vlc-plugins*
        libdvd-pkg
        obs-studio
    )

    # Enable 32-bit packages for Steam and other 32-bit software.
    sudo dpkg --add-architecture i386

    sudo apt-get update

    sudo apt-get upgrade

    # Add contrib and non-free where the source format permits it.
    if ! grep -RqsE '^[[:space:]]*(deb|Components:).*contrib' \
        /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then

        echo "contrib was not detected automatically."
        echo "Check your APT repositories if packages are unavailable."
    fi

    for package in "${pkg_list[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
            grep -q "install ok installed"; then
            to_install+=("$package")
        fi
    done

    if ((${#to_install[@]} > 0)); then
        sudo apt-get install -y "${to_install[@]}"
    else
        echo "All Debian packages are already installed."
    fi
}

install_packages_pacman() {
    pkg_list+=(
        obs-studio
        dvd+rw-tools
        libdvdcss
        libdvdnav
        libdvdread
        base-devel
        vlc-plugins-all
        the_silver_searcher
        steam
        zeditor
        python-pipenv
        telegram-desktop
    )
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

    # update
    sudo pacman -Syu

    # --needed prevents reinstalling packages that are already installed.
    sudo pacman -Syu --needed "${pkg_list[@]}"
}

install_packages_xbps() {

    sudo xbps-install -Syu

    echo "repository=https://github.com/noid-linux/xbps-repo/releases/latest/download" | sudo tee /etc/xbps.d/noid-xbps-repo.conf

    sudo xbps-install -Syu void-repo-nonfree void-repo-multilib
    sudo xbps-install -Syu void-repo-multilib-nonfree
    sudo xbps-install -Su

    pkg_list+=(
        bitwarden-desktop
        brave-origin
        obs
        onlyoffice
        python
        dvd+rw-tools
        libdvdcss
        libdvdnav
        libdvdread
        kde-plasma
        smplayer
        steam
        libGL-32bit
        libpulseaudio-32bit
        libtxc_dxtn-32bit
        glibc-32bit
        libdrm-32bit
        libglvnd-32bit
        mesa-32bit
        mesa-dri-32bit
        vulkan-loader-32bit
        smplayer
        zen-browser
        nodejs
        the_silver_searcher
    )

    # AMD:
    sudo xbps-install -S mesa-vulkan-radeon mesa-vulkan-radeon-32bit

    # INTEL: (LAPTOP)
    # sudo xbps-install -S mesa-vulkan-intel mesa-vulkan-intel-32bit

    sudo xbps-install -y "${pkg_list[@]}"

    # install Zeditor:
    curl -f https://zed.dev/install.sh | sh

    # install ente-auth
    wget https://github.com/ente/ente/releases/download/auth-v4.4.25/ente-auth-v4.4.25-x86_64.AppImage &&
        sudo mkdir -p /opt/bin &&
        sudo cp ente-auth-* /opt/bin &&
        sudo chmod +x /opt/bin/ente-auth-v4.4.25-x86_64.AppImage &&
        sudo ln -s /opt/bin/ente-auth-v4.4.25-x86_64.AppImage /usr/bin/ente-auth &&
        tee ~/.local/share/applications/ente-auth.desktop <<EOF
[Desktop Entry]
Name=Ente Auth
Exec=ente-auth
Type=Application
Icon=/opt/bin/ente-auth-v4.4.25-x86_64.AppImage
Terminal=false
Categories=Utility;Security;
EOF

}

install_packages_dnf() {
    pkg_list+=(
        dvd+rw-tools
        lib64dvdnav4
        lib64dvdread
        lib64dvdcss
    )

    sudo dnf install -y "${pkg_list[@]}"
}

# Select the package manager based on /etc/os-release.
case "$ID" in
    debian|peppermint)
        echo "Detected Debian-based system: $ID"

        install_packages_apt

        # Optional desktop setup for PeppermintOS.
        if [[ "$ID" == "peppermint" ]]; then
            sudo apt-get install -y task-kde-desktop sddm
            sudo dpkg-reconfigure sddm
        fi

        install_zen
        install_brave_debian
        ;;

    void)
        echo "Detected Void Linux"

        install_packages_xbps
        install_zen

        # Brave availability varies depending on the configured Void
        # repositories and whether an AUR-style helper is being used.
        install_brave_pacman || true
        ;;

    artix)
        echo "Detected Artix Linux"

        install_packages_pacman
        install_zen
        install_brave_pacman || true
        ;;

    openmandriva)
        echo "Detected OpenMandriva"

        install_packages_dnf
        ;;

    *)
        echo "Unsupported distribution: ${ID:-unknown}" >&2
        echo "Detected values:" >&2
        echo "  ID=${ID:-unknown}" >&2
        echo "  ID_LIKE=${ID_LIKE:-unknown}" >&2
        exit 1
        ;;
esac

if [[ -d ~/.oh-my-zsh ]]; then
    # do nothing
    echo "Oh My ZSH already installed\!"
else
    echo "Installing OMZ\!"
    if curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" | sh; then
        echo "OMZ Install complete."
    else
        echo "OMZ Install fails.">&2
        exit 1
    fi
fi

sudo chsh -s "$(command -v zsh)" "$USER"

if getent passwd "$USER" | grep -qE ':/bin/zsh$'; then
    echo "Your login shell is set to zsh."
else
    echo "Your login shell is not set to zsh."
fi

# Application that setups up Nym VPN and it's OpenRC Daemon (OLD METHOD)
# python install_nym.py

# Application that setups up
# Artix path (Debian requires adding repo for Nym)

# These are failing on the debian path, pipenv command not found
if ! command -v "pipenv" >/dev/null 2>&1; then
    echo "pipenv not found, unable to install pipenv dependencies"
else
    # Install Python dependencies via pipenv from the base directory
    pipenv install
    # Application that setups up Nym VPN and it's OpenRC Daemon
    pipenv run python setup_app.py --service-name nym-vpnd --apps nym-vpnd-bin,nym-vpn-app-bin,nym-vpnc-bin
    # Application that setups up scanner sharing
    pipenv run python sane_sharing.py

    # Application that setups up SSH and it's OpenRC Daemon
    pipenv run python setup_remote_ssh.py

    if ! command -v "nym-vpnd" >/dev/null 2>&1; then
        echo "nym-vpnd not found, unable to install nym-vpnd"
    fi
    # Should check for sane_sharing success and ssh server success
    #
fi

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

echo "Restore script completed."

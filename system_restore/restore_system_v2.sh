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
    obs-studio
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
    pkg_list+=(
        dvd+rw-tools
        libdvdnav
        libdvdread
    )

    sudo xbps-install -Syu
    sudo xbps-install -y "${pkg_list[@]}"
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

echo "Restore script completed."

#!/usr/bin/env bash
# Version 3 of restore script, goal is to make it easier to add platforms.
# Update with command line options
# mode = client/server
# gpu = amd/nvidia/intel
# installed_apps_file = path to package list file, this is created prior to reinstall with bin/get_installed_apps.sh

set -Eeuo pipefail

# Color output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

mode="${1:-}"
gpu="${2:-}"
installed_apps_file="${3:-}"

log() {
  echo -e "$1"
}

if [[ -z "$mode" || -z "$gpu" || -z "$installed_apps_file" ]]; then
    log "$YELLOW Usage:$NC $GREEN $0 <mode> <gpu> <installed_apps_file> $NC" >&2
    exit 1
fi

if [[ $mode != "client" && $mode != "server" ]]; then
    log "$YELLOW Invalid mode:$NC $RED $mode $NC" >&2
    log "$YELLOW Valid modes:$NC $GREEN client, server $NC" >&2
    exit 1
fi

if [[ $gpu != "amd" && $gpu != "nvidia" && $gpu != "intel" ]]; then
    log "${YELLOW}Invalid GPU:${NC} ${RED}$gpu${NC}" >&2
    log "${YELLOW}Valid GPUs:${NC} ${GREEN}amd, nvidia, intel${NC}" >&2
    exit 1
fi

if [[ ! -r "$installed_apps_file" ]]; then
    log "${RED}Error: Package file not found or not readable: ${NC}$installed_apps_file" >&2
    exit 1
fi

# Read distribution information.
if [[ ! -r /etc/os-release ]]; then
    log "${RED}Cannot determine the operating system.${NC}" >&2
    exit 1
fi

. /etc/os-release

# Load installed packages from file
log "${GREEN}Loading packages from: ${NC}$installed_apps_file"
mapfile -t pkg_list < "$installed_apps_file"

if ((${#pkg_list[@]} == 0)); then
    log "${RED}Error: Package file is empty.${NC}" >&2
    exit 1
fi

log "${GREEN}Loaded ${#pkg_list[@]} packages.${NC}"

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
<<<<<<< Updated upstream
        log "${GREEN}Zen Browser installed!${NC}"
    else
        echo "${YELLOW}Zen Browser installation failed.${NC}" >&2
=======
        echo "Zen Browser installed!"
    else
        echo "Zen Browser installation failed." >&2
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
        log "${GREEN}Brave Browser installed!${NC}"
    else
        log "${RED}Brave Browser installation failed.${NC}" >&2
=======
        echo "${GREEN}Brave Browser installed!${NC}"
    else
        echo "${RED}Brave Browser installation failed.${NC}" >&2
>>>>>>> Stashed changes
        return 1
    fi
}

install_brave_pacman() {
    if browser_installed brave brave-browser; then
<<<<<<< Updated upstream
        log "${YELLOW}Brave Browser is already installed.${NC}"
        return 0
    fi

    log "Checking for a ${GREEN}Brave${NC} package in the configured repositories..."
=======
        echo "${YELLOW}Brave Browser is already installed.${NC}"
        return 0
    fi

    echo "Checking for a ${GREEN}Brave${NC} package in the configured repositories..."
>>>>>>> Stashed changes

    local brave_package=""

    if pacman -Si brave >/dev/null 2>&1; then
        brave_package="brave"
    elif pacman -Si brave-bin >/dev/null 2>&1; then
        brave_package="brave-bin"
    fi

    if [[ -z "$brave_package" ]]; then
<<<<<<< Updated upstream
        log "Brave Browser was not found in the configured pacman repositories."
        log "Install a compatible Brave package manually, for example through an"
        log "AUR helper, then run this script again."
=======
        echo "Brave Browser was not found in the configured pacman repositories."
        echo "Install a compatible Brave package manually, for example through an"
        echo "AUR helper, then run this script again."
>>>>>>> Stashed changes
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

    # Enable 32-bit packages for Steam and other 32-bit software.
    sudo dpkg --add-architecture i386

    sudo apt-get update

    sudo apt-get upgrade

    # Add contrib and non-free where the source format permits it.
    if ! grep -RqsE '^[[:space:]]*(deb|Components:).*contrib' \
        /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then

        log "$YELLOW contrib was not detected automatically. $NC"
        echo "$YELLOW Check your APT repositories if packages are unavailable. $NC"
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

<<<<<<< Updated upstream
    # Needs a guard, don't do if done.
=======
>>>>>>> Stashed changes
    echo "repository=https://github.com/noid-linux/xbps-repo/releases/latest/download" | sudo tee /etc/xbps.d/noid-xbps-repo.conf
    echo 'repository=https://voidrepo.linuxnauta.com' | sudo tee /etc/xbps.d/linuxnauta.conf
    echo "repository=https://repo.voiders.dev" | sudo tee /etc/xbps.d/voiders-dev-repo.conf
    echo "repository=https://sourceforge.net/projects/neko-void/files/repo" | sudo tee /etc/xbps.d/neko-void.conf

    sudo xbps-install -Syu void-repo-nonfree void-repo-multilib
<<<<<<< Updated upstream
    sudo xbps-install -Syu

    sudo xbps-install -Su

    case $gpu in
    amd)
        sudo xbps-install -y mesa-vulkan-radeon mesa-vulkan-radeon-32bit LACT
        ;;
    nvidia)
        sudo xbps-install -y mesa-vulkan-nvidia mesa-vulkan-nvidia-32bit
        ;;
    intel)
        sudo xbps-install -y mesa-vulkan-intel mesa-vulkan-intel-32bit
        ;;
    esac

    local failed=()

=======
    sudo xbps-install -Syu void-repo-multilib-nonfree
    sudo xbps-install -Su

    case $gpu in
    amd)
        sudo xbps-install -y mesa-vulkan-radeon mesa-vulkan-radeon-32bit LACT
        ;;
    nvidia)
        sudo xbps-install -y mesa-vulkan-nvidia mesa-vulkan-nvidia-32bit
        ;;
    intel)
        sudo xbps-install -y mesa-vulkan-intel mesa-vulkan-intel-32bit
        ;;
    esac

    local failed=()

>>>>>>> Stashed changes
    echo "Attempting to install packages for Void."
    for pkg in "${pkg_list[@]}"; do
        log "$YELLOW Installing: $NC $GREEN $pkg $NC"

        if ! sudo xbps-install -y "$pkg"; then
            failed+=("$pkg")
        fi
    done

    if ((${#failed[@]})); then
        log "$RED The following packages failed to install: $RED" >&2
<<<<<<< Updated upstream
        log "$RED${failed[@]}$NC"
        # exit 0 # Need a determination here not to hard fail.
    fi

    ./install_zeditor.sh

    if xbps-query -p pkgver sddm >/dev/null 2>&1 &&
    [ -L /var/service/sddm ] &&
    sv status sddm >/dev/null 2>&1; then
        log "$YELLOW SDDM is already installed and running. $NC"
    else
        sudo xbps-install -S sddm

        if xbps-query -p pkgver lightdm >/dev/null 2>&1 &&
        [ -L /var/service/lightdm ]; then
            log "$YELLOW Stopping and disabling LightDM... $NC"
            sudo sv down lightdm
            sudo rm -f /var/service/lightdm
        fi

        if [ ! -e /var/service/sddm ]; then
            sudo ln -s /etc/sv/sddm /var/service/sddm
        fi

        sudo sv up sddm
    fi

    ./setup_cron_void.sh $GREEN $NC

    ./install_ente_auth.sh

    ./install_avahi.sh

    ./enable_cups.sh

    ./linux-cachyos-void-patch.sh
}

install_packages_dnf() {
    sudo dnf install -y "${pkg_list[@]}"
    echo "server.lan" | sudo tee /etc/sane.d/net.conf
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

    void|vostok|lazylinux)
        echo "Detected Void Linux"

        install_packages_xbps
        # install_zen

        # Brave availability varies depending on the configured Void
        # repositories and whether an AUR-style helper is being used.
        # install_brave_pacman || true
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

case $mode in
    server)
        ./server_setup.sh
        ;;
    client)
        ./client_setup.sh $USER
        ;;
esac

./zsh_setup.sh $USER

=======
        printf '%s %s %s\n ' "$RED" "${failed[@]}" "                $NC" >&2
        exit 1
    fi

    ./install_zeditor.sh

    if xbps-query -p pkgver sddm >/dev/null 2>&1 &&
    [ -L /var/service/sddm ] &&
    sv status sddm >/dev/null 2>&1; then
        log "$YELLOW SDDM is already installed and running. $NC"
    else
        sudo xbps-install -S sddm

        if xbps-query -p pkgver lightdm >/dev/null 2>&1 &&
        [ -L /var/service/lightdm ]; then
            log "$YELLOW Stopping and disabling LightDM... $NC"
            sudo sv down lightdm
            sudo rm -f /var/service/lightdm
        fi

        if [ ! -e /var/service/sddm ]; then
            sudo ln -s /etc/sv/sddm /var/service/sddm
        fi

        sudo sv up sddm
    fi

    ./setup_cron_void.sh $GREEN $NC

    ./install_ente_auth.sh

    ./install_avahi.sh

    ./enable_cups.sh

    ./linux-cachyos-void-patch.sh
}

install_packages_dnf() {
    sudo dnf install -y "${pkg_list[@]}"
    echo "server.lan" | sudo tee /etc/sane.d/net.conf
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

    void|vostok)
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

case $mode in
    server)
        ./server_setup.sh
        ;;
    client)
        ./client_setup.sh $USER
        ;;
esac

./zsh_setup.sh $USER

>>>>>>> Stashed changes
if ! command -v "pipenv" >/dev/null 2>&1; then
    echo "pipenv not found, unable to install pipenv dependencies"
else
    # Install Python dependencies via pipenv from the base directory
    pipenv install

    # Application that setups up SSH and it's OpenRC Daemon
    pipenv run python setup_remote_ssh.py

    if ! command -v "nym-vpnd" >/dev/null 2>&1; then
        echo "nym-vpnd not found, unable to install nym-vpnd"
    fi
fi

# copy setup files you want on this system, for example local scripts, ssh pub file, etc
./bin_setup.sh

echo "Restore script completed."

echo "You should reboot now."

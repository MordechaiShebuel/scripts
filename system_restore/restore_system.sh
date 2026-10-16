#!/usr/bin/env bash
# Version 3 of restore script, goal is to make it easier to add platforms.
# Update with command line options
# mode = client/server
# gpu = amd/nvidia/intel
# installed_apps_file = path to package list file, this is created prior to reinstall with bin/get_installed_apps.sh

set -Eeuo pipefail

# Get color support
. ./support/./colors.sh

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

# Configure third-party repositories and install the required repository packages
# only if this has not already been done.
    ./support/./enable_void_repo.sh

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

    echo "Attempting to install packages for Void."
    for pkg in "${pkg_list[@]}"; do
        log "$YELLOW Installing: $NC $GREEN $pkg $NC"

        if ! sudo xbps-install -y "$pkg"; then
            failed+=("$pkg")
        fi
    done

    if ((${#failed[@]})); then
        log "$RED The following packages failed to install: $RED" >&2
        log "$RED${failed[@]}$NC"
        # exit 0 # Need a determination here not to hard fail.
    fi

    ./support/./install_zeditor.sh

    ./support/./setup_cron_void.sh $GREEN $NC

    ./support/./install_ente_auth.sh

    ./support/./install_avahi.sh

    ./support/./enable_cups.sh

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

        ./support/./zen_browser_installer.sh
        ./support/./brave_debian_installer.sh
        ;;

    void|vostok|lazylinux|noid)
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
        ./support/./zen_browser_installer.sh
        ./support/./brave_arch_installer.sh || true
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
        ./support/./server_setup.sh
        ;;
    client)
        ./support/./client_setup.sh $USER
        ;;
esac

./support/./zsh_setup.sh $USER

# Need to think about how I want to approach this section
# if ! command -v "pipenv" >/dev/null 2>&1; then
#     echo "pipenv not found, unable to install pipenv dependencies"
# else
#     # Install Python dependencies via pipenv from the base directory
#     pipenv install
#
#     # Application that setups up SSH and it's OpenRC Daemon
#     pipenv run python setup_remote_ssh.py
#
#     if ! command -v "nym-vpnd" >/dev/null 2>&1; then
#         echo "nym-vpnd not found, unable to install nym-vpnd"
#     fi
# fi

# copy setup files you want on this system, for example local scripts, ssh pub file, etc
./support/./bin_setup.sh

echo "Restore script completed."

echo "You should reboot now."

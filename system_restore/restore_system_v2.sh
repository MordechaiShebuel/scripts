#!/usr/bin/env bash
# Version 2 of restore script, goal is to make it easier to add platforms.
# Update with command line options
# mode = client/server
# gpu = amd/nvidia/intel

set -Eeuo pipefail

# Color output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

mode="${1:-clients}"
gpu="${2:-amd}"

log() {
  echo -e "$1"
}

if [[ $mode != "client" && $mode != "server" ]]; then
    log "$YELLOW Invalid mode:$NC $RED $mode $NC" >&2
    log "$YELLOW Usage:$NC $GREEN $0 <mode> <gpu> $NC" >&2
    exit 1
fi

if [[ $gpu != "amd" && $gpu != "nvidia" && $gpu != "intel" ]]; then
    log "${YELLOW}Invalid GPU:${NC} ${RED}$gpu${NC}" >&2
    log "${YELLOW}Usage:${NC} ${GREEN}$0 <mode> <gpu>${NC}" >&2
    exit 1
fi

# Read distribution information.
if [[ ! -r /etc/os-release ]]; then
    log "${YELLOW}Cannot determine the operating system.{$NC}" >&2
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
    kvirc
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
        echo "{$GREEN}Brave Browser installed!{$NC}"
    else
        echo "${RED}Brave Browser installation failed.${NC}" >&2
        return 1
    fi
}

install_brave_pacman() {
    if browser_installed brave brave-browser; then
        echo "${YELLOW}Brave Browser is already installed.${NC}"
        return 0
    fi

    echo "Checking for a ${GREEN}Brave${NC} package in the configured repositories..."

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
        hplip
        sane-utils
        sane-daemon
    )

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
        sane-utilspkg_list
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
        openbsd-netcat
        nfs-utils
        cups
        cups-filters
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
        nano
        vulkan-loader-32bit
        smplayer
        zen-browser
        nodejs
        the_silver_searcher
        falkon
        telegram-desktop
        sane
        skanpage
        cronie
        lact
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

install_packages_xbps() { # There is a serious bug in this code, if one of the packages is missing it doesn't bubble up and just rams through the other changes.

    sudo xbps-install -Syu

    echo "repository=https://github.com/noid-linux/xbps-repo/releases/latest/download" | sudo tee /etc/xbps.d/noid-xbps-repo.conf
    echo 'repository=https://voidrepo.linuxnauta.com' | sudo tee /etc/xbps.d/linuxnauta.conf
    echo "repository=https://repo.voiders.dev" | sudo tee /etc/xbps.d/voiders-dev-repo.conf
    echo "repository=https://sourceforge.net/projects/neko-void/files/repo" | sudo tee /etc/xbps.d/neko-void.conf

    sudo xbps-install -Syu void-repo-nonfree void-repo-multilib
    sudo xbps-install -Syu void-repo-multilib-nonfree
    sudo xbps-install -Su

    pkg_list+=(
        python3-pipenv
        bitwarden-desktop
        brave-origin
        cronie
        cups
        cups-filters
        dvd+rw-tools
        falkon
        glibc-32bit
        libdrm-32bit
        libdvdcss
        libdvdnav
        libdvdread
        libGL-32bit
        libglvnd-32bit
        libpulseaudio-32bit
        libtxc_dxtn-32bit
        linux-cachyos
        linux-cachyos-headers
        mesa-32bit
        mesa-dri-32bit
        nano
        Neko-Kernel-Manager
        nfs-utils
        nodejs
        obs
        onlyoffice
        openbsd-netcat
        python
        sane
        skanpage
        steam
        telegram-desktop
        the_silver_searcher
        vulkan-loader-32bit
        zen-browser
    )


    case $gpu in
    amd)
        pkg_list+=(mesa-vulkan-radeon mesa-vulkan-radeon-32bit LACT)
        ;;
    nvidia)
        pkg_list+=(mesa-vulkan-nvidia mesa-vulkan-nvidia-32bit)
        ;;
    intel)
        pkg_list+=(mesa-vulkan-intel mesa-vulkan-intel-32bit)
        ;;
    esac

    failed=()

    echo "Attempting to install packages for Void."
    for pkg in "${pkg_list[@]}"; do
        log "$BLUE Installing: $NC $GREEN $pkg $NC"

        if ! sudo xbps-install -y "$pkg"; then
            failed+=("$pkg")
        fi
    done

    if ((${#failed[@]})); then
        log "$RED The following packages failed to install: $RED" >&2
        printf '%s %s %s\n ' "$RED" "${failed[@]}" "                $NC" >&2
        exit 1
    fi


    # install Zeditor:
    if ! command -v zed >/dev/null 2>&1; then
        log "$GREEN Installing Zed - Editor $NC"
        curl -f https://zed.dev/install.sh | sh
    else
        log "$YELLOW Zed already installed $YELLOW"
    fi

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

    # Cron setup
    if [ ! -L /var/service/cronie ]; then
        sudo ln -s /etc/sv/cronie /var/service/cronie
    fi

    # Wait for runit to notice the new service
    for _ in 1 2 3 4 5; do
        if sudo sv status cronie >/dev/null 2>&1; then
            log "$GREEN Cronie running properly! $NC"
            break
        fi
        sleep 1
    done

    # This is used for file sharing as well:
    sudo ln -s /etc/sv/rpcbind /var/service/rpcbind 2>/dev/null
    sudo ln -s /etc/sv/statd /var/service/statd 2>/dev/null


    if ! command -v ente-auth >/dev/null 2>&1; then
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
        echo "Ente-Auth installed"
    else
        echo "Ente-Auth already installed."
    fi

    # Install and enable Avahi
    if ! xbps-query -p pkgver avahi >/dev/null 2>&1; then
        sudo xbps-install -y avahi
    else
        echo "avahi is already installed."
    fi

    if [ ! -e /var/service/avahi-daemon ]; then
        sudo ln -s /etc/sv/avahi-daemon /var/service/avahi-daemon
    else
        echo "avahi-daemon is already enabled."
    fi

    if sv status avahi-daemon >/dev/null 2>&1; then
        echo "avahi-daemon is already running."
    else
        sudo sv up avahi-daemon
    fi

    # Install and enable CUPS
    if ! xbps-query -p pkgver cups >/dev/null 2>&1; then
        sudo xbps-install -S
        sudo xbps-install -y cups cups-filters print-manager system-config-printer
    else
        echo "CUPS is already installed."
    fi

    if [ ! -e /var/service/cupsd ]; then
        sudo ln -s /etc/sv/cupsd /var/service/cupsd
    fi

    if sv status cupsd >/dev/null 2>&1; then
        echo "cupsd is already running."
    else
        sudo sv up cupsd
    fi

    echo "Fix Cachyos kernel bug so it shows up at boot."
    #kernel fix
    sudo cp /usr/lib/modules/6.18.5-1-cachyos/vmlinuz /boot/vmlinuz-6.18.5-1-cachyos
    sudo depmod 6.18.5-1-cachyos
    sudo dracut -f /boot/initramfs-6.18.5-1-cachyos.img 6.18.5-1-cachyos
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}



install_packages_dnf() {
    pkg_list+=(
        dvd+rw-tools
        lib64dvdnav4
        lib64dvdread
        lib64dvdcss
    )echo server.lan | sudo tee /etc/sane.d/net.conf


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

# Application that setups up Nym VPN and it's OpenRC Daemon (OLD METHOD)
# python install_nym.py

# Application that setups up
# Artix path (Debian requires adding repo for Nym)
#
# Setup SSH key from client to this host:
# scp .ssh/id_ed25519.pub USER@client.lan:/home/USER/

# These are failing on the debian path, pipenv command not found
if ! command -v "pipenv" >/dev/null 2>&1; then
    echo "pipenv not found, unable to install pipenv dependencies"
else
    # Install Python dependencies via pipenv from the base directory
    pipenv install
    # Application that setups up Nym VPN and it's OpenRC Daemon
    # pipenv run python setup_app.py --service-name nym-vpnd --apps nym-vpnd-bin,nym-vpn-app-bin,nym-vpnc-bin
    # Application that setups up scanner sharing
    # pipenv run python sane_sharing.py

    # Application that setups up SSH and it's OpenRC Daemon
    pipenv run python setup_remote_ssh.py

    if ! command -v "nym-vpnd" >/dev/null 2>&1; then
        echo "nym-vpnd not found, unable to install nym-vpnd"
    fi
    # Should check for sane_sharing success and ssh server success
    #
fi

# copy setup files you want on this system, for example local scripts, ssh pub file, etc
./bin_setup.sh

echo "Restore script completed."

echo "You should reboot now."

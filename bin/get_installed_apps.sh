#!/usr/bin/env bash

# Read distribution information.
if [[ ! -r /etc/os-release ]]; then
    echo "Cannot determine the operating system." >&2
    exit 1
fi

. /etc/os-release

pkg=$1
option=$2

# Create output directory if it doesn't exist
mkdir -p "$HOME/.local/share"

# Select the package manager based on /etc/os-release.
case "$ID" in
    debian|peppermint|devuan)
        echo "Detected Debian-based system: $ID"

        dpkg-query -W -f='${Package}\n' > "$HOME/.local/share/.installed_apps"
        ;;

    void|vostok)
        echo "Detected Void Linux"

        xbps-query --list-manual-pkgs > "$HOME/.local/share/.installed_apps"
        ;;

    artix|arch|manjaro)
        echo "Detected Artix Linux"

        pacman -Qqe > "$HOME/.local/share/.installed_apps"
        ;;

    openmandriva)
        echo "Detected OpenMandriva"

        dnf list installed | awk '{print $1}' > "$HOME/.local/share/.installed_apps"
        ;;

    *)
        echo "Unsupported distribution: ${ID:-unknown}" >&2
        echo "Detected values:" >&2
        echo "  ID=${ID:-unknown}" >&2
        echo "  ID_LIKE=${ID_LIKE:-unknown}" >&2
        exit 1
        ;;
esac

echo "Generated package list: $HOME/.local/share/.installed_apps"

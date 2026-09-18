#!/usr/bin/env bash

# Read distribution information.
if [[ ! -r /etc/os-release ]]; then
    echo "Cannot determine the operating system." >&2
    exit 1
fi

. /etc/os-release

pkg=$1
option=$2

OUTPUT_DIR="$HOME/.local/share/installed_apps"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Select the package manager based on /etc/os-release.
case "$ID" in
    debian|peppermint|devuan)
        echo "Detected Debian-based system: $ID"

        dpkg-query -W -f='${Package}\n' > "$OUTPUT_DIR/installed_apps.txt"
        ;;

    void|vostok|lazylinux)
        echo "Detected Void Linux"

        xbps-query --list-manual-pkgs > "$OUTPUT_DIR/installed_apps.txt"
        ;;

    artix|arch|manjaro)
        echo "Detected Artix Linux"

        pacman -Qqe > "$OUTPUT_DIR/installed_apps.txt"
        ;;

    openmandriva)
        echo "Detected OpenMandriva"

        dnf list installed | awk '{print $1}' > "$OUTPUT_DIR/installed_apps.txt"
        ;;

    *)
        echo "Unsupported distribution: ${ID:-unknown}" >&2
        echo "Detected values:" >&2
        echo "  ID=${ID:-unknown}" >&2
        echo "  ID_LIKE=${ID_LIKE:-unknown}" >&2
        exit 1
        ;;
esac

echo "Generated package list: $OUTPUT_DIR/installed_apps.txt"

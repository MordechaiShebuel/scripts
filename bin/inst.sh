#!/usr/bin/env bash

# Read distribution information.
if [[ ! -r /etc/os-release ]]; then
    echo "Cannot determine the operating system." >&2
    exit 1
fi

. /etc/os-release

# Guard: Check if package argument is provided
if [[ -z "$1" ]]; then
    echo "Error: No package(s) specified." >&2
    echo "" >&2
    echo "Usage: $0 <package(s)>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 package1                              # Single package" >&2
    echo "  $0 'package1 package2 package3'          # Space-separated" >&2
    echo "  $0 'package1,package2,package3'          # Comma-separated" >&2
    echo "  $0 'package1, package2, package3'        # Comma-separated with spaces" >&2
    exit 1
fi

# Convert input to array, handling both space and comma separation
IFS=',' read -ra pkg_array <<< "$1"
for i in "${!pkg_array[@]}"; do
    pkg_array[$i]=$(echo "${pkg_array[$i]}" | xargs)  # Trim whitespace
done

# Select the package manager based on /etc/os-release.
case "$ID" in
    debian|peppermint|devuan)
        echo "Detected Debian-based system: $ID"
        sudo apt-get install -y "${pkg_array[@]}"
        ;;

    void|vostok|lazylinux|noid)
        echo "Detected Void Linux"
        sudo xbps-install -Sy "${pkg_array[@]}"
        ;;

    artix|arch|manjaro)
        echo "Detected Artix Linux"
        sudo pacman -S --noconfirm "${pkg_array[@]}"
        ;;

    openmandriva)
        echo "Detected OpenMandriva"
        sudo dnf install -y "${pkg_array[@]}"
        ;;

    *)
        echo "Unsupported distribution: ${ID:-unknown}" >&2
        echo "Detected values:" >&2
        echo "  ID=${ID:-unknown}" >&2
        echo "  ID_LIKE=${ID_LIKE:-unknown}" >&2
        exit 1
        ;;
esac

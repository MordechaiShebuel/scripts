# Read distribution information.
if [[ ! -r /etc/os-release ]]; then
    echo "Cannot determine the operating system." >&2
    exit 1
fi

. /etc/os-release

pkg=$1
option=$2

# Select the package manager based on /etc/os-release.
case "$ID" in
    debian|peppermint|devuan)
        echo "Detected Debian-based system: $ID"
        sudo apt autoremove
        sudo apt clean
        ;;

    void|vostok)
        echo "Detected Void Linux"

        sudo xbps-remove -yO
        sudo xbps-remove -yo
        ;;

    artix|arch|manjaro)
        echo "Detected Artix Linux"
        sudo pacman -Rns $(pacman -Qdtq) && sudo pacman -Sc
        ;;

    openmandriva)
        echo "Detected OpenMandriva"

        sudo dnf autoremove && sudo dnf clean all

        ;;

    *)
        echo "Unsupported distribution: ${ID:-unknown}" >&2
        echo "Detected values:" >&2
        echo "  ID=${ID:-unknown}" >&2
        echo "  ID_LIKE=${ID_LIKE:-unknown}" >&2
        exit 1
        ;;
esac

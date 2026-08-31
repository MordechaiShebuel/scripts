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
    debian|peppermint)
        echo "Detected Debian-based system: $ID"
        sudo apt-get update
        sudo apt-get upgrade
        ;;

    void)
        echo "Detected Void Linux"

        sudo xbps-install -Su
        ;;

    artix)
        echo "Detected Artix Linux"

        sudo pamac update
        ;;

    openmandriva)
        echo "Detected OpenMandriva"

        sudo dnf clean all ; sudo dnf dsync --allowerasing -x kernel-desktop

        ;;

    *)
        echo "Unsupported distribution: ${ID:-unknown}" >&2
        echo "Detected values:" >&2
        echo "  ID=${ID:-unknown}" >&2
        echo "  ID_LIKE=${ID_LIKE:-unknown}" >&2
        exit 1
        ;;
esac

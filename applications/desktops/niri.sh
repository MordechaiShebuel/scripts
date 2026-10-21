# 0.01 Setup for Niri to function like Hyprland
# Initial version is working, not sure why people like Niri over Hyprland. Window "scrolling" is obnoxious, the way windows move super unintuitive.
# Rendering effects look just awful
# Steam doesn't function, missing X11 portal that is enabled in Hyprland
#
# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should NOT be run as root!"
    exit 1
fi

# can be manually set
TERMINAL="rio"
FILE_MANAGER="caja"
SHELL="noctalia"

echo "Updating System before beginning"
# Update repos and system first
sudo xbps-install -Syu

sudo xbps-install -S \
    niri-d77 \
    xdotool \
    kvantum \
    nwg-look \
    $TERMINAL \
    $FILE_MANAGER \
    xdg-desktop-portal \
    $SHELL \
    xorg-server-xwayland \
    xorg-fonts \
    font-awesome \
    font-inter \
    font-inter-variable \
    gnome-keyring \
    papirus-icon-theme \
    qt6ct \
    hyprland-qt-support \
    accountsservice \
    brightnessctl \
    playerctl \
    pamixer \
    blueman

#!/bin/sh
# Remove unwanted Plasma / KDE components + clean leftover settings
# Keeps: Ark, Falkon, Gwenview, KTorrent, KVIrc

set -e

echo "==> Removing Plasma desktop, frameworks and agents..."



sudo xbps-remove -y \
  bluedevil \
  discover \
  dolphin \
  flatpak-kcm \
  gwenview \
  kdeconnect \
  kdeconnect-kde \
  kde-plasma \
  kdeplasma-addons \
  kglobalshortcuts \
  konsole \
  kscreen \
  kscreenlocker \
  kworkspace \
  kio-extras \
  kwin \
  kwin-x11 \
  libplasma \
  milou \
  plasma-activities \
  plasma-activities-stats \
  plasma-desktop \
  plasma-framework \
  plasma-nm \
  plasma-pa \
  plasma-wayland-protocols \
  plasma-workspace \
  plasma-workspace-x11 \
  plasma5support \
  polkit-kde-agent \
  powerdevil \
  pulseaudio-qt \
  sddm \
  sddm-kcm \
  systemsettings \
  xdg-desktop-portal-kde \
  flatpak

# BUG:
# Removes SDDM and without alternate setup, this will cause boot issues
# Removes pulseaudio-qt, could also cause issues
#
# patch until get an alternate dm:
sudo xbps-install elogind sddm font-hack-ttf noto-fonts-ttf noto-fonts-emoji

echo "==> Removing KDE applications you no longer need..."
sudo xbps-remove -Ry \
  dolphin \
  konsole \
  yakuake \
  kwrite \
  spectacle \
  skanpage \
  kpmcore

# Optional – uncomment if you also want to drop these
# sudo xbps-remove -Ry sddm kvantum

echo "==> Cleaning orphaned packages..."
sudo xbps-remove -o

echo "==> Cleaning leftover KDE/Plasma configuration and data..."

# --- Config directories (~/.config) ---
rm -rf \
  ~/.config/plasma* \
  ~/.config/kwin* \
  ~/.config/kded* \
  ~/.config/kglobal* \
  ~/.config/kcm* \
  ~/.config/dolphinrc \
  ~/.config/dolphin* \
  ~/.config/konsolerc \
  ~/.config/konsole* \
  ~/.config/yakuakerc \
  ~/.config/yakuake* \
  ~/.config/kwriterc \
  ~/.config/kwrite* \
  ~/.config/spectaclerc \
  ~/.config/spectacle* \
  ~/.config/skanpage* \
  ~/.config/discover* \
  ~/.config/session/ \
  ~/.config/kactivitymanagerd* \
  ~/.config/kconf_updaterc \
  ~/.config/kdeglobals \
  ~/.config/kiorc \
  ~/.config/kioslaverc \
  ~/.config/ktimezonedrc \
  ~/.config/plasma-localerc \
  ~/.config/plasma-org.kde.plasma.desktop-appletsrc \
  ~/.config/plasmanotifyrc \
  ~/.config/plasmashellrc \
  ~/.config/powerdevilrc \
  ~/.config/systemsettingsrc

# --- Data directories (~/.local/share) ---
rm -rf \
  ~/.local/share/dolphin \
  ~/.local/share/konsole \
  ~/.local/share/yakuake \
  ~/.local/share/kwrite \
  ~/.local/share/spectacle \
  ~/.local/share/skanpage \
  ~/.local/share/discover \
  ~/.local/share/plasma* \
  ~/.local/share/kactivitymanagerd \
  ~/.local/share/kxmlgui5 \
  ~/.local/share/kservices5 \
  ~/.local/share/knewstuff3 \
  ~/.local/share/kpackage \
  ~/.local/share/kwalletd \
  ~/.local/share/kcookiejar

# --- Cache ---
rm -rf \
  ~/.cache/plasma* \
  ~/.cache/dolphin \
  ~/.cache/konsole \
  ~/.cache/yakuake \
  ~/.cache/kwrite \
  ~/.cache/spectacle \
  ~/.cache/skanpage \
  ~/.cache/discover \
  ~/.cache/kio* \
  ~/.cache/krunner

# --- Older KDE leftovers (just in case) ---
rm -rf \
  ~/.kde \
  ~/.kde4

echo "==> Done."
echo "Kept packages: ark, falkon, gwenview, ktorrent, kvirc"
echo "You may want to log out and back in (or reboot) for a fully clean session."

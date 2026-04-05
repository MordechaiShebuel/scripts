#!/usr/bin/env bash
set -euo pipefail

PACMAN_CONF="/etc/pacman.conf"
BACKUP="/etc/pacman.conf.bak.$(date +%Y%m%d%H%M%S)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root."
  exit 1
fi

# Backup
cp -a "$PACMAN_CONF" "$BACKUP"
echo "Backed up $PACMAN_CONF -> $BACKUP"

# Define multilib block (Artix uses [lib32] on some repos; use [multilib] compatible with Arch/Artix)
read -r -d '' MULTILIB <<'EOF'

#################################################################
# 32-bit compatibility repository
[multilib]
Include = /etc/pacman.d/mirrorlist
#################################################################
EOF

# Add or enable multilib
if grep -Pzoq "(?s)^\[multilib\].*?Include\s*=\s*/etc/pacman.d/mirrorlist" "$PACMAN_CONF"; then
  echo "[multilib] already present and enabled in $PACMAN_CONF"
else
  if grep -Pzoq "(?s)^\[multilib\].*" "$PACMAN_CONF"; then
    # If present but commented, uncomment the block
    sed -i '/^\s*#\s*\[multilib\]/,/\[/{ s/^\s*#\s*//g }' "$PACMAN_CONF" || true
    sed -i '/^\s*#\s*Include\s*=.*mirrorlist/ s/^\s*#\s*//g' "$PACMAN_CONF" || true
    echo "Uncommented existing [multilib] block."
  else
    # Append block
    printf "%s\n" "$MULTILIB" >> "$PACMAN_CONF"
    echo "Appended [multilib] block to $PACMAN_CONF"
  fi
fi

# Update keyring and sync DB
echo "Refreshing keyring and updating package database..."
pacman -Sy archlinux-keyring --noconfirm || true
pacman -Sy --noconfirm

echo "Done. You can now install 32-bit packages, e.g. 'pacman -S lib32-glibc' or 'lib32-<package>'."

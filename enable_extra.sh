#!/usr/bin/env bash
set -euo pipefail

PACMAN_CONF="/etc/pacman.conf"
BACKUP="/etc/pacman.conf.bak.$(date +%Y%m%d%H%M%S)"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

cp -a "$PACMAN_CONF" "$BACKUP"
echo "Backup saved to $BACKUP"

# Check for an enabled lib32 Include line
if grep -Eqs '^\s*\[extra\]\s*$' "$PACMAN_CONF" && grep -Eqs '^\s*Include\s*=\s*/etc/pacman.d/mirrorlist\s*$' "$PACMAN_CONF"; then
  echo "[extra] already enabled."
else
  # If there's a commented extra block, uncomment it
  if grep -Eqs '^#\[extra\]$' "$PACMAN_CONF" || grep -Eqs '^\s*#\s*Include\s*=\s*/etc/pacman.d/mirrorlist\s*$' "$PACMAN_CONF"; then
    # Uncomment lines that start with # and contain [extra] or Include = /etc/pacman.d/mirrorlist
    sed -i -E 's/^#(\[extra\])/\1/' "$PACMAN_CONF" || true
    sed -i -E 's/^#(Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist[[:space:]]*)/\1/' "$PACMAN_CONF" || true
    echo "Uncommented existing [extra] block."
  elif grep -Eqs '^#\[multilib\]$' "$PACMAN_CONF" || grep -Eqs '^\s*#\s*Include\s*=\s*/etc/pacman.d/mirrorlist\s*$' "$PACMAN_CONF"; then
    # Uncomment lines that start with # and contain [extra] or Include = /etc/pacman.d/mirrorlist
    sed -i -E 's/^#(\[multilib\])/\1/' "$PACMAN_CONF" || true
    sed -i -E 's/^#(Include[[:space:]]*=[[:space:]]*\/etc\/pacman.d\/mirrorlist[[:space:]]*)/\1/' "$PACMAN_CONF" || true
    echo "Uncommented existing [multilib] block."
  else
    # Append block
    cat >> "$PACMAN_CONF" <<'EOF'

#################################################################

# Arch compatibility
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch
#################################################################
EOF
    echo "Appended [extra] block."
  fi
fi

# Refresh keyring and update DB
echo "Refreshing keyring and syncing package databases..."
pacman -Sy archlinux-keyring --noconfirm || true
pacman -Syy --noconfirm

echo "Done."

#!/usr/bin/env bash
set -euo pipefail

PACMAN_CONF="/etc/pacman.conf"
BACKUP="/etc/pacman.conf.bak.$(date +%Y%m%d%H%M%S)"
REPO="$1"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Run as root." >&2
  exit 1
fi

cp -a "$PACMAN_CONF" "$BACKUP"
echo "Backup saved to $BACKUP"

# Check if [extra] with Include already enabled
if grep -q "^\[$REPO\]$" "$PACMAN_CONF" && \
   grep -q "^[[:space:]]*Include[[:space:]]*=[[:space:]]*/etc/pacman.d/mirrorlist" "$PACMAN_CONF"; then
    echo "[$REPO] enabled"
else
  echo "[$REPO] not enabled."

  # Try to uncomment a commented [extra] or [multilib] header and the first Include inside it
  awk -v repo="$REPO" '
  /^\[.*\]$/ {
      in_target = 0
  }
  /^#\[.*\]$/ {
      if ("[" repo "]" == gensub(/^#/, "", 1)) {
          gsub(/^#[[:space:]]*/, "")
          in_target = 1
          uncommented = 1
      } else {
          in_target = 0  # Do not touch other commented sections
      }
  }
  in_target && /^#?[[:space:]]*Include[[:space:]]*=[[:space:]]*\/etc\/pacman\.d\/mirrorlist/ {
      gsub(/^#[[:space:]]*/, "")
  }
  { print }
  END {
      if (!uncommented) exit 1
  }' "$PACMAN_CONF" > "$PACMAN_CONF.tmp" && mv "$PACMAN_CONF.tmp" "$PACMAN_CONF"

    if grep -q "^\[$REPO\]$" "$PACMAN_CONF" && \
       grep -q "^[[:space:]]*Include[[:space:]]*=[[:space:]]*/etc/pacman.d/mirrorlist" "$PACMAN_CONF"; then
        echo "$REPO enabled"
    else
        cat >> "$PACMAN_CONF" <<EOF
#################################################################

# Arch compatibility
[$REPO]
Include = /etc/pacman.d/mirrorlist-arch

#################################################################
EOF
    echo "Appended [$REPO] block."
  fi
fi

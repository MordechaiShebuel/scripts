#!/bin/sh

tmp=$(mktemp)

cat > "$tmp" <<'EOF'
Hyprland Shortcuts
==================

SUPER + Return       Open terminal
SUPER + D            Application launcher
ALT  + SPACE         Application launcher
SUPER + Q            Close window
SUPER + F            Fullscreen
SUPER + SPACE        Toggle floating
SUPER + /            Show this shortcut list

SUPER + Arrow keys   Move focus
SUPER + 1-5          Switch workspace
SUPER + SHIFT + 1-5  Move window to workspace

Volume Up/Down       Change volume
Mute                 Toggle mute
Brightness Up/Down   Change brightness

SUPER + Print        Select and copy screenshot
Print                Save screenshot
SUPER + CTRL + L     Lock screen

EOF

alacritty -T "Hyprland Shortcuts" -e bash -c "
  cat '$tmp'
  printf '\nPress any key to close...'
  read -n 1
"

rm -f "$tmp"

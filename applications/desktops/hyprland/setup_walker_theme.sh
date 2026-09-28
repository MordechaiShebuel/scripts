#!/bin/sh
set -eu

# This is for Walker 0.8.14
THEME="hyprland"
THEME_DIR="$HOME/.config/walker/themes"

mkdir -p "$THEME_DIR"

rm -f "$THEME_DIR/$THEME.toml"

cp "$THEME_DIR/default.toml" \
   "$THEME_DIR/$THEME.toml"

cp "walker-$THEME-config.toml" \
   "$HOME/.config/walker/config.toml"

cp "walker-$THEME-style.css" \
   "$THEME_DIR/$THEME.css"

# This is not used for Walker 0.8.14
# cp "walker-$THEME-layout.xml" \
#    "$THEME_DIR/layout.xml"


printf 'Installed Walker theme: %s\n' "$THEME"
printf 'Theme directory: %s\n' "$THEME_DIR"

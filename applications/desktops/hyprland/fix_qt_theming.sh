#!/bin/bash

# === 1. Set Kvantum theme to KvAdaptaDark ===
mkdir -p ~/.config/Kvantum
cat > ~/.config/Kvantum/kvantum.kvconfig << EOF
[General]
theme=KvAdaptaDark
EOF

echo "Kvantum theme set to KvAdaptaDark"

# === 2. Fix theming for Dolphin + Falkon ===
# Append the ColorScheme block to the relevant configs

for conf in ~/.config/dolphinrc ~/.config/falkon/falkon.conf ~/.config/kdeglobals; do
    # Create the file if it doesn't exist
    touch "$conf"

    # Remove any existing [UiSettings] ColorScheme line first (to avoid duplicates)
    sed -i '/^\[UiSettings\]/,/^\[/{/ColorScheme=/d}' "$conf" 2>/dev/null

    # Append the correct block if it doesn't already exist
    if ! grep -q "ColorScheme=KvAdaptaDark" "$conf"; then
        echo "" >> "$conf"
        echo "[UiSettings]" >> "$conf"
        echo "ColorScheme=KvAdaptaDark" >> "$conf"
        echo "Fixed: $conf"
    else
        echo "Already correct: $conf"
    fi
done

echo ""
echo "Done! Restart Dolphin and Falkon for the changes to take effect."
echo "You can do:  killall dolphin falkon; dolphin & falkon &"

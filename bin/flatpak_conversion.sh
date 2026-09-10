#!/bin/bash
#!/bin/bash
# Generic Flatpak → Native migration script
# Reads all installed Flatpak apps and migrates where a mapping exists

set -euo pipefail

echo "=== Generic Flatpak to Native Migration ==="
echo

# Detect AUR helper
if command -v yay >/dev/null; then
    AUR_HELPER="yay"
elif command -v paru >/dev/null; then
    AUR_HELPER="paru"
elif command -v pikaur >/dev/null; then
    AUR_HELPER="pikaur"
elif command -v trizen >/dev/null; then
    AUR_HELPER="trizen"
else
    echo "❌ No AUR helper (yay/paru/pikaur/trizen) found."
    exit 1
fi

# Read all Flatpak apps into array
mapfile -t FLATPAK_APPS < <(flatpak list --app --columns=application 2>/dev/null | tail -n +1)

if [ ${#FLATPAK_APPS[@]} -eq 0 ]; then
    echo "No Flatpak applications found."
    exit 1
fi

echo "Found ${#FLATPAK_APPS[@]} Flatpak app(s):"
printf '  - %s\n' "${FLATPAK_APPS[@]}"
echo

# === Mapping: Flatpak ID → Native AUR/package name ===
# Add or modify entries here as needed. Only these will get auto-installed.
declare -A MAPPINGS=(
    ["org.telegram.desktop"]="telegram-desktop-bin"   # Change to "telegram-desktop" if preferred
    ["app.zen_browser.zen"]="zen-browser-bin"
    ["com.brave.Browser"]="brave-bin"
    ["com.bitwarden.desktop"]="bitwarden-bin"
    ["org.garudalinux.firedragon"]="firedragon-bin"
    # Add more below, for example:
)

for APP_ID in "${FLATPAK_APPS[@]}"; do
    echo "────────────────────────────────────────"
    echo "Processing: $APP_ID"

    NATIVE_PKG="${MAPPINGS[$APP_ID]:-}"

    if [[ -n "$NATIVE_PKG" ]]; then
        echo "→ Installing native: $NATIVE_PKG"
        if ! $AUR_HELPER -S --needed --noconfirm "$NATIVE_PKG"; then
            echo "⚠️  Installation failed for $NATIVE_PKG — skipping install step"
        fi
    else
        echo "⚠️  No mapping found for $APP_ID — data copy will still run if native app exists"
    fi

    # Generic data & config copy
    echo "→ Copying data from Flatpak..."
    FLATPAK_DATA="$HOME/.var/app/$APP_ID/data"
    FLATPAK_CONFIG="$HOME/.var/app/$APP_ID/config"

    if [ -d "$FLATPAK_DATA" ]; then
        rsync -a --info=progress2 "$FLATPAK_DATA/" "$HOME/.local/share/" 2>/dev/null || true
    fi

    if [ -d "$FLATPAK_CONFIG" ]; then
        rsync -a --ignore-existing "$FLATPAK_CONFIG/" "$HOME/.config/" 2>/dev/null || true
    fi

    # App-specific tweaks (only Telegram for now)
    if [[ "$APP_ID" == "org.telegram.desktop" ]]; then
        echo "→ Applying Telegram-specific data fix..."
        mkdir -p "$HOME/.local/share/TelegramDesktop"
        rsync -a "$HOME/.var/app/$APP_ID/data/TelegramDesktop/" "$HOME/.local/share/TelegramDesktop/" 2>/dev/null || true
    fi

    echo "→ Fixing permissions..."
    find "$HOME/.local/share" "$HOME/.config" -path "*/$APP_ID*" -exec chmod -R u+rwX {} + 2>/dev/null || true

    # Remove Flatpak version
    echo "→ Removing Flatpak $APP_ID..."
    flatpak uninstall --user -y "$APP_ID" || echo "⚠️  Uninstall may have failed (app might still be running)"

    echo "✅ Finished $APP_ID"
    echo
done

echo "🎉 Migration completed!"
echo "Tip: Extend the MAPPINGS array in the script for other apps you use regularly."

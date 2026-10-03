#!/usr/bin/env bash
set -euo pipefail

DEFAULT_PNG_URL="https://static1.howtogeekimages.com/wordpress/wp-content/uploads/2024/02/enter-the-void.png"
CONFIG_DIR="$HOME/.config/fastfetch"
PNG_DIR="$CONFIG_DIR/images"
CONFIG="$CONFIG_DIR/config.jsonc"
DEFAULT_PNG="$PNG_DIR/void-linux-logo.png"

# Use the first command-line argument if provided.
# Otherwise, download the default Void Linux PNG.
if [[ $# -ge 1 ]]; then
    PNG="$(realpath "$1")"

    if [[ ! -f "$PNG" ]]; then
        echo "PNG not found: $PNG"
        exit 1
    fi
else
    if ! command -v wget >/dev/null 2>&1; then
        echo "wget is required to download the default PNG."
        echo "Install it with: sudo xbps-install -S wget"
        exit 1
    fi

    mkdir -p "$PNG_DIR"

    echo "Downloading default Void Linux logo..."
    wget -q --show-progress \
        -O "$DEFAULT_PNG" \
        "$DEFAULT_PNG_URL"

    PNG="$DEFAULT_PNG"
fi

if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Fastfetch is not installed."
    echo "Install it with: sudo xbps-install -S fastfetch"
    exit 1
fi

mkdir -p "$CONFIG_DIR"

# Escape the PNG path for use inside JSON.
PNG_JSON=$(printf '%s' "$PNG" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat > "$CONFIG" <<EOF
{
    "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",

    "logo": {
        "type": "kitty-direct",
        "source": "/home/mshalom/.config/fastfetch/images/void-linux-logo.png",
        "width": 30,
        "height": 15,
        "padding": {
            "right": 3
        }
    },

    "display": {
        "separator": "  ",
        "key": {
            "width": 14
        }
    },

    "modules": [
        {
            "type": "title",
            "format": "{user-name}@{host-name}"
        },
        "separator",
        {
            "type": "os",
            "format": "{pretty-name}"
        },
        "kernel",
        "uptime",
        "packages",
        "shell",
        "display",
        "de",
        "wm",
        "terminal",
        "cpu",
        "gpu",
        "memory",
        "disk",
        "colors"
    ]
}
EOF

echo
echo "Fastfetch configuration written to:"
echo "  $CONFIG"
echo "Logo:"
echo "  $PNG"
echo

fastfetch --config "$CONFIG"

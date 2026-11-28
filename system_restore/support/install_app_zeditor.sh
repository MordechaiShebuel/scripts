#!/bin/bash
#DEFINE COLORS
YELLOW="\033[1;33m"
NC="\033[0m"
GREEN="\033[1;32m"
RED="\033[1;31m"

ZED_BIN="$HOME/.local/bin/zed"

if [ -x "$ZED_BIN" ] || command -v zed >/dev/null 2>&1; then
    echo -e "$YELLOW Zed already installed $NC"
else
    echo -e "$GREEN Installing Zed - Editor $NC"

    curl -fL https://zed.dev/install.sh | sh

    # Confirm that the installer actually installed it
    if [ ! -x "$ZED_BIN" ] && ! command -v zed >/dev/null 2>&1; then
        echo -e "$RED Zed installation failed or was not found $NC"
        exit 1
    fi
fi

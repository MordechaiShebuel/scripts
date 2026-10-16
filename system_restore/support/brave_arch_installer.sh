#!/bin/bash

# Get color support
. ./support/./colors.sh

browser_installed() {
    local browser

    for browser in "$@"; do
        if command -v "$browser" >/dev/null 2>&1; then
            return 0
        fi
    done

    return 1
}


install_brave_pacman() {
    if browser_installed brave brave-browser; then
        log "${YELLOW}Brave Browser is already installed.${NC}"
        return 0
    fi

    log "Checking for a ${GREEN}Brave${NC} package in the configured repositories..."

    local brave_package=""

    if pacman -Si brave >/dev/null 2>&1; then
        brave_package="brave"
    elif pacman -Si brave-bin >/dev/null 2>&1; then
        brave_package="brave-bin"
    fi

    if [[ -z "$brave_package" ]]; then
        log "Brave Browser was not found in the configured pacman repositories."
        log "Install a compatible Brave package manually, for example through an"
        log "AUR helper, then run this script again."
        return 1
    fi

    sudo pacman -Syu --needed "$brave_package"

    if browser_installed brave brave-browser; then
        echo "Brave Browser installed!"
    else
        echo "Brave Browser installation failed." >&2
        return 1
    fi
}

brave_pacman

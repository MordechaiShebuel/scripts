#!/usr/bin/env bash

search_term=$1
linux=$(uname -r)

if [[ "$linux" == *"omlx"* ]]; then
    # Open Mandriva
    ./update.sh

    sudo dnf search "$search_term"
fi

if [[ "$linux" == *"artix"* ]]; then
    # Artix
    #update first
    ./update.sh

    if ! command -v "pamac" >/dev/null 2>&1; then
        sudo pacman -S pamac
    fi

    # Enable lib32 in config
    # Artix [lib32] and Arch [multilib]

    pamac search "$search_term"
fi

if [[ "$linux" == *"vendefoul"* ]]; then
    # Vendewolf
    ./update.sh

    # After installing
    sudo apt-cache search "$search_term"
    # Cinnamon:
    # Menu → Settings → Keyboard → Layouts tab → click + to add English layout, then set it as default.
fi

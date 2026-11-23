#!/bin/bash

# Classes that count as "game" windows
GAME_CLASSES="steam_app_|gamescope|steam$"

socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    case $line in
        activewindow\>\>*)
            class=$(echo "$line" | cut -d'>' -f3 | cut -d',' -f1)
            if echo "$class" | grep -qE "$GAME_CLASSES"; then
                noctalia msg caffeine-enable
            else
                noctalia msg caffeine-disable
            fi
            ;;
    esac
done

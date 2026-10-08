#!/bin/bash
#
# Made to debug windows / games that don't want to behave in Hyprland

mkdir -p ~/hypr-capture
last=
while sleep 0.2; do
    current=$(hyprctl -j clients | jq -c \
        '[.[] | {class, title, initialClass, initialTitle, address}]')
    if [ "$current" != "$last" ]; then
        printf '%s %s\n' "$(date --iso-8601=seconds)" "$current" \
            >> ~/hypr-capture/changes.jsonl
        last=$current
    fi
done

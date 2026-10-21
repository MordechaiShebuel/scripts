#!/bin/bash

WINDOW_CLASS=$(xprop -id "$(xdotool getactivewindow)" WM_CLASS 2>/dev/null | grep -oP '"\K[^"]+' | tail -1)

if [[ "$WINDOW_CLASS" == "rio" ]] || [[ "$WINDOW_CLASS" == "ghostty" ]] || [[ "$WINDOW_CLASS" == "com.mitchellh.ghostty" ]]; then
    xdotool key ctrl+shift+f
else
    xdotool key ctrl+f
fi

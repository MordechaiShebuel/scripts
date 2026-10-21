#!/bin/bash

# Get active window class
ACTIVE_CLASS=$(xdotool getactivewindow getwindowname)
WINDOW_CLASS=$(xprop -id "$(xdotool getactivewindow)" WM_CLASS 2>/dev/null | grep -oP '"\K[^"]+' | tail -1)

# Check if terminal
if [[ "$WINDOW_CLASS" == "rio" ]] || [[ "$WINDOW_CLASS" == "ghostty" ]] || [[ "$WINDOW_CLASS" == "com.mitchellh.ghostty" ]]; then
    xdotool key ctrl+shift+c
else
    xdotool key ctrl+c
fi

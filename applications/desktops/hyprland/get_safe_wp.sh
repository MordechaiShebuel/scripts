# Replace the stock Hyprland wallpaper
printf 'Replace stock Hyprland photo with something safer? [Y/n] '
read -r answer

case "$answer" in
    [nN]|[nN][oO])
        printf 'Keeping the current wallpaper.\n'
        ;;
    *)
        wallpaper_dir="$HOME/Pictures/wallpapers"
        wallpaper_file="$wallpaper_dir/wallpaper.jpg"
        wallpaper_url='https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80'

        mkdir -p "$wallpaper_dir"

        if wget -O "$wallpaper_file" "$wallpaper_url"; then
            printf 'Wallpaper downloaded to: %s\n' "$wallpaper_file"
        else
            printf 'Failed to download the wallpaper.\n' >&2
            exit 1
        fi
        ;;
esac

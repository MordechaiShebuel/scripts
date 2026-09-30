# Replace the stock Hyprland wallpaper
printf 'Retrieve a stock default wallpaper? [Y/n] '
read -r answer

case "$answer" in
    [nN]|[nN][oO])
        printf 'Keeping the current wallpaper.\n'
        ;;
    *)
        wallpaper_dir="$HOME/Pictures/wallpapers"
        wallpaper_file="$wallpaper_dir/wallpaper.jpg"
        wallpaper_url='https://wallpapers.com/images/featured/most-beautiful-nature-pictures-hdb30wtkjbn08xlf.jpg'

        mkdir -p "$wallpaper_dir"

        if wget -O "$wallpaper_file" "$wallpaper_url"; then
            printf 'Wallpaper downloaded to: %s\n' "$wallpaper_file"
        else
            printf 'Failed to download the wallpaper.\n' >&2
            exit 1
        fi
        ;;
esac

# Replace the stock Hyprland wallpapers
printf 'Install wallpapers to /usr/share/hypr as well? [y/N] '
read -r answer

wallpaper_dir="$HOME/Pictures/wallpapers"
mkdir -p "$wallpaper_dir"

wallpaper_url0='https://wallpapers.com/images/featured/most-beautiful-nature-pictures-hdb30wtkjbn08xlf.jpg'
wallpaper_url1='https://wallpapercave.com/wp/wp3162131.jpg'
wallpaper_url2='https://wallpapercave.com/wp/wp6844174.jpg'

wallpaper_home0="$wallpaper_dir/wall0.png"
wallpaper_home1="$wallpaper_dir/wall1.png"
wallpaper_home2="$wallpaper_dir/wall2.png"

download_wallpaper() {
    url="$1"
    destination="$2"

    if wget -O "$destination" "$url"; then
        printf 'Wallpaper downloaded to: %s\n' "$destination"
    else
        printf 'Failed to download wallpaper: %s\n' "$url" >&2
        exit 1
    fi
}

# Always download the wallpapers to ~/Pictures/wallpapers
download_wallpaper "$wallpaper_url0" "$wallpaper_home0"
download_wallpaper "$wallpaper_url1" "$wallpaper_home1"
download_wallpaper "$wallpaper_url2" "$wallpaper_home2"

case "$answer" in
    [yY]|[yY][eE][sS])
        printf 'Copying wallpapers to /usr/share/hypr...\n'

        if sudo cp "$wallpaper_home0" /usr/share/hypr/wall0.png &&
           sudo cp "$wallpaper_home1" /usr/share/hypr/wall1.png &&
           sudo cp "$wallpaper_home2" /usr/share/hypr/wall2.png; then
            printf 'Wallpapers copied to /usr/share/hypr.\n'
        else
            printf 'Failed to copy wallpapers to /usr/share/hypr.\n' >&2
            exit 1
        fi
        ;;
    *)
        printf 'Wallpapers kept in %s.\n' "$wallpaper_dir"
        ;;
esac

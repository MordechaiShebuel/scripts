#!/bin/bash
# Replace the stock Hyprland wallpapers
printf 'Install wallpapers to /usr/share/hypr as well? [y/N] '
read -r answer

wallpaper_dir="$HOME/Pictures/wallpapers"
mkdir -p "$wallpaper_dir"

declare -A wallpapers
wallpapers=(
  ["$wallpaper_dir/wall0.png"]="https://wallpapers.com/images/featured/most-beautiful-nature-pictures-hdb30wtkjbn08xlf.jpg"
  ["$wallpaper_dir/wall1.png"]="https://wallpapercave.com/wp/wp3162131.jpg"
  ["$wallpaper_dir/wall2.png"]="https://wallpapercave.com/wp/wp6844174.jpg"
  ["$wallpaper_dir/wall3.png"]="https://wallpapercave.com/uwp/uwp4920179.jpeg"
  ["$wallpaper_dir/wall4.png"]="https://wallpapercave.com/wp/wp16495094.webp"
  ["$wallpaper_dir/wall5.png"]="https://wallpapercave.com/uwp/uwp4920180.jpeg"
  ["$wallpaper_dir/void0.png"]="https://art.osowoso.org/assets/hires/052.png"
  ["$wallpaper_dir/void1.png"]="https://art.osowoso.org/assets/hires/034.png"
  ["$wallpaper_dir/void2.png"]="https://art.osowoso.org/assets/hires/007.png"
)

download_wallpaper() {
    url="$1"
    destination="$2"
    if [[ -f $destination ]]; then
        return
    fi

    if wget -O "$destination" "$url"; then
        printf 'Wallpaper downloaded to: %s\n' "$destination"
    else
        printf 'Failed to download wallpaper: %s\n' "$url" >&2
        exit 1
    fi
}

# Always download the wallpapers to ~/Pictures/wallpapers
for destination in "${!wallpapers[@]}"; do
  download_wallpaper "${wallpapers[$destination]}" "$destination"
done

case "$answer" in
    [yY]|[yY][eE][sS])
        printf 'Copying wallpapers to /usr/share/hypr...\n'

        if sudo cp -f "$wallpaper_dir/wall0" /usr/share/hypr/wall0.png &&
           sudo cp -f "$wallpaper_dir/wall1" /usr/share/hypr/wall1.png &&
           sudo cp -f "$wallpaper_dir/void0" /usr/share/hypr/wall2.png; then
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

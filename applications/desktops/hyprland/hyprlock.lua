-- ~/.config/hypr/hyprlock.lua

local config = {
    general = {
        grace = 5,
        hide_cursor = false,
        no_fade_in = false,
        disable_loading_bar = false,
    },
    background = {
        monitor = "",
        path = "screenshot",
        blur_passes = 3,
        blur_size = 8,
        noise = 0.0117,
        contrast = 0.8916,
        brightness = 0.8172,
        vibrancy = 0.1696,
    },
    -- Clock in top right with active border styling
    label = {
        {
            monitor = "",
            text = "cmd[update:1000] echo \"$(date '+%H:%M:%S')\"",
            color = "0xffcdd6f4",
            font_size = 48,
            font_family = "Noto Sans",
            position = "-50, 50",
            halign = "right",
            valign = "top",
        }
    },
    -- Box around clock (styled with active border)
    shape = {
        {
            monitor = "",
            size = "300, 100",
            color = "0xff1e1e2e",
            rounding = 10,
            border_size = 2,
            border_color = "0xff89b4fa",  -- active_border from Hyprland
            position = "-370, 30",
            halign = "right",
            valign = "top",
        }
    },
    -- Main input/wallpaper box (inactive border styling)
    shape = {
        {
            monitor = "",
            size = "800, 600",
            color = "0xff1e1e2e",
            rounding = 10,
            border_size = 2,
            border_color = "0xff45475a",  -- inactive_border from Hyprland
            position = "0, -150",
            halign = "center",
            valign = "center",
        }
    },
    -- Wallpaper slideshow inside box
    image = {
        {
            monitor = "",
            path = "cmd[update:5000] ls -1 $HOME/Pictures/wallpapers/* | shuf -n 1",
            size = "800, 600",
            rounding = 8,
            position = "0, -150",
            halign = "center",
            valign = "center",
        }
    },
    -- Input field
    input_field = {
        {
            monitor = "",
            size = "250, 60",
            outline_thickness = 2,
            dots_size = 0.2,
            dots_spacing = 0.35,
            outer_color = "0xff45475a",
            inner_color = "0xff313244",
            font_color = "0xffcdd6f4",
            fade_on_empty = true,
            fade_timeout = 1000,
            placeholder_text = "<i>Enter Pass</i>",
            check_color = "0xffa6e3a1",
            fail_color = "0xfff38ba8",
            position = "0, -300",
            halign = "center",
            valign = "center",
        }
    },
}

return config

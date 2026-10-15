hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QTWEBENGINE_CHROMIUM_FLAGS", "--blink-settings=forceDarkModeEnabled=true")

-- Theming setup
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(89b4faff)", "rgba(cba6f7ff)" },
                angle = 45,
            },
            inactive_border = "0xff45475a",
        },
        layout = "dwindle",
        allow_tearing = false,
    },
    decoration = {
        rounding = 10,
        inactive_opacity = 0.82,
        active_opacity = 0.95,

        shadow = {
            enabled = true,
            range = 6,
            render_power = 3,
            color = "0x66000000"
        },

        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            vibrancy = 0.15,
        },
    },
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        numlock_by_default = true,
    },
    dwindle = {
        preserve_split = true,
    },
    animations = {
        enabled = true,
        bezier = { "smooth, 0.25, 0.1, 0.25, 1.0" },
        animation = {
            "windows, 1, 5, smooth",
            "windowsOut, 1, 5, default, popin 80%",
            "fade, 1, 5, smooth",
            "workspaces, 1, 5, smooth",
        },
    },
})

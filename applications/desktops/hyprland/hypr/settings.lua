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
            active_border   = "0xff89b4fa",
            inactive_border = "0xff45475a",
        },
        layout = "dwindle",
        allow_tearing = false,
    },
    decoration = {
        rounding = 10,
        inactive_opacity = 0.85,
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
        animation = {
            "windows, 1, 7, default",
            "windowsOut, 1, 7, default, popin 80%",
            "fade, 1, 7, myBezier",
        },
    },
})

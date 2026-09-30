-- ~/.config/hypr/hyprland.lua

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("QTWEBENGINE_CHROMIUM_FLAGS", "--blink-settings=forceDarkModeEnabled=true")

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

hl.window_rule({
    name  = "hyprland-shortcuts",
    match = { title = "^Hyprland Shortcuts$" },  -- adjust if the real title is different
    float = true,
    center = true,
})

-- Autostart
hl.on("hyprland.start", function()
    -- Keep this list short while testing
    hl.exec_cmd("/usr/bin/pipewire")
    hl.exec_cmd("/usr/bin/pipewire -c pipewire-pulse.conf")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("nym-vpn")
    hl.exec_cmd("~/.config/hypr/show-shortcuts.sh")
end)

local mainMod   = "SUPER"
local secondMod = "ALT"

-- Terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("alacritty"))

-- App Launcher
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(secondMod .. " + SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- Close window
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + W", hl.dsp.window.close())

-- Fullscreen (1 = maximize)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))

-- Toggle floating
hl.bind(mainMod .. " + Space", hl.dsp.window.float({ action = "toggle" }))

-- Move focus with arrow keys
hl.bind(mainMod .. " + left",          hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + TAB",           hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right",         hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + TAB",   hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",            hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",          hl.dsp.focus({ direction = "down" }))

-- Workspaces 1-5 + move window to workspace
for i = 1, 5 do
    hl.bind(mainMod .. " + " .. i,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i,   hl.dsp.window.move({ workspace = i }))
end

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer -t"),   { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +10%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true, repeating = true })

-- Screenshots
hl.bind(mainMod .. " + Print",                 hl.dsp.exec_cmd("grimshot --notify save area"))
hl.bind(secondMod .. " + CTRL + SHIFT + 4",    hl.dsp.exec_cmd("grimshot --notify copy area"))
hl.bind(secondMod .. " + SHIFT + 4",           hl.dsp.exec_cmd("grimshot --notify save area ~/Pictures/screenshot-$(date +%s).png"))
hl.bind(secondMod .. " + Print",               hl.dsp.exec_cmd("grimshot --notify save output"))

-- Lock screen
hl.bind(mainMod .. " + CTRL + L", hl.dsp.exec_cmd("noctalia msg session lock"))

-- Shortcut help screen
hl.bind(mainMod .. " + slash",
    hl.dsp.exec_cmd("~/.config/hypr/show-shortcuts.sh", { float = true, center = true }))

-- Reload Hyprland config
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Mac-style save/copy/cut/paste (Super = Cmd equivalent)
-- Duck.ai recommendation, doesn't work.
hl.bind(mainMod .. " + s",             hl.dsp.exec_cmd("xdotool key ctrl+s"))
hl.bind(mainMod .. " + c",             hl.dsp.exec_cmd("xdotool key ctrl+c"))
hl.bind(mainMod .. " + x",             hl.dsp.exec_cmd("xdotool key ctrl+x"))
hl.bind(mainMod .. " + v",             hl.dsp.exec_cmd("xdotool key ctrl+v"))

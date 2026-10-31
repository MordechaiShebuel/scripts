-- Window Rules
hl.window_rule({
  name  = "keybind-viewer",
  match = {
    class = "keybind_viewer",
    title = "^Lua Keybindings$",
  },
  float  = true,
  center = true,
  size = { 750, 900 }
})

hl.window_rule({
    match = { class = "^steam$" },
    no_initial_focus = true,
    -- workspace = "5 silent",   -- optional
})

hl.window_rule({
    match = { class = "^steam$", title = "^Steam Big Picture Mode$" },
    fullscreen = true,
})

-- Optional but useful for actual games
hl.window_rule({
    match = { class = "^steam_app_.*" },
    idle_inhibit = "fullscreen",   -- Hyprland-side inhibit as extra safety
})

-- Rule for galculator
hl.window_rule({
    match = {
        class = "[q|g]alculat.*",
    },
    -- allowedOverFullscreen = true,
    -- floating = true,
    monitor = 0,
    float  = true,
    center = true,
    -- at = "1550,46",
    size = "359 380"
})

-- Rule for Nym VPN
hl.window_rule({
    match = {
        class = "nym-vpn-app",
        title = "NymVPN"
    },
    -- allowedOverFullscreen = true,
    -- floating = true,
    monitor = 0,
    float  = true,
    center = true,
    -- at = "1550,46",
    size = "370 710"
})

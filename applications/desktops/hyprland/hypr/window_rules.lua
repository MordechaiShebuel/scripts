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
    match = {
        title = "^()$",
        class = "^steam$",
    },
    stay_focused = true,
})

hl.window_rule({
    match = {
        title = "^()$",
        class = "^steam$",
    },
    min_size = "1 1",
})
hl.window_rule({
    name = "steam-big-picture-fullscreen",
    match = {
        class = "^steam$",
        title = "^Steam Big Picture Mode$",
    },
    fullscreen = true,
})

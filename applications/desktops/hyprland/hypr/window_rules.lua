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
        class = "^steam$",
        title = "^Steam Big Picture Mode$",
    },
    fullscreen = true,
})

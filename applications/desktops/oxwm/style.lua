-- ~/.config/oxwm/style.lua
-- Borders, gaps and general visual style

local theme = require("theme_tokyo_night")   -- pull colors from theme.lua

-- Borders
oxwm.border.set_width(2)
oxwm.border.set_focused_color(theme.blue)
oxwm.border.set_unfocused_color(theme.grey)

-- Gaps
oxwm.gaps.set_smart(true)          -- no gaps when only one window
oxwm.gaps.set_inner(6, 6)          -- horizontal, vertical
oxwm.gaps.set_outer(8, 8)          -- outer gaps from screen edges

-- Optional extras you might want
-- oxwm.set_floating_position("center")
-- oxwm.bar.set_position("top")     -- or "bottom"

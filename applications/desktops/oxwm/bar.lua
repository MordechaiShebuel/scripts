-- ~/.config/oxwm/bar.lua
-- Stock status bar with system tray + clock

local theme = require("theme_tokyo_night")

-- Font (change to your preferred Nerd Font if you want icons)
local bar_font = "JetBrainsMono Nerd Font:style=Bold:size=12"
-- Fallback if you don't have a Nerd Font:
-- local bar_font = "monospace:style=Bold:size=11"

oxwm.bar.set_font(bar_font)

-- Optional: put the bar at the bottom
-- oxwm.bar.set_position("bottom")

-- Tag color schemes
oxwm.bar.set_scheme_normal(theme.fg, theme.bg, "#444444")
oxwm.bar.set_scheme_occupied(theme.cyan, theme.bg, theme.cyan)
oxwm.bar.set_scheme_selected(theme.selected, theme.bg, theme.selected)
oxwm.bar.set_scheme_urgent(theme.urgent, theme.bg, theme.urgent)

-- Hide empty tags (optional – uncomment if you want it)
-- oxwm.bar.set_hide_vacant_tags(true)

-- Status blocks (displayed from right to left)
local blocks = {
    -- System tray (icons for network, volume, etc.)
    oxwm.bar.block.systray({
        -- Most people leave this empty / with defaults
    }),

    -- Separator
    oxwm.bar.block.static({
        text = "  │  ",
        interval = 999999999,
        color = theme.lavender,
        underline = false,
    }),

    -- Clock
    oxwm.bar.block.datetime({
        format = "{}",
        date_format = "%a %d %b  %H:%M",   -- e.g. Thu 15 Oct  14:40
        interval = 1,
        color = theme.cyan,
        underline = true,
    }),
}

oxwm.bar.set_blocks(blocks)

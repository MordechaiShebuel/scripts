-- ~/.config/hypr/hyprland.lua
local shell = "dux"

require("monitors")
require("settings")
require("window_rules")

if shell == "noctalia" then
    require("autostart-noctalia")
    require("keybinds-noctalia")
    -- >>> HYPRLAND VISUAL EDITOR (HVE) <<<
    pcall(function() dofile(os.getenv("HOME") .. "/.cache/noctalia/HVE/overlay.lua") end)
    -- <<< HYPRLAND VISUAL EDITOR (HVE) <<<

    -- For Noctalia Color templates
    require("noctalia").apply_theme()

    local colors = require("noctalia").colors

elseif shell == "dux" then
    require("autostart-dux")
    require("keybinds-dux")
    -- DMS auto themes
    require("dms-theme-sync")

    require("dms/colors")
    require("dms/cursor")
    require("dms/input")
    require("dms/layout")
    require("dms/windowrules")
else
    error("Unknown shell: " .. tostring(shell))
end-- ~/.config/hypr/hyprland.lua

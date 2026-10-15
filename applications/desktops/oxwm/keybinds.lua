local modkey = "Mod4"
local home   = os.getenv("HOME")

-- Helper for Mac-style key simulation (needs xdotool)
local function send_keys(keys)
    return oxwm.spawn({ "xdotool", "key", "--clearmodifiers", keys })
end

-------------------------------------------------------------------------------
-- Terminal / Launcher / Apps
-------------------------------------------------------------------------------
oxwm.key.bind({ modkey }, "Return", oxwm.spawn("rio"))                    -- Terminal
oxwm.key.bind({ modkey }, "D",     oxwm.spawn("wofi -show drun"))         -- App launcher
oxwm.key.bind({ modkey }, "Space", oxwm.spawn("wofi -show drun"))         -- App launcher
oxwm.key.bind({ modkey }, "E",     oxwm.spawn("nemo"))                  -- File manager

-------------------------------------------------------------------------------
-- Window management
-------------------------------------------------------------------------------
oxwm.key.bind({ modkey }, "Q", oxwm.client.kill())
oxwm.key.bind({ modkey }, "W", oxwm.client.kill())
oxwm.key.bind({ modkey, "Shift" }, "F", oxwm.client.toggle_fullscreen())
oxwm.key.bind({ modkey, "Mod1" }, "Space", oxwm.client.toggle_floating()) -- Alt+Space

-- Force kill
oxwm.key.bind({ modkey, "Mod1" }, "Q",      oxwm.client.kill())
oxwm.key.bind({ modkey, "Mod1" }, "Escape", oxwm.client.kill())

-------------------------------------------------------------------------------
-- Focus
-------------------------------------------------------------------------------
oxwm.key.bind({ modkey }, "J",     oxwm.client.focus_stack(1))
oxwm.key.bind({ modkey }, "K",     oxwm.client.focus_stack(-1))
oxwm.key.bind({ modkey }, "Left",  oxwm.client.focus_stack(-1))
oxwm.key.bind({ modkey }, "Right", oxwm.client.focus_stack(1))
oxwm.key.bind({ modkey }, "Up",    oxwm.client.focus_stack(-1))
oxwm.key.bind({ modkey }, "Down",  oxwm.client.focus_stack(1))

-- Window switcher
oxwm.key.bind({ modkey }, "Tab", oxwm.spawn("rofi -show window"))

-------------------------------------------------------------------------------
-- Workspaces (tags 1-5)
-------------------------------------------------------------------------------
for i = 1, 5 do
    local tag = i - 1
    oxwm.key.bind({ modkey },          tostring(i), oxwm.tag.view(tag))
    oxwm.key.bind({ modkey, "Shift" }, tostring(i), oxwm.tag.move_to(tag))
end

-------------------------------------------------------------------------------
-- Media / Hardware
-------------------------------------------------------------------------------
oxwm.key.bind({}, "XF86AudioRaiseVolume",  oxwm.spawn("pamixer -i 5"))
oxwm.key.bind({}, "XF86AudioLowerVolume",  oxwm.spawn("pamixer -d 5"))
oxwm.key.bind({}, "XF86AudioMute",         oxwm.spawn("pamixer -t"))
oxwm.key.bind({}, "XF86MonBrightnessUp",   oxwm.spawn("brightnessctl set +10%"))
oxwm.key.bind({}, "XF86MonBrightnessDown", oxwm.spawn("brightnessctl set 10%-"))

-- Power button → lock (or change to a power menu if you prefer)
oxwm.key.bind({}, "XF86PowerOff", oxwm.spawn("i3lock-color -c 000000"))

-------------------------------------------------------------------------------
-- Screenshots (maim style – matches OXWM defaults)
-------------------------------------------------------------------------------
-- Region → clipboard
oxwm.key.bind({ modkey, "Shift" }, "4",
    oxwm.spawn({ "sh", "-c", "maim -s | xclip -selection clipboard -t image/png" }))

-- Fullscreen focused monitor → clipboard
oxwm.key.bind({ modkey, "Shift" }, "3",
    oxwm.spawn({ "sh", "-c", "maim -i $(xdotool getactivewindow) | xclip -selection clipboard -t image/png" }))

-- All monitors → clipboard
oxwm.key.bind({ modkey, "Control", "Shift" }, "3",
    oxwm.spawn({ "sh", "-c", "maim | xclip -selection clipboard -t image/png" }))

-- Optional: Flameshot (nicer UI + annotation)
-- oxwm.key.bind({ modkey, "Shift" }, "4", oxwm.spawn("flameshot gui"))

-------------------------------------------------------------------------------
-- Lock / Session
-------------------------------------------------------------------------------
oxwm.key.bind({ modkey, "Mod1" }, "L",
    oxwm.spawn("i3lock-color -c 000000"))                 -- simple black lock

oxwm.key.bind({ modkey, "Control" }, "L",
    oxwm.spawn("i3lock-color -c 000000"))

-- Optional prettier lock with betterlockscreen:
-- oxwm.key.bind({ modkey, "Mod1" }, "L", oxwm.spawn("betterlockscreen -l"))

-------------------------------------------------------------------------------
-- Help / Reload
-------------------------------------------------------------------------------
oxwm.key.bind({ modkey }, "H",
    oxwm.spawn(home .. "/.config/hypr/keybind_viewer " .. home .. "/.config/hypr/binds.json"))
    -- or just use the built-in one:
-- oxwm.key.bind({ modkey }, "H", oxwm.show_keybinds())

oxwm.key.bind({ modkey, "Shift" }, "R", oxwm.restart())

-------------------------------------------------------------------------------
-- Mac-style overlays (Super ≈ Cmd)
-------------------------------------------------------------------------------
oxwm.key.bind({ modkey }, "B",     send_keys("ctrl+b"))
oxwm.key.bind({ modkey }, "X",     send_keys("ctrl+x"))
oxwm.key.bind({ modkey }, "S",     send_keys("ctrl+s"))
oxwm.key.bind({ modkey }, "T",     send_keys("ctrl+t"))oxwm.key.bind({ modkey }, "F",     send_keys("ctrl+f"))
oxwm.key.bind({ modkey }, "Z",     send_keys("ctrl+z"))
oxwm.key.bind({ modkey }, "A",     send_keys("ctrl+a"))
oxwm.key.bind({ modkey }, "slash", send_keys("ctrl+slash"))

local function mac_copy()
    return oxwm.spawn({ "sh", "-c", "./oxwm-mac-keys 'ctrl+c' 'ctrl+shift+c'" })
end

local function mac_paste()
    return oxwm.spawn({ "sh", "-c", "./oxwm-mac-keys 'ctrl+v' 'ctrl+shift+v'" })
end

local function mac_find()
    return oxwm.spawn({ "sh", "-c", "./oxwm-mac-keys 'ctrl+f' 'ctrl+shift+f'" })
end

-- Bind them
oxwm.key.bind({ modkey }, "C", mac_copy())
oxwm.key.bind({ modkey }, "V", mac_paste())
oxwm.key.bind({ modkey }, "F", mac_find())

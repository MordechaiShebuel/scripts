-- Helper Functions
local function send_shortcut_once(mods, key)
    return function()
        hl.dispatch(hl.dsp.send_key_state({
            mods = mods,
            key = key,
            state = "down",
            window = "activewindow",
        }))

        hl.timer(function()
            hl.dispatch(hl.dsp.send_key_state({
                mods = mods,
                key = key,
                state = "up",
                window = "activewindow",
            }))
        end, {
            timeout = 50,
            type = "oneshot",
        })
    end
end

local function active_window_is_terminal()
  local window = hl.get_active_window()
    if not window then
        return false
    end

  if window.class == "rio" or  window.class == "com.mitchellh.ghostty" then
	return true
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return true
    end
  end

  return false
end

local function universal_clipboard_shortcut(
  default_mods,
  default_key,
  terminal_mods,
  terminal_key
)
  return function()
    if active_window_is_terminal() then
      send_shortcut_once(terminal_mods, terminal_key)()
    else
      send_shortcut_once(default_mods, default_key)()
    end
  end
end

-- Constants
local mainMod   = "SUPER"
local secondMod = "ALT"
local ipc = "noctalia msg "

-- KEY BINDS
-- Terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("rio"))

-- App Launcher
hl.bind(mainMod .. " + D",     hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))

-- Launch file explorer
hl.bind(mainMod .. " + E",     hl.dsp.exec_cmd("thunar"))

-- Close window
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + W", hl.dsp.window.close())

-- Fullscreen (1 = maximize)
hl.bind(mainMod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = 1 }))

-- Toggle floating
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Move focus with arrow keys
hl.bind(mainMod .. " + TAB",           hl.dsp.exec_cmd(ipc .. "window-switcher hold"))
hl.bind(mainMod .. " + left",          hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right",         hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",            hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",          hl.dsp.focus({ direction = "down" }))

-- Workspaces 1-5 + move window to workspace
for i = 1, 5 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Intercept Power button
hl.bind(
    "XF86PowerOff",
    hl.dsp.exec_cmd("noctalia msg panel-toggle session"),
    { locked = true }
)

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pamixer -t"),   { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +10%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), { locked = true, repeating = true })


-- macOS-style screenshots (secondMod ≈ Cmd)
-- ⌘⇧3  full screen (focused output)
hl.bind(mainMod .. " + SHIFT + 3",
  hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"))

-- ⌘⇧4  region
hl.bind(mainMod .. " + CTRL + SHIFT + 4",
  hl.dsp.exec_cmd(ipc .. "screenshot-region"))

-- Multi-monitor: picker (≈ “choose display”)
hl.bind(mainMod .. " + SHIFT + 5",
  hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen pick"))

-- All monitors as one image
hl.bind(mainMod .. " + CTRL + SHIFT + 3",
    hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen all"))

-- Lock screen
hl.bind(mainMod .. " + ALT + L", hl.dsp.exec_cmd(ipc .. "panel-toggle session"))

-- Shortcut help screen
hl.bind(mainMod .. " + h",
  hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/keybind_viewer $HOME/.config/hypr/keybinds.lua"))

-- Reload Hyprland config
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))

-- Mac-style overlays (Super = Cmd equivalent)
-- Duck.ai recommendation, doesn't work.
hl.bind(mainMod .. " + b", send_shortcut_once("CTRL", "b"))   -- app specific, close browser bar in coding apps
hl.bind(mainMod .. " + c", universal_clipboard_shortcut("CTRL", "C", "CTRL SHIFT", "C"))   -- copy
hl.bind(mainMod .. " + x", send_shortcut_once("CTRL", "x"))        -- cut
hl.bind(mainMod .. " + v", universal_clipboard_shortcut("CTRL", "V", "CTRL SHIFT", "V"))  -- paste
hl.bind(mainMod .. " + s", send_shortcut_once("CTRL", "s"))        -- save
hl.bind(mainMod .. " + t", send_shortcut_once("CTRL", "t"))        -- new tab
hl.bind(mainMod .. " + p", send_shortcut_once("CTRL", "p"))        -- print
hl.bind(mainMod .. " + f", universal_clipboard_shortcut("CTRL", "F", "CTRL SHIFT", "F"))        -- find
hl.bind(mainMod .. " + z", send_shortcut_once("CTRL", "z"))        -- undo
hl.bind(mainMod .. " + a", send_shortcut_once("CTRL", "a"))        -- select-all
hl.bind(mainMod .. " + slash", send_shortcut_once("CTRL", "slash"))        -- app specfic for code editors, enable remark / disable remark
hl.bind(mainMod .. " + ALT + q", hl.dsp.window.kill())            -- Force kill app
hl.bind(mainMod .. " + ALT + escape", hl.dsp.window.kill())       -- Force kill app
hl.bind(mainMod .. " + CTRL + l", hl.dsp.exec_cmd("noctalia msg session lock"))      -- lock screen

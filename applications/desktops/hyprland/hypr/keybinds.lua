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

local function bindWithDescription(keyBinding, action, description, options)
    -- Store the description
    if not _commandRegistry then
        _commandRegistry = {}
    end

    table.insert(_commandRegistry, {
        key = keyBinding,
        action = action,
        description = description,
        options = options
    })

    -- Bind with optional config
    if options then
        hl.bind(keyBinding, action, options)
    else
        hl.bind(keyBinding, action)
    end
end

-- Constants
local mainMod   = "SUPER"
local ipc = "noctalia msg "

-- KEY BINDS
-- Terminal
bindWithDescription(mainMod .. " + Return", hl.dsp.exec_cmd("rio"), "Open Terminal Window")

-- App Launcher
bindWithDescription(mainMod .. " + D", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"), "Open Application Launcher")
bindWithDescription(mainMod .. " + SPACE", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"), "Open Application Launcher")

-- Launch file explorer
bindWithDescription(mainMod .. " + E", hl.dsp.exec_cmd("Thunar"), "Open Application Launcher")

-- Close window
bindWithDescription(mainMod .. " + SPACE", hl.dsp.exec_cmd(ipc .. "panel-toggle launcher"), "Open Application Launcher")-- hl.bind(mainMod .. " + Q", hl.dsp.window.close())
bindWithDescription(mainMod .. " + Q", hl.dsp.window.close(), "Close the current window")
bindWithDescription(mainMod .. " + W", hl.dsp.window.close(), "Close the current window")

-- Toggle Fullscreen (1 = maximize)
bindWithDescription(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = 1 }), "Toggle Fullscreen for Window")

-- Toggle floating
bindWithDescription(mainMod .. " + ALT + SPACE", hl.dsp.window.float({ action = "toggle" }), "Toggle Float for Window")

-- Scroll through existing workspaces with mainMod + scroll
bindWithDescription(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Cycle through open windows forward")
bindWithDescription(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), "Cycle through open windows backward")

-- Move/resize windows with mainMod + LMB/RMB and dragging
bindWithDescription(mainMod .. " + mouse:272", hl.dsp.window.drag(), "Left Click to drag window with mouse", { mouse = true })
bindWithDescription(mainMod .. " + mouse:273", hl.dsp.window.resize(), "Right Click to resize window with mouse", { mouse = true })

-- Move focus with arrow keys
bindWithDescription(mainMod .. " + TAB", hl.dsp.exec_cmd(ipc .. "window-switcher hold"), "Window switcher")
bindWithDescription(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), "Focus window to the left")
bindWithDescription(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), "Focus window to the right")
bindWithDescription(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), "Focus window above")
bindWithDescription(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), "Focus window below")

-- Workspaces 1-5 + move window to workspace
for i = 1, 5 do
    bindWithDescription(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }), "Switch to workspace " .. i)
    bindWithDescription(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }), "Move window to workspace " .. i)
end

-- Intercept Power button
bindWithDescription("XF86PowerOff", hl.dsp.exec_cmd("noctalia msg panel-toggle session"), "Toggle session panel", { locked = true })

-- Volume
bindWithDescription("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"), "Increase volume", { locked = true, repeating = true })
bindWithDescription("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"), "Decrease volume", { locked = true, repeating = true })
bindWithDescription("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"), "Toggle mute", { locked = true })

-- Brightness
bindWithDescription("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +10%"), "Increase brightness", { locked = true, repeating = true })
bindWithDescription("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 10%-"), "Decrease brightness", { locked = true, repeating = true })

-- macOS-style screenshots (secondMod ≈ Cmd)
-- ⌘⇧3  full screen (focused output)
bindWithDescription(mainMod .. " + SHIFT + 3", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen"), "Screenshot focused monitor")

-- ⌘⇧4  region
bindWithDescription(mainMod .. " + CTRL + SHIFT + 4", hl.dsp.exec_cmd(ipc .. "screenshot-region"), "Screenshot region")

-- Multi-monitor: picker (≈ "choose display")
bindWithDescription(mainMod .. " + SHIFT + 5", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen pick"), "Screenshot with monitor picker")

-- All monitors as one image
bindWithDescription(mainMod .. " + CTRL + SHIFT + 3", hl.dsp.exec_cmd(ipc .. "screenshot-fullscreen all"), "Screenshot all monitors")

-- Lock screen
bindWithDescription(mainMod .. " + ALT + L", hl.dsp.exec_cmd(ipc .. "panel-toggle session"), "Lock screen")

-- Shortcut help screen
bindWithDescription(mainMod .. " + h", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/keybind_viewer $HOME/.config/hypr/keybinds.lua"), "Show keybind help")

-- Reload Hyprland config
bindWithDescription(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"), "Reload Hyprland config")

-- Mac-style overlays (Super = Cmd equivalent)
bindWithDescription(mainMod .. " + B", send_shortcut_once("CTRL", "b"), "Close the sidebar (Zed/VsCode/etc)")
bindWithDescription(mainMod .. " + c", universal_clipboard_shortcut("CTRL", "C", "CTRL SHIFT", "C"), "Copy")
bindWithDescription(mainMod .. " + x", send_shortcut_once("CTRL", "x"), "Cut")
bindWithDescription(mainMod .. " + v", universal_clipboard_shortcut("CTRL", "V", "CTRL SHIFT", "V"), "Paste")
bindWithDescription(mainMod .. " + s", send_shortcut_once("CTRL", "s"), "Save")
bindWithDescription(mainMod .. " + t", send_shortcut_once("CTRL", "t"), "New tab")
bindWithDescription(mainMod .. " + p", send_shortcut_once("CTRL", "p"), "Print")
bindWithDescription(mainMod .. " + f", universal_clipboard_shortcut("CTRL", "F", "CTRL SHIFT", "F"), "Find")
bindWithDescription(mainMod .. " + z", send_shortcut_once("CTRL", "z"), "Undo")
bindWithDescription(mainMod .. " + a", send_shortcut_once("CTRL", "a"), "Select all")
bindWithDescription(mainMod .. " + slash", send_shortcut_once("CTRL", "slash"), "Toggle comment (code editors)")
bindWithDescription(mainMod .. " + ALT + q", hl.dsp.window.kill(), "Force kill application")
bindWithDescription(mainMod .. " + ALT + escape", hl.dsp.window.kill(), "Force kill application")
bindWithDescription(mainMod .. " + CTRL + l", hl.dsp.exec_cmd("noctalia msg session lock"), "Lock screen")

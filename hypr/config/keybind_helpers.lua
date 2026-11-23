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

return {
    send_shortcut_once = send_shortcut_once,
    active_window_is_terminal = active_window_is_terminal,
    universal_clipboard_shortcut = universal_clipboard_shortcut,
}

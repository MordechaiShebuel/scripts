local home = os.getenv("HOME")
local help_cmd = string.format("%s/.config/hypr/./keybind_viewer %s/.config/hypr/binds.json", home, home)

hl.on("hyprland.start", function()
    -- Kesend_shortcut_onceep this list short while testing
    hl.exec_cmd("/usr/bin/pipewire")
    hl.exec_cmd("/usr/bin/pipewire -c pipewire-pulse.conf")
    hl.exec_cmd("dms run")
    hl.exec_cmd("~/.local/bin/game-caffeine.sh")
    hl.exec_cmd("nohup steam -silent >/dev/null 2>&1 &")
    hl.exec_cmd("octoxbps-notifier")
    hl.exec_cmd(home .. "/bin/nym-vpn")
    hl.exec_cmd(help_cmd)
end)

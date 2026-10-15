oxwm.autostart("/usr/bin/pipewire")
oxwm.autostart("/usr/bin/pipewire -c pipewire-pulse.conf")
-- oxwm.autostart("noctalia")          -- removed
oxwm.autostart("dunst")                -- notifications
oxwm.autostart("picom") -- optional compositor
oxwm.autostart("plank")
oxwm.autostart("feh --bg-fill " .. os.getenv("HOME") .. "/Pictures/wallpapers/void1.png")
oxwm.autostart("nitrogen --restore")
oxwm.autostart("nohup steam -silent >/dev/null 2>&1 &")
oxwm.autostart("octoxbps-notifier")
oxwm.autostart(home .. "/bin/nym-vpn")
-- keybind_viewer can stay if you still want it

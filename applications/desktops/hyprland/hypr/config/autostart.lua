-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("pipewire") -- Not necessary on RakuOS
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd("nohup steam -silent >/dev/null 2>&1 &")
    hl.exec_cmd("octoxbps-notifier")
    hl.exec_cmd("nym-vpn") -- This will need a different pathing command on Raku
end)

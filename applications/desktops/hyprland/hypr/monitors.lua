local hostname = os.getenv("HOSTNAME")

if not hostname then
    local pipe = io.popen("hostname")
    hostname = pipe and pipe:read("*l") or ""
    if pipe then pipe:close() end
end

if hostname == "prime" then
    hl.monitor({
        output = "DP-3",
        mode = "1920x1080@100",
        position = "0x0",
        scale = 1,
    })
    hl.monitor({
        output = "HDMI-A-1",
        mode = "1920x1080@100",
        position = "1920x0",
        scale = 1,
    })
elseif hostname == "media" then
    hl.monitor({
        output = "eDP-1",
        mode = "1920x1080@60",
        position = "0x0",
        scale = 1,
    })
    hl.monitor({
        output = "HDMI-A-1",
        mode = "1920x1080@60",
        position = "0x0",
        scale = 1,
        mirror = "eDP-1",
    })
elseif hostname == "games" then
    hl.monitor({
        output = "DP-3",
        mode = "1920x1080@60",
        position = "0x0",
        scale = 1,
    })
else
    -- Default if the hostname is missing or unrecognized
    hl.monitor({
        output = "",
        mode = "1920x1080@60",
    })
end

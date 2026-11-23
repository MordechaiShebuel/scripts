-- Hyprland default apps
-- Ganti nilai di sini untuk mengganti default app
-- (bind di binds.lua memakai variabel ini)
local hostname = os.getenv("HOSTNAME")

if not hostname then
    local pipe = io.popen("hostname")
    hostname = pipe and pipe:read("*l") or ""
    if pipe then pipe:close() end
end

TERMINAL      = "rio"
FILE_MANAGER  = "nemo"
BROWSER       = "zen"
EDITOR        = "zed"
CALCULATOR    = "gnome-calculator"

MUSIC_PLAYER  = "mpv"
VIDEO_PLAYER  = "vlc"
IMAGE_VIEWER  = "nomacs"

if hostname == "gamma" then
    MONITOR1 = "DP-3"
    MONITOR2 = "HDMI-A-1"
elseif hostname == "rome" then
    MONITOR1 = "eDP-1"
    MONITOR2 = "HDMI-A-1"
elseif hostname == "games" then
    MONITOR1 = "DP-3"
else
    --Monitors
    MONITOR1 = ""
    MONITOR2 = ""
    MONITOR3 = ""
end


PRIMARY_MONITOR = MONITOR1

-- Workspaces
-- NUM_WPM = 3 -- Number of workspaces per monitor (Max 10)

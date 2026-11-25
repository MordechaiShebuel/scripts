-- Hyprland default apps
-- Ganti nilai di sini untuk mengganti default app
-- (bind di binds.lua memakai variabel ini)

-- Detect OS
local function get_os_id()
    local f = io.open("/etc/os-release", "r")
    if not f then return "" end

    for line in f:lines() do
        local id = line:match('^ID%s*=%s*"?([^"\n]+)"?')
        if id then
            f:close()
            return id
        end
    end
    f:close()
    return ""
end

local os_id = get_os_id()

-- Set launcher based on OS
if os_id == "void" then
    LAUNCHER = ""                  -- no uwsm on Void
else
    LAUNCHER = "uwsm app -- "      -- recommended form (with --)
end

TERMINAL      = "rio"
FILE_MANAGER  = "nemo"
BROWSER       = "zen-browser"
EDITOR        = "zed"
CALCULATOR    = "gnome-calculator"

MUSIC_PLAYER  = "mpv"
VIDEO_PLAYER  = "vlc"
IMAGE_VIEWER  = "nomacs"

--Monitors
MONITOR1 = ""
MONITOR2 = ""
MONITOR3 = ""
PRIMARY_MONITOR = MONITOR1

-- Workspaces
-- NUM_WPM = 3 -- Number of workspaces per monitor (Max 10)

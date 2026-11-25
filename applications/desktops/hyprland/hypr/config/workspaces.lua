-- Workspace rules wiki https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- Add your workspace rules here. Increment the workspace number as you go. Do not have duplicate workspaces.
-- Named gaming workspace. No `default = true` here: with it, Hyprland treats the
-- named workspace as a low-id default and lands the session there on login instead
-- of workspace 1. Window rules still route matching apps here.
-- Special workspace
hl.workspace_rule({ workspace = "name:gaming", monitor = PRIMARY_MONITOR })

-- Workspaces 1–9
for i = 1, 9 do
    local mon = MONITOR1

    if MONITOR2 ~= "" and i % 2 == 0 then
        mon = MONITOR2 -- even numbers → MONITOR2
    end
    -- odd numbers (and everything if MONITOR2 is empty) stay on MONITOR1

    hl.workspace_rule({
        workspace  = tostring(i),
        monitor    = mon,
        default    = true,
        persistent = true,
    })
end

-- For other layouts such as scrolling, see example below
-- hl.workspace_rule({ workspace = "1", monitor = MONITOR1, default = true, persistent = true, layout = scroling })

-- EVERLUMEN // NEUROGLASS for Hyprland 0.55+ Lua configs.
-- Opt in by adding: dofile(os.getenv("HOME") .. "/.config/hypr/everlumen.lua")
-- Does not modify monitors, input settings or keybindings.
hl.config({
  general = {
    gaps_in = 6, gaps_out = 18, border_size = 2, layout = "dwindle",
    resize_on_border = true, allow_tearing = false,
    col = {
      active_border = { colors = {"rgba(3bf7eeee)", "rgba(ff42d0ee)", "rgba(c6ff3bee)"}, angle = 45 },
      inactive_border = "rgba(33435b99)"
    }
  },
  decoration = {
    rounding = 14, rounding_power = 3, active_opacity = 0.98, inactive_opacity = 0.92,
    shadow = { enabled = true, range = 24, render_power = 4, color = 0xCC03040C },
    blur = { enabled = true, size = 9, passes = 3, vibrancy = 0.24 }
  },
  animations = { enabled = true },
  dwindle = { preserve_split = true },
  misc = { disable_hyprland_logo = true, force_default_wallpaper = 0 }
})
hl.curve("everLumenBloom", { type = "bezier", points = {{0.16, 1.0}, {0.3, 1.0}} })
hl.curve("everLumenSnap", { type = "bezier", points = {{0.22, 1.0}, {0.36, 1.0}} })
hl.curve("everLumenSettle", { type = "spring", mass = 1.0, stiffness = 180.0, damping = 22.0 })
hl.animation({ leaf = "global", enabled = true, speed = 7, bezier = "everLumenBloom" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.8, spring = "everLumenSettle" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "everLumenSettle", style = "popin 92%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.0, bezier = "everLumenSnap", style = "popin 92%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3.2, bezier = "everLumenBloom" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.6, bezier = "everLumenSnap" })
hl.animation({ leaf = "border", enabled = true, speed = 4.0, bezier = "everLumenBloom" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.3, bezier = "everLumenBloom", style = "fade" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.0, bezier = "everLumenBloom" })
hl.on("hyprland.start", function()
  hl.exec_cmd("sh -lc 'if command -v everlumen-start >/dev/null 2>&1; then everlumen-start; elif command -v qs >/dev/null 2>&1; then qs -c everlumen; fi'")
end)

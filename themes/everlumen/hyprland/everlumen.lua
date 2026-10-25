-- EVERLUMEN compositor styling fragment for Hyprland Lua configuration.
-- Review the API names against your installed Hyprland release before use.
local hypr = require("hyprland")

hypr.general.gaps_in = 5
hypr.general.gaps_out = 12
hypr.general.border_size = 2
hypr.general."col.active_border" = "rgba(8fffd8ee) rgba(c6a7ffee) 45deg"
hypr.general."col.inactive_border" = "rgba(45556899)"

hypr.decoration.rounding = 16
hypr.decoration.active_opacity = 0.96
hypr.decoration.inactive_opacity = 0.91
hypr.decoration.shadow.enabled = true
hypr.decoration.shadow.range = 18
hypr.decoration.shadow.render_power = 3
hypr.decoration.shadow.color = "rgba(080f20aa)"
hypr.decoration.blur.enabled = true
hypr.decoration.blur.size = 7
hypr.decoration.blur.passes = 3
hypr.decoration.blur.vibrancy = 0.16

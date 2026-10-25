# NEUROGLASS customization

## Palettes
Edit quickshell/everlumen/palette.js. The four initial profiles are:
- Void Pulse: cyan + acid-lime on ink-black glass.
- Phosphor//X: green phosphor and cleanroom contrast.
- Ultraviolet: violet and magenta haze.
- Toxic Petal: mint, acid-lime and warm amber.

Each profile exposes background, surface, raised, line, text, muted, cyan, acid, pink, violet, orange and red tokens.

## The live lab
The Quickshell lab controls palette, glass/solid surface, glow, scanlines, angular geometry, compact dock, workspace visibility, dock position, 12/24-hour clock, seconds and text scale. Current selections are session-local; they reset when the shell is relaunched.

## Hyprland
The modern Lua fragment is for the Lua configuration workflow. Only load it from an existing config after checking the installed Hyprland version and keeping a backup. The legacy hyprlang fragment is for older configurations. Neither file intentionally changes monitor arrangements or keybindings.

## Applications
- Kitty: include terminal/kitty.conf.
- Rofi: select applications/rofi/everlumen.rasi.
- Neovim: source applications/neovim/everlumen.lua.
- GTK: merge gtk/everlumen.css into a compatible theme layer.
- UPM: the button and wrapper invoke the actual UPM program; package logic remains upstream.

Blur/glow are decorative. Disable them on low-power GPUs and preserve readable focus borders.

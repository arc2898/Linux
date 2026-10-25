# Customization

## Palette
Edit `quickshell/everlumen/palette.js`. The default palette is Abyss Bloom:
- Background: `#0b1020`
- Surface: `#151c2e`
- Text: `#e8f4f4`
- Mint: `#8fffd8`
- Lilac: `#c6a7ff`
- Petal: `#ffb6d9`

Other palettes in the token file are Lotus Orbit, Glacier Dream, and Solar Petal.

## Hyprland
The `.conf` file is a fragment; include it from your main config only after reviewing it. The Lua fragment is illustrative and may need adapting to the exact Lua configuration API of your Hyprland version.

## Quickshell
The QML panel is a starting point. Quickshell API availability can vary by release; verify workspace model properties against your installed version before enabling autostart.

## Apps
- Kitty: include `terminal/kitty.conf`.
- Rofi: use `applications/rofi/everlumen.rasi` with `rofi -theme`.
- Neovim: source `applications/neovim/everlumen.lua` from your init file.
- GTK: merge the CSS into a compatible GTK theme or custom stylesheet.

## Safety
Make a backup before editing your desktop configuration. Test manually before adding any component to autostart.

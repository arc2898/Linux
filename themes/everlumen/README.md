# EVERLUMEN

An original, modular Hyprland + Quickshell desktop theme inspired by soft alien bioluminescence.

## Components
- `hyprland/everlumen.conf`: compositor styling fragment
- `hyprland/everlumen.lua`: Lua configuration fragment for newer Hyprland setups
- `quickshell/everlumen/`: QML shell and palette
- `gtk/everlumen.css`: GTK styling
- `terminal/kitty.conf`: Kitty colors
- `applications/`: Rofi and Neovim styling
- `assets/`: vector artwork and wallpaper
- `install.sh` / `uninstall.sh`: user-local setup and rollback helpers

## Install
From this directory:

```sh
chmod +x install.sh
./install.sh --check
./install.sh
```

The installer is designed for user-local installation and should not overwrite the user's complete Hyprland configuration. Review the script and generated configuration before enabling it. Quickshell must be available from your distribution's repositories or installed separately.

## Safety
Back up your existing configuration before applying changes. Start the shell manually with `qs -c everlumen` before adding it to autostart. This theme is not a distribution or a replacement for Hyprland itself.

## License
See `LICENSE`.

# Troubleshooting

## Panel does not open
1. Run everlumen-doctor from a terminal inside Hyprland.
2. Confirm Hyprland and hyprctl are installed and the session has HYPRLAND_INSTANCE_SIGNATURE.
3. Confirm Quickshell is installed: qs --version (or consult qs --help if that build has no version option).
4. Test manually with qs -c everlumen and read terminal errors before adding autostart.
5. Check your Quickshell 0.3.x, Qt version and Hyprland workspace API compatibility.

## App launch actions fail
Install a terminal (Kitty, Foot or Alacritty) and an app launcher (Rofi, Fuzzel or Wofi). These are optional; their absence should not prevent the HUD from rendering. Notification actions need notify-send.

## UPM button fails
Run everlumen-doctor. If upm is missing, install Go and run ./install.sh --bootstrap-upm. That builds from the actual upstream source and executes go test and go vet before installing the user-local binary. The wrapper only styles the terminal output; UPM owns package operations.

## Package install is rejected
Use ./install.sh --deps and read each [WARN] reason. Repository package metadata, mirrors and package names differ by release. Review the native fallback rather than assuming that package manager availability proves a package exists. On Arch, update and package install are intentionally combined into pacman -Syu --needed to avoid partial upgrades.

## Quickshell package not available
Run everlumen-fallback-qs. It tries Nix user-profile install first and can then attempt a source build into the user-local prefix. Source builds need compatible Qt development packages. If it fails, use the official upstream build docs in docs/RESOURCES.md.

## Revert
The installer backs up theme-owned config/data paths before replacing them in a timestamped directory under ~/.local/state/everlumen/backups. The uninstaller archives only EVERLUMEN-owned paths and deliberately does not rewrite the rest of your Hyprland config. Remove the marker-delimited block manually if you previously enabled autoload and want to disable it.

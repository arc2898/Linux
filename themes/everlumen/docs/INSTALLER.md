# Installer and dependency routing

The theme is installed per-user. Dependency installation is opt-in, and the compositor is never installed unless --install-hyprland is explicitly provided.

## Options
- --check: strict read-only dependency diagnostic.
- --deps: prompts before dependency operations.
- --extras: add optional GUI utilities to the dependency pass.
- --install-hyprland: explicitly permit a Hyprland package install attempt.
- --bootstrap-upm: clone the actual UPM Go source, test, vet and build to ~/.local/bin/upm.
- --install-go: with --bootstrap-upm, permit asking the native package manager to install Go.
- --enable: back up the existing Hyprland config before adding an include/autostart marker.
- --yes: skip prompts for only the explicitly requested actions.

## Family routing
ID and ID_LIKE are checked for Arch, Debian/Ubuntu, Fedora/RHEL, openSUSE, Alpine, Void, Gentoo, NixOS and Guix. UPM uses explicit manager/package pairs for apt, dnf, zypper, xbps and Portage where available. Arch bypasses the current UPM Pacman adapter because it issues a non-full-upgrade install; the fallback uses pacman -Syu --needed. Unsupported families are reported rather than guessed.

Required desktop integration: Hyprland, hyprctl, Quickshell (qs), and a running Hyprland session for workspace controls. Optional helpers include hyprpaper, hyprlock, hypridle, hyprpicker, hyprsunset, hyprpolkitagent, portals, wl-clipboard, grim, slurp, notify-send, playerctl, wpctl and brightnessctl.

## Fallback
If Quickshell is not confirmed in configured repositories, the script tries a user-profile Nix install when Nix is available. It can then clone the official Quickshell source and attempt a user-local CMake/Ninja build. The source build needs compatible Qt6 development libraries and further system build dependencies; no guarantee is made that a generic source build succeeds on all distributions.

No root privileges are needed for theme files. Native package installs use sudo or root when required. Main user configuration is not edited without --enable.

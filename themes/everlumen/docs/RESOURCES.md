# Upstream resources and compatibility

- Hyprland Lua config: https://wiki.hypr.land/Configuring/Advanced-and-Creative/Lua
- Official Hyprland Lua example: https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
- Quickshell 0.3.x install: https://quickshell.org/docs/v0.3.2/guide/install-setup/
- Quickshell PanelWindow: https://quickshell.org/docs/v0.3.2/types/Quickshell/PanelWindow/
- Quickshell process launching: https://quickshell.org/docs/v0.3.2/types/Quickshell/Quickshell/
- Quickshell workspace model: https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandWorkspace/
- Quickshell source build: https://git.outfoxxed.me/quickshell/quickshell/src/branch/master/BUILD.md
- Universal Package Manager source: https://github.com/arc2898/Universal-Package-Manager
- Go installation docs: https://go.dev/doc/install

Quickshell package availability differs by distribution release and enabled repositories. Runtime QML validation must be performed on the target system. The dependency doctor checks installed binaries; the installer queries packages where the distro manager supports an availability check and offers a fallback when needed.

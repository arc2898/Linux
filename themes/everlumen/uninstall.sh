#!/bin/sh
# Archive theme-owned paths only. Never silently rewrite the full user config.
set -eu
CONFIG_HOME=\${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=\${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=\${XDG_STATE_HOME:-"$HOME/.local/state"}/everlumen
BIN_HOME=\${XDG_BIN_HOME:-"$HOME/.local/bin"}
ARCHIVE="$STATE_HOME/uninstall-archive/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p "$ARCHIVE"
move(){ src=$1; [ -e "$src" ] || [ -L "$src" ] || return 0; rel=$(printf '%s' "$src" | sed 's#^/##'); mkdir -p "$ARCHIVE/$(dirname "$rel")"; mv "$src" "$ARCHIVE/$rel"; echo "[ARCHIVE] $src"; }
move "$CONFIG_HOME/quickshell/everlumen"
move "$CONFIG_HOME/hypr/everlumen.lua"
move "$CONFIG_HOME/hypr/everlumen.conf"
move "$DATA_HOME/everlumen"
for name in everlumen-start everlumen-upm everlumen-doctor everlumen-deps everlumen-fallback-qs everlumen-bootstrap-upm; do move "$BIN_HOME/$name"; done
echo "Theme-owned paths were moved to $ARCHIVE"
echo "If you used --enable, remove the marker-delimited EVERLUMEN block from your main Hyprland config manually."

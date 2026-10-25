#!/usr/bin/env bash
set -Eeuo pipefail
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/everlumen"
if [[ ! -d "$DEST" ]]; then
  echo "EVERLUMEN user config not found: $DEST"
  exit 0
fi
printf 'This removes only the EVERLUMEN files at:\n  %s\n' "$DEST"
printf 'It does not edit your Hyprland, Kitty, or GTK main configuration files.\n'
read -r -p 'Continue? [y/N] ' answer
case "$answer" in
  y|Y|yes|YES) rm -rf -- "$DEST"; echo "Removed $DEST" ;;
  *) echo "Cancelled." ;;
esac

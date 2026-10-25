#!/bin/sh
# Neon banner wrapper; all command handling is delegated to upstream UPM.
set -u
PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"; export PATH
CYAN='\033[38;2;59;247;238m'; LIME='\033[38;2;198;255;59m'; PINK='\033[38;2;255;66;208m'; RESET='\033[0m'
printf '%bEVERLUMEN // PACKAGE UPLINK%b\n' "$CYAN" "$RESET"
printf '%b══════════════════════════════════════════════%b\n' "$LIME" "$RESET"
UPM=$(command -v upm 2>/dev/null || true)
[ -n "$UPM" ] || [ ! -x "$HOME/.local/bin/upm" ] || UPM="$HOME/.local/bin/upm"
[ -n "$UPM" ] || { printf '%bUPM is missing.%b\n' "$PINK" "$RESET" >&2; echo 'Build with everlumen-bootstrap-upm or visit https://github.com/arc2898/Universal-Package-Manager'; exit 127; }
exec "$UPM" "$@"

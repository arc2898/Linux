#!/usr/bin/env bash
# Styled console bridge for the real UPM executable; streams output and preserves its exit status.
set -uo pipefail
PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"
export PATH
CYAN='\033[38;2;59;247;238m'; LIME='\033[38;2;198;255;59m'; PINK='\033[38;2;255;66;208m'; VIOLET='\033[38;2;152;112;255m'; RESET='\033[0m'
printf '%b\n' "$CYAN"
printf '  ╔══════════════════════════════════════════════════╗\n'
printf '  ║  E V E R L U M E N   //   P A C K A G E   U P L I N K ║\n'
printf '  ╚══════════════════════════════════════════════════╝\n'
printf '%b[ NEUROGLASS ]%b styling bridge is online\n' "$LIME" "$RESET"
printf '%b[ UPM CORE   ]%b command engine remains upstream\n\n' "$VIOLET" "$RESET"
UPM=$(command -v upm 2>/dev/null || true)
[ -n "$UPM" ] || [ ! -x "$HOME/.local/bin/upm" ] || UPM="$HOME/.local/bin/upm"
if [ -z "$UPM" ]; then
  printf '%b[ NO SIGNAL ]%b UPM is missing.\n' "$PINK" "$RESET" >&2
  echo 'Build it with everlumen-bootstrap-upm or visit https://github.com/arc2898/Universal-Package-Manager' >&2
  exit 127
fi
# Stream output through a palette filter. pipefail preserves a failing UPM exit code.
"$UPM" "$@" 2>&1 | awk '
BEGIN {
  esc = sprintf("%c", 27)
  cyan = esc "[38;2;59;247;238m"
  lime = esc "[38;2;198;255;59m"
  pink = esc "[38;2;255;66;208m"
  violet = esc "[38;2;152;112;255m"
  muted = esc "[38;2;142;163;188m"
  reset = esc "[0m"
}
/(^|[[:space:]])(Error:|ERROR|failed|FAILED|error)([[:space:]]|$)/ { print pink $0 reset; next }
/(WARN|Warning|warning|Skipping)/ { print muted $0 reset; next }
/(Available Package Managers|Searching for|Installing|Removing|Updating|UPM version)/ { print cyan $0 reset; next }
/(\[ OK \]|\[SUCCESS\]|successfully|installed successfully|Success)/ { print lime $0 reset; next }
/(\[apt\]|\[dnf\]|\[pacman\]|\[zypper\]|\[xbps\]|\[flatpak\]|\[snap\])/ { print violet $0 reset; next }
{ print $0 }
'
status=$?
exit "$status"

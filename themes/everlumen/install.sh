#!/usr/bin/env bash
set -Eeuo pipefail

# EVERLUMEN user-local installer. It does not install Hyprland or modify the
# main Hyprland config. It copies theme files and prints the opt-in source line.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/everlumen"
BACKUP="${XDG_STATE_HOME:-$HOME/.local/state}/everlumen/backups/$(date +%Y%m%d-%H%M%S)"
CHECK=0
NO_DEPS=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    --no-deps) NO_DEPS=1 ;;
    --help)
      printf 'Usage: %s [--check] [--no-deps]\n' "$0"
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

for cmd in bash install; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 1; }
done

if (( CHECK )); then
  printf 'EVERLUMEN source: %s\nDestination: %s\n' "$ROOT" "$DEST"
  for cmd in hyprland qs; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf 'OK: %s found\n' "$cmd"
    else
      printf 'NOTICE: %s not found (required only for its integration)\n' "$cmd"
    fi
  done
  exit 0
fi

if [[ ! -d "$HOME" || "$HOME" == "/" ]]; then
  echo "Refusing unsafe HOME: $HOME" >&2
  exit 1
fi

mkdir -p "$DEST" "$BACKUP"
for rel in hyprland/everlumen.conf terminal/kitty.conf gtk/everlumen.css; do
  src="$ROOT/$rel"
  [[ -f "$src" ]] || { echo "Missing source file: $src" >&2; exit 1; }
  target="$DEST/$rel"
  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" ]]; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    cp -a "$target" "$BACKUP/$rel"
  fi
  install -m 0644 "$src" "$target"
done

printf '\nEVERLUMEN files installed to %s\n' "$DEST"
printf 'Existing replaced files backed up to %s\n' "$BACKUP"
printf '\nEnable Hyprland styling by adding this line to your config:\n  source = %s/hyprland/everlumen.conf\n' "$DEST"
printf 'Kitty: include %s/terminal/kitty.conf in kitty.conf\n' "$DEST"
printf 'GTK: merge %s/gtk/everlumen.css into your GTK theme CSS if supported\n' "$DEST"
printf '\nNo package manager was invoked. Install Quickshell separately if you want the custom shell.\n'

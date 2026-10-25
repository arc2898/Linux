#!/bin/sh
# EVERLUMEN // NEUROGLASS: per-user installation, backed up and opt-in.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
BIN_HOME=${XDG_BIN_HOME:-"$HOME/.local/bin"}
STAMP=$(date +%Y%m%d-%H%M%S)-$$
BACKUP="$STATE_HOME/everlumen/backups/$STAMP"
DO_DEPS=0 YES=0 ENABLE=0 INSTALL_HYPRLAND=0 EXTRAS=0 CHECK=0 BOOTSTRAP=0 INSTALL_GO=0
usage(){ cat <<'HELP'
EVERLUMEN // NEUROGLASS
  --check               Run strict dependency check
  --deps                Offer dependency install (UPM-first, native fallback)
  --extras              With --deps, offer optional GUI utilities
  --install-hyprland    With --deps, explicitly permit Hyprland install
  --bootstrap-upm       Build the real upstream UPM (requires Go)
  --install-go          With --bootstrap-upm, permit offering Go installation
  --enable              Back up and add theme include to an existing Hyprland config
  --yes                 Skip prompts for explicitly requested package operations
  --no-deps             Do not install packages (default)
  --help                Show this help
No package operations occur by default. Hyprland itself is never installed without --install-hyprland.
HELP
}
while [ "$#" -gt 0 ]; do
 case "$1" in
  --check) CHECK=1;; --deps) DO_DEPS=1;; --no-deps) DO_DEPS=0;;
  --extras) EXTRAS=1;; --install-hyprland) INSTALL_HYPRLAND=1;;
  --bootstrap-upm) BOOTSTRAP=1;; --install-go) INSTALL_GO=1;;
  --enable) ENABLE=1;; --yes|-y) YES=1;; --help|-h) usage; exit 0;;
  *) echo "Unknown option: $1" >&2; usage >&2; exit 2;;
 esac
 shift
done
[ "$CHECK" -eq 0 ] || exec "$ROOT/scripts/doctor.sh" --strict
PATH="$BIN_HOME:$HOME/.local/bin:$HOME/.nix-profile/bin:$PATH"; export PATH
if [ "$BOOTSTRAP" -eq 1 ]; then
 set --; [ "$YES" -eq 0 ] || set -- "$@" --yes; [ "$INSTALL_GO" -eq 0 ] || set -- "$@" --install-go
 "$ROOT/scripts/bootstrap-upm.sh" "$@" || echo '[WARN] UPM bootstrap failed; native fallback remains available.'
fi
if [ "$DO_DEPS" -eq 1 ]; then
 set --; [ "$YES" -eq 0 ] || set -- "$@" --yes; [ "$EXTRAS" -eq 0 ] || set -- "$@" --extras
 [ "$INSTALL_HYPRLAND" -eq 0 ] || set -- "$@" --install-hyprland
 "$ROOT/scripts/install-dependencies.sh" "$@" || echo '[WARN] Some dependencies remain missing; theme files will still be installed.'
fi
for file in quickshell/everlumen/shell.qml quickshell/everlumen/palette.js hyprland/everlumen.lua hyprland/everlumen.conf manifest.json; do
 [ -f "$ROOT/$file" ] || { echo "Missing required source: $file" >&2; exit 1; }
done
mkdir -p "$BACKUP"
backup_path(){ target=$1; [ -e "$target" ] || [ -L "$target" ] || return 0; rel=$(printf '%s' "$target" | sed 's#^/##'); mkdir -p "$BACKUP/$(dirname "$rel")"; mv "$target" "$BACKUP/$rel"; echo "[BACKUP] $target"; }
copy_tree(){ src=$1 dst=$2; [ -d "$src" ] || { echo "Missing directory: $src" >&2; exit 1; }; backup_path "$dst"; mkdir -p "$dst"; cp -R "$src"/. "$dst"/; echo "[COPY] $dst"; }
copy_file(){ src=$1 dst=$2; [ -f "$src" ] || { echo "Missing file: $src" >&2; exit 1; }; backup_path "$dst"; mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; echo "[COPY] $dst"; }
copy_tree "$ROOT/assets" "$DATA_HOME/everlumen/assets"
copy_tree "$ROOT/docs" "$DATA_HOME/everlumen/docs"
copy_tree "$ROOT/gtk" "$DATA_HOME/everlumen/gtk"
copy_tree "$ROOT/terminal" "$DATA_HOME/everlumen/terminal"
copy_tree "$ROOT/applications" "$DATA_HOME/everlumen/applications"
copy_tree "$ROOT/scripts" "$DATA_HOME/everlumen/scripts"
copy_file "$ROOT/manifest.json" "$DATA_HOME/everlumen/manifest.json"
copy_tree "$ROOT/quickshell/everlumen" "$CONFIG_HOME/quickshell/everlumen"
copy_file "$ROOT/hyprland/everlumen.lua" "$CONFIG_HOME/hypr/everlumen.lua"
copy_file "$ROOT/hyprland/everlumen.conf" "$CONFIG_HOME/hypr/everlumen.conf"
mkdir -p "$BIN_HOME"
cat > "$BIN_HOME/everlumen-start" <<EOF
#!/bin/sh
set -eu
PATH="$BIN_HOME:\$HOME/.local/bin:\$HOME/.nix-profile/bin:\$PATH"; export PATH
command -v qs >/dev/null 2>&1 || { echo 'Quickshell (qs) is missing. Run everlumen-doctor.' >&2; exit 127; }
if command -v pgrep >/dev/null 2>&1 && pgrep -f '[q]s -c everlumen' >/dev/null 2>&1; then echo 'Quickshell is already running.'; exit 0; fi
exec qs -c everlumen
EOF
cat > "$BIN_HOME/everlumen-upm" <<EOF
#!/bin/sh
set -eu
PATH="$BIN_HOME:\$HOME/.local/bin:\$HOME/.nix-profile/bin:\$PATH"; export PATH
exec "$DATA_HOME/everlumen/scripts/everlumen-upm.sh" "\$@"
EOF
for spec in "doctor:doctor.sh" "deps:install-dependencies.sh" "fallback-qs:fallback-quickshell.sh" "bootstrap-upm:bootstrap-upm.sh"; do
 name=${spec%%:*}; file=${spec#*:}
 cat > "$BIN_HOME/everlumen-$name" <<EOF
#!/bin/sh
set -eu
PATH="$BIN_HOME:\$HOME/.local/bin:\$HOME/.nix-profile/bin:\$PATH"; export PATH
exec "$DATA_HOME/everlumen/scripts/$file" "\$@"
EOF
done
chmod 0755 "$BIN_HOME"/everlumen-start "$BIN_HOME"/everlumen-upm "$BIN_HOME"/everlumen-doctor "$BIN_HOME"/everlumen-deps "$BIN_HOME"/everlumen-fallback-qs "$BIN_HOME"/everlumen-bootstrap-upm
if [ "$ENABLE" -eq 1 ]; then
 HYPR="$CONFIG_HOME/hypr"
 if [ -f "$HYPR/hyprland.lua" ]; then
  MAIN="$HYPR/hyprland.lua"; MARK='-- EVERLUMEN NEUROGLASS AUTOLOAD BEGIN'
  if ! grep -Fq "$MARK" "$MAIN"; then cp -p "$MAIN" "$BACKUP/hyprland.lua.pre-enable"; printf '\n%s\ndofile("%s/hypr/everlumen.lua")\n-- EVERLUMEN NEUROGLASS AUTOLOAD END\n' "$MARK" "$CONFIG_HOME" >> "$MAIN"; fi
 elif [ -f "$HYPR/hyprland.conf" ]; then
  MAIN="$HYPR/hyprland.conf"; MARK='# EVERLUMEN NEUROGLASS AUTOLOAD BEGIN'
  if ! grep -Fq "$MARK" "$MAIN"; then cp -p "$MAIN" "$BACKUP/hyprland.conf.pre-enable"; printf '\n%s\nsource = %s/hypr/everlumen.conf\nexec-once = %s/everlumen-start\n# EVERLUMEN NEUROGLASS AUTOLOAD END\n' "$MARK" "$CONFIG_HOME" "$BIN_HOME" >> "$MAIN"; fi
 else echo '[WARN] No existing Hyprland config found. Nothing was created.'; fi
fi
echo
echo 'EVERLUMEN // NEUROGLASS installed per-user.'
echo "Backup: $BACKUP"
echo 'Commands: everlumen-doctor, everlumen-deps, everlumen-upm, everlumen-fallback-qs, everlumen-bootstrap-upm'
echo 'Launch: everlumen-start  |  Enable autoload: ./install.sh --enable'
echo 'Dependencies are opt-in: ./install.sh --deps --extras'
"$DATA_HOME/everlumen/scripts/doctor.sh" || true

#!/bin/sh
# Offline checks and install test in a disposable HOME.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
echo '[CHECK] shell syntax'
for f in "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT"/scripts/*.sh; do sh -n "$f"; done
echo '[CHECK] palette JavaScript'
if command -v node >/dev/null 2>&1; then sed '1{/^\.pragma library$/d;}' "$ROOT/quickshell/everlumen/palette.js" >/tmp/everlumen-palette.js; node --check /tmp/everlumen-palette.js; else echo '[SKIP] node unavailable'; fi
echo '[CHECK] manifest and SVG XML'
python3 - "$ROOT" <<'PY'
import json,pathlib,sys,xml.etree.ElementTree as ET
root=pathlib.Path(sys.argv[1]); json.loads((root/'manifest.json').read_text())
for path in root.rglob('*.svg'): ET.parse(path); print('SVG OK:',path.relative_to(root))
print('manifest OK')
PY
tmp=$(mktemp -d); trap 'rm -rf "$tmp" /tmp/everlumen-palette.js' EXIT
mkdir -p "$tmp/home"
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/config" XDG_DATA_HOME="$tmp/home/data" XDG_STATE_HOME="$tmp/home/state" XDG_BIN_HOME="$tmp/home/bin" "$ROOT/install.sh" >"$tmp/install.log"
test -f "$tmp/home/config/quickshell/everlumen/shell.qml"
test -f "$tmp/home/config/hypr/everlumen.lua"
test -x "$tmp/home/bin/everlumen-upm"
test -f "$tmp/home/data/everlumen/assets/everlumen-wallpaper.svg"
HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/home/config" XDG_DATA_HOME="$tmp/home/data" XDG_STATE_HOME="$tmp/home/state" XDG_BIN_HOME="$tmp/home/bin" "$ROOT/install.sh" >"$tmp/reinstall.log"
test -f "$tmp/home/config/quickshell/everlumen/shell.qml"
echo '[PASS] static checks and isolated install smoke test'

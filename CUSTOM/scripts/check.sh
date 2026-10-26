#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
PYTHONPATH="$ROOT" python3 -m custom --validate
PYTHONPATH="$ROOT" python3 -m custom --profile "$ROOT/examples/debian-minimal.json" --validate
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
PYTHONPATH="$ROOT" python3 -m custom --profile "$ROOT/examples/debian-minimal.json" --plan "$tmp"
python3 - "$tmp" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f: data = json.load(f)
assert data["builder"] == "CUSTOM"
assert data["status"] == "plan-only"
assert "sudo" in data["package_selection"]
print("CUSTOM checks passed.")
PY

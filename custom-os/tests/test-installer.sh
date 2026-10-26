#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
sh -n "$ROOT/installer/custom-tui.sh"
sh -n "$ROOT/scripts/build-iso.sh"
grep -q 'exec /init.custom-original' "$ROOT/scripts/build-iso.sh"
grep -q 'custom-preseed.cfg' "$ROOT/scripts/build-iso.sh"
grep -q 'CUSTOM_GITHUB_COMPONENT_URL' "$ROOT/installer/custom-tui.sh"
grep -q 'runs GitHub code' "$ROOT/installer/custom-tui.sh"
grep -q '104857600' "$ROOT/scripts/build-iso.sh"
printf 'CUSTOM OS static tests passed.\n'

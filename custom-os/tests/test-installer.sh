#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
sh -n "$ROOT/installer/custom-tui.sh"
sh -n "$ROOT/scripts/build-iso.sh"
grep -q 'preseed/file=/preseed/custom.cfg' "$ROOT/scripts/build-iso.sh"
grep -q 'isolinux/txt.cfg' "$ROOT/scripts/build-iso.sh"
grep -q 'boot/grub/grub.cfg' "$ROOT/scripts/build-iso.sh"
grep -q 'preseed/custom.cfg' "$ROOT/scripts/build-iso.sh"
grep -q '/tmp/custom-packages' "$ROOT/scripts/build-iso.sh"
printf 'CUSTOM OS static tests passed.\n'

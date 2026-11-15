#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
for script in \
    "$ROOT/installer/custom-tui.sh" \
    "$ROOT/installer/custom-hardware-detect.sh" \
    "$ROOT/installer/custom-install-target.sh" \
    "$ROOT/installer/custom-apply-firmware.sh" \
    "$ROOT/scripts/build-iso.sh" \
    "$ROOT/tests/test-installer.sh" \
    "$ROOT/tests/test-hardware-detect.sh" \
    "$ROOT/tests/test-firmware-stage.sh" \
    "$ROOT/tests/qemu-smoke.sh"; do
    sh -n "$script"
done
sh "$ROOT/tests/test-hardware-detect.sh"
sh "$ROOT/tests/test-firmware-stage.sh"
grep -q 'preseed/file=/preseed/custom.cfg' "$ROOT/scripts/build-iso.sh"
grep -q 'BIOS_CFG=' "$ROOT/scripts/build-iso.sh"
grep -q 'UEFI_CFG=' "$ROOT/scripts/build-iso.sh"
grep -q 'apt-setup/non-free-firmware' "$ROOT/scripts/build-iso.sh"
grep -q 'custom-install-target.sh' "$ROOT/scripts/build-iso.sh"
grep -q 'upm -b install apt' "$ROOT/installer/custom-install-target.sh"
grep -q 'firmware-iwlwifi' "$ROOT/installer/custom-hardware-detect.sh"
grep -q 'CUSTOM profile captured' "$ROOT/installer/custom-tui.sh"
grep -q 'mount -t sysfs sysfs /sys' "$ROOT/scripts/build-iso.sh"
grep -q 'custom-apply-firmware.sh' "$ROOT/scripts/build-iso.sh"
grep -q '250 MiB' "$ROOT/scripts/build-iso.sh"
printf 'CUSTOM OS static tests passed.\n'

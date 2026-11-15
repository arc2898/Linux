#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM
STATE="$TMP/state"
SYS="$TMP/sys"
PAYLOAD="$TMP/payload"
DEST="$TMP/firmware"
mkdir -p "$STATE" "$SYS" "$PAYLOAD/firmware-iwlwifi/usr/lib/firmware/iwlwifi" "$PAYLOAD/firmware-nvidia-graphics/usr/lib/firmware/nvidia" "$DEST"
printf 'firmware-iwlwifi\nfirmware-nvidia-graphics\n' > "$STATE/hardware-packages.txt"
printf 'intel-wifi-test-blob\n' > "$PAYLOAD/firmware-iwlwifi/usr/lib/firmware/iwlwifi/test.bin"
printf 'should-not-be-staged\n' > "$PAYLOAD/firmware-nvidia-graphics/usr/lib/firmware/nvidia/test.bin"
CUSTOM_STATE_DIR="$STATE" CUSTOM_FIRMWARE_ROOT="$PAYLOAD" CUSTOM_FIRMWARE_DEST="$DEST" CUSTOM_SYSFS_ROOT="$SYS" sh "$ROOT/installer/custom-apply-firmware.sh"
grep -q 'intel-wifi-test-blob' "$DEST/iwlwifi/test.bin"
[ ! -e "$DEST/nvidia/test.bin" ]
printf 'Selective firmware staging fixture tests passed.\n'

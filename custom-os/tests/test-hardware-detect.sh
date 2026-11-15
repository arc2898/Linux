#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM
SYS="$TMP/sys"; PROC="$TMP/proc"; OUT="$TMP/state"
mkdir -p "$SYS/bus/pci/devices/0000:00:14.3" "$SYS/bus/pci/devices/0000:01:00.0" "$PROC" "$OUT"
printf '0x8086\n' > "$SYS/bus/pci/devices/0000:00:14.3/vendor"
printf '0x51f0\n' > "$SYS/bus/pci/devices/0000:00:14.3/device"
printf '0x028000\n' > "$SYS/bus/pci/devices/0000:00:14.3/class"
printf '0x10de\n' > "$SYS/bus/pci/devices/0000:01:00.0/vendor"
printf '0x2684\n' > "$SYS/bus/pci/devices/0000:01:00.0/device"
printf '0x030000\n' > "$SYS/bus/pci/devices/0000:01:00.0/class"
printf 'processor : 0\nvendor_id : GenuineIntel\n' > "$PROC/cpuinfo"
CUSTOM_SYSFS_ROOT="$SYS" CUSTOM_PROC_ROOT="$PROC" CUSTOM_STATE_DIR="$OUT" sh "$ROOT/installer/custom-hardware-detect.sh" >/dev/null
grep -qx 'firmware-iwlwifi' "$OUT/hardware-packages.txt"
grep -qx 'firmware-nvidia-graphics' "$OUT/hardware-packages.txt"
grep -qx 'intel-microcode' "$OUT/hardware-packages.txt"
! grep -qx 'firmware-realtek' "$OUT/hardware-packages.txt"
grep -q 'kernel-driver=unbound' "$OUT/hardware-report.txt"
printf 'Hardware detection fixture tests passed.\n'

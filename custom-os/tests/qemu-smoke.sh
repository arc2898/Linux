#!/bin/sh
# Smoke-test the CUSTOM TUI in the patched installer initramfs.
# This does not claim to test actual ISO firmware boot or disk installation.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
WORK="$ROOT/.build"
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1" >&2; exit 2; }; }
need qemu-system-x86_64
need timeout
KERNEL=$(find "$WORK/iso-root" -type f \( -name vmlinuz -o -name linux \) -print | sed -n '1p')
INITRD=$(find "$WORK/iso-root" -type f -name initrd.gz -print | sed -n '1p')
[ -n "$KERNEL" ] && [ -n "$INITRD" ] || { echo "Kernel/initrd not found; run build-iso.sh first." >&2; exit 2; }
LOG="$WORK/qemu-smoke.log"
mkdir -p "$WORK"
# Inputs: system name, DE, display manager, WM, shell, icon, five category
# lists, extra package list, and optional GitHub component.
set +e
printf 'custom\nnone\nnone\nbash\nnone\n\n\n\n\n\n\n\n' |
  timeout 60s qemu-system-x86_64 -machine pc,accel=tcg -m 1024 -smp 1 \
    -display none -serial stdio -monitor none -no-reboot -no-shutdown \
    -kernel "$KERNEL" -initrd "$INITRD" \
    -append 'console=tty0 console=ttyS0,115200n8 --- preseed/file=/preseed/custom.cfg' \
    >"$LOG" 2>&1
status=$?
set -e
if ! grep -q 'CUSTOM profile captured' "$LOG"; then
    echo "QEMU did not reach the end of the CUSTOM TUI (exit $status)." >&2
    tail -n 120 "$LOG" >&2 || true
    exit 1
fi
printf 'CUSTOM TUI smoke test passed (QEMU exit %s after handoff).\n' "$status"

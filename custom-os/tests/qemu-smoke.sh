#!/bin/sh
# Boot the patched Debian kernel/initrd in QEMU with a serial console, answer
# the CUSTOM prompts, and assert that the TUI completed before D-I continues.
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
WORK=${CUSTOM_BUILD_DIR:-"$ROOT/.build"}
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing command: $1" >&2; exit 2; }; }
need qemu-system-x86_64
need timeout
KERNEL=$(find "$WORK/iso-root" -type f \( -name vmlinuz -o -name linux \) -print | head -n 1)
INITRD=$(find "$WORK/iso-root" -type f -name initrd.gz -print | head -n 1)
[ -n "$KERNEL" ] && [ -n "$INITRD" ] || { echo "Kernel/initrd not found; run build-iso.sh first." >&2; exit 2; }
LOG="$WORK/qemu-smoke.log"
mkdir -p "$WORK"
# Answers: DE, display manager, window manager, shell, icon package, extra
# packages, GitHub URL. The test intentionally never runs the full installer.
set +e
printf 'none\nnone\nnone\nbash\ndefault\n\n\n' |
  timeout 35s qemu-system-x86_64 -machine pc,accel=tcg -m 1024 -smp 1 \
    -display none -serial stdio -monitor none -no-reboot -no-shutdown \
    -kernel "$KERNEL" -initrd "$INITRD" \
    -append 'console=tty0 console=ttyS0,115200n8 --- preseed/file=/custom-preseed.cfg' \
    >"$LOG" 2>&1
status=$?
set -e
if ! grep -q 'CUSTOM configuration prepared' "$LOG"; then
    echo "QEMU did not reach the end of the CUSTOM TUI (exit $status)." >&2
    tail -n 120 "$LOG" >&2 || true
    exit 1
fi
printf 'QEMU smoke test passed: CUSTOM TUI completed (QEMU exit %s after handing off to Debian Installer).\n' "$status"

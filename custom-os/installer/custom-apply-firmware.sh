#!/bin/sh
# Stage only detected wireless firmware into the installer initramfs, then reprobe.
# Graphics firmware and CPU microcode are installed only in the target system.
# shellcheck disable=SC2154
set -e
STATE_DIR=/var/lib/custom
PAYLOAD_ROOT=/custom-firmware
FIRMWARE_ROOT=/lib/firmware
SYSFS_ROOT=/sys
[ -z "$CUSTOM_STATE_DIR" ] || STATE_DIR=$CUSTOM_STATE_DIR
[ -z "$CUSTOM_FIRMWARE_ROOT" ] || PAYLOAD_ROOT=$CUSTOM_FIRMWARE_ROOT
[ -z "$CUSTOM_FIRMWARE_DEST" ] || FIRMWARE_ROOT=$CUSTOM_FIRMWARE_DEST
[ -z "$CUSTOM_SYSFS_ROOT" ] || SYSFS_ROOT=$CUSTOM_SYSFS_ROOT
mkdir -p "$FIRMWARE_ROOT"
[ -s "$STATE_DIR/hardware-packages.txt" ] || exit 0
while IFS= read -r package; do
    case "$package" in
        firmware-iwlwifi|firmware-realtek|firmware-brcm80211|firmware-atheros|firmware-mediatek) ;;
        *) continue ;;
    esac
    payload="$PAYLOAD_ROOT/$package"
    [ -d "$payload" ] || continue
    for source in "$payload/lib/firmware" "$payload/usr/lib/firmware"; do
        if [ -d "$source" ]; then cp -R "$source"/. "$FIRMWARE_ROOT"/; fi
    done
done < "$STATE_DIR/hardware-packages.txt"
# Load matching wireless modules only where the kernel exposes a PCI alias.
if command -v modprobe >/dev/null 2>&1; then
    for device in "$SYSFS_ROOT"/bus/pci/devices/*; do
        [ -r "$device/class" ] && [ -r "$device/modalias" ] || continue
        class=$(cat "$device/class")
        case "$class" in 0x0280*) ;; *) continue ;; esac
        modalias=$(cat "$device/modalias")
        modprobe "$modalias" 2>/dev/null || true
        if [ ! -L "$device/driver" ] && [ -w "$SYSFS_ROOT/bus/pci/drivers_probe" ]; then
            printf '%s' "$(basename "$device")" > "$SYSFS_ROOT/bus/pci/drivers_probe" 2>/dev/null || true
        fi
    done
fi

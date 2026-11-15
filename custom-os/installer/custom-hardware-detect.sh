#!/bin/sh
set -e
SYSFS_ROOT=/sys
PROC_ROOT=/proc
STATE_DIR=/var/lib/custom
[ -z "$CUSTOM_SYSFS_ROOT" ] || SYSFS_ROOT=$CUSTOM_SYSFS_ROOT
[ -z "$CUSTOM_PROC_ROOT" ] || PROC_ROOT=$CUSTOM_PROC_ROOT
[ -z "$CUSTOM_STATE_DIR" ] || STATE_DIR=$CUSTOM_STATE_DIR
REPORT="$STATE_DIR/hardware-report.txt"
PACKAGES="$STATE_DIR/hardware-packages.txt"
mkdir -p "$STATE_DIR"
: > "$REPORT"
: > "$PACKAGES"
add_package() {
    package=$1
    case "$package" in ''|*[!A-Za-z0-9+._-]*) return 0 ;; esac
    if ! grep -qxF "$package" "$PACKAGES" 2>/dev/null; then printf '%s\n' "$package" >> "$PACKAGES"; fi
}
printf 'CUSTOM hardware inventory\n' >> "$REPORT"
printf 'Source: Linux sysfs; no vendor driver installers are executed.\n\n' >> "$REPORT"
cpu_vendor=$(sed -n 's/^vendor_id[[:space:]]*:[[:space:]]*//p' "$PROC_ROOT/cpuinfo" 2>/dev/null | sed -n '1p' || true)
case "$cpu_vendor" in
    GenuineIntel) printf 'CPU vendor: Intel (microcode package recommended)\n' >> "$REPORT"; add_package intel-microcode ;;
    AuthenticAMD) printf 'CPU vendor: AMD (microcode package recommended)\n' >> "$REPORT"; add_package amd64-microcode ;;
    '') printf 'CPU vendor: not identified\n' >> "$REPORT" ;;
    *) printf 'CPU vendor: %s (no automatic package mapping)\n' "$cpu_vendor" >> "$REPORT" ;;
esac
count=0
for device in "$SYSFS_ROOT"/bus/pci/devices/*; do
    [ -d "$device" ] || continue
    [ -r "$device/vendor" ] && [ -r "$device/device" ] && [ -r "$device/class" ] || continue
    vendor=$(cat "$device/vendor")
    device_id=$(cat "$device/device")
    class=$(cat "$device/class")
    driver=unbound
    if [ -L "$device/driver" ] && command -v readlink >/dev/null 2>&1; then driver=$(basename "$(readlink "$device/driver")"); fi
    category=other
    case "$class" in
        0x02*) category=network ;; 0x03*) category=graphics ;;
        0x01*) category=storage ;; 0x04*) category=multimedia ;;
        0x0c03*) category=usb-controller ;;
    esac
    bdf=$(basename "$device")
    printf 'PCI %s | %s:%s | class=%s | category=%s | kernel-driver=%s\n' "$bdf" "$vendor" "$device_id" "$class" "$category" "$driver" >> "$REPORT"
    count=$((count + 1))
    case "$class" in
        0x0280*)
            case "$vendor" in
                0x8086) add_package firmware-iwlwifi ;; 0x10ec) add_package firmware-realtek ;;
                0x14e4) add_package firmware-brcm80211 ;; 0x168c|0x17cb) add_package firmware-atheros ;;
                0x14c3) add_package firmware-mediatek ;;
            esac ;;
        0x03*)
            case "$vendor" in
                0x1002) add_package firmware-amd-graphics ;; 0x10de) add_package firmware-nvidia-graphics ;;
                0x8086) add_package firmware-intel-graphics ;;
            esac ;;
    esac
done
if [ "$count" -eq 0 ]; then
    printf 'PCI devices: none visible (possibly a VM or restricted firmware inventory).\n' >> "$REPORT"
else printf '\nPCI devices inventoried: %s\n' "$count" >> "$REPORT"; fi
if [ -d "$SYSFS_ROOT/bus/usb/devices" ]; then
    usb_count=0
    for device in "$SYSFS_ROOT"/bus/usb/devices/*; do
        [ -r "$device/idVendor" ] && [ -r "$device/idProduct" ] || continue
        printf 'USB %s | %s:%s\n' "$(basename "$device")" "$(cat "$device/idVendor")" "$(cat "$device/idProduct")" >> "$REPORT"
        usb_count=$((usb_count + 1))
    done
    [ "$usb_count" -eq 0 ] || printf 'USB devices inventoried: %s (no automatic USB driver guesses).\n' "$usb_count" >> "$REPORT"
fi
printf '\nFirmware package recommendations (known PCI mappings only):\n' >> "$REPORT"
if [ -s "$PACKAGES" ]; then sed 's/^/  - /' "$PACKAGES" >> "$REPORT"
else printf '  - none; kernel drivers will be left to the distro kernel\n' >> "$REPORT"; fi
printf 'Hardware scan complete.\n'

#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
WORK="$ROOT/.build"
DIST="$ROOT/dist"
ARCH=amd64
SUITE=stable
UPM_BINARY="$WORK/upm"
UPM_COMMIT=$(cat "$WORK/upm-version")
MAX_ISO_BYTES=157286400
BASE_URL="https://deb.debian.org/debian/dists/$SUITE/main/installer-$ARCH/current/images/netboot"
SOURCE_ISO="$WORK/debian-mini.iso"
ISO_ROOT="$WORK/iso-root"
VERIFY_ROOT="$WORK/verify-root"
INITRD_TREE="$WORK/initrd-tree"
PATCHED_INITRD="$WORK/initrd-patched.gz"
OUTPUT="$DIST/custom-os-$ARCH.iso"

die() { printf 'CUSTOM ISO build error: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command missing: $1"; }
for cmd in curl xorriso gzip cpio find sed grep wc tr sha256sum file basename; do need "$cmd"; done
[ -s "$UPM_BINARY" ] || die "compiled UPM binary required at $UPM_BINARY"
file "$UPM_BINARY" | grep -q 'ELF 64-bit' || die "UPM binary is not a 64-bit Linux ELF executable"
[ -f "$ROOT/installer/custom-tui.sh" ] || die "missing CUSTOM TUI"
[ -f "$ROOT/installer/custom-hardware-detect.sh" ] || die "missing hardware detector"
[ -f "$ROOT/installer/custom-install-target.sh" ] || die "missing target installer helper"
mkdir -p "$WORK" "$DIST"
rm -rf "$ISO_ROOT" "$VERIFY_ROOT" "$INITRD_TREE" "$PATCHED_INITRD"
mkdir -p "$ISO_ROOT" "$VERIFY_ROOT" "$INITRD_TREE"
curl --fail --location --retry 4 --retry-delay 2 --connect-timeout 20 --output "$SOURCE_ISO" "$BASE_URL/mini.iso" || die "Debian mini ISO download failed"
xorriso -indev "$SOURCE_ISO" -toc >/dev/null 2>&1 || die "source ISO invalid"
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$ISO_ROOT" >/dev/null 2>&1 || die "ISO extraction failed"
INITRD_PATH=$(find "$ISO_ROOT" -type f -name initrd.gz -print | sed -n '1p')
[ -n "$INITRD_PATH" ] || die "initrd.gz not found"
INITRD_REL=$(printf '%s\n' "$INITRD_PATH" | sed "s#^$ISO_ROOT/##")
gzip -t "$INITRD_PATH" || die "source initrd gzip invalid"
(cd "$INITRD_TREE" && gzip -dc "$INITRD_PATH" | cpio --extract --make-directories --no-absolute-filenames --quiet) || die "initramfs extract failed"
[ -e "$INITRD_TREE/init" ] || die "initramfs /init missing"
cp "$ROOT/installer/custom-tui.sh" "$INITRD_TREE/custom-tui.sh"
cp "$ROOT/installer/custom-hardware-detect.sh" "$INITRD_TREE/custom-hardware-detect.sh"
cp "$ROOT/installer/custom-install-target.sh" "$INITRD_TREE/custom-install-target.sh"
cp "$UPM_BINARY" "$INITRD_TREE/upm"
printf '%s\n' "$UPM_COMMIT" > "$INITRD_TREE/upm-version"
chmod 0755 "$INITRD_TREE/custom-tui.sh" "$INITRD_TREE/custom-hardware-detect.sh" "$INITRD_TREE/custom-install-target.sh" "$INITRD_TREE/upm"
mv "$INITRD_TREE/init" "$INITRD_TREE/init.custom-original"
cat > "$INITRD_TREE/init" <<'WRAPPER'
#!/bin/sh
/bin/sh /custom-hardware-detect.sh || true
/bin/sh /custom-tui.sh || true
exec /init.custom-original "$@"
WRAPPER
chmod 0755 "$INITRD_TREE/init"
(cd "$INITRD_TREE" && find . -print0 | cpio --null --create --format=newc --quiet --owner=0:0) | gzip -9n > "$PATCHED_INITRD"
gzip -t "$PATCHED_INITRD" || die "patched initrd invalid"
cp "$PATCHED_INITRD" "$INITRD_PATH"

mkdir -p "$ISO_ROOT/preseed"
cat > "$ISO_ROOT/preseed/custom.cfg" <<'PRESEED'
d-i debconf/priority string critical
d-i auto-install/enable boolean true
d-i pkgsel/upgrade select none
d-i pkgsel/include string ca-certificates sudo
d-i apt-setup/non-free-firmware boolean true
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i preseed/late_command string /bin/sh /var/lib/custom/install-target.sh
PRESEED

find "$ISO_ROOT" -type f \( -name '*.cfg' -o -name '*.conf' \) -print |
while IFS= read -r cfg; do
    case "$cfg" in
        */grub.cfg|*/txt.cfg|*/menu.cfg|*/isolinux.cfg|*/syslinux.cfg)
            if grep -q -- '---' "$cfg" && ! grep -q 'preseed/file=/preseed/custom.cfg' "$cfg"; then
                sed 's#---#--- preseed/file=/preseed/custom.cfg#g' "$cfg" > "$cfg.tmp"
                mv "$cfg.tmp" "$cfg"
            fi
            ;;
    esac
done
BIOS_CFG=$(find "$ISO_ROOT" -type f \( -name '*.cfg' -o -name '*.conf' \) -exec grep -l 'menu label.*Install\|label install\|default install' {} \; | sed -n '1p')
UEFI_CFG=$(find "$ISO_ROOT" -type f -path '*/grub/grub.cfg' -print | sed -n '1p')
[ -n "$BIOS_CFG" ] || die "could not discover Debian BIOS Syslinux menu"
[ -n "$UEFI_CFG" ] || die "could not discover Debian UEFI GRUB menu"
grep -q 'preseed/file=/preseed/custom.cfg' "$BIOS_CFG" || die "preseed argument absent from BIOS menu"
grep -q 'preseed/file=/preseed/custom.cfg' "$UEFI_CFG" || die "preseed argument absent from UEFI menu"
[ -s "$ISO_ROOT/preseed/custom.cfg" ] || die "preseed payload missing"
set --
for candidate in "$ISO_ROOT/$INITRD_REL" "$ISO_ROOT/preseed/custom.cfg" "$BIOS_CFG" "$UEFI_CFG"; do
    [ ! -f "$candidate" ] || {
        relative=$(printf '%s\n' "$candidate" | sed "s#^$ISO_ROOT/##")
        set -- "$@" -map "$candidate" "/$relative"
    }
done
xorriso -indev "$SOURCE_ISO" -outdev "$OUTPUT" -boot_image any replay "$@" -commit >/dev/null 2>&1 || die "xorriso ISO rebuild failed"
[ -s "$OUTPUT" ] || die "ISO output empty"
BYTES=$(wc -c < "$OUTPUT" | tr -d ' ')
[ "$BYTES" -lt "$MAX_ISO_BYTES" ] || die "ISO exceeds 150 MiB size limit"
xorriso -indev "$OUTPUT" -toc >/dev/null 2>&1 || die "rebuilt ISO unreadable"
xorriso -indev "$OUTPUT" -report_el_torito plain 2>&1 | grep -qi 'El Torito' || die "El Torito boot catalogue missing"
# Verify the files in the rebuilt ISO itself, not only the staging tree.
xorriso -osirrox on -indev "$OUTPUT" -extract / "$VERIFY_ROOT" >/dev/null 2>&1 || die "rebuilt ISO extraction failed"
[ -s "$VERIFY_ROOT/preseed/custom.cfg" ] || die "preseed payload absent from rebuilt ISO"
VERIFY_BIOS=$(find "$VERIFY_ROOT" -type f \( -name '*.cfg' -o -name '*.conf' \) -exec grep -l 'menu label.*Install\|label install\|default install' {} \; | sed -n '1p')
VERIFY_UEFI=$(find "$VERIFY_ROOT" -type f -path '*/grub/grub.cfg' -print | sed -n '1p')
[ -n "$VERIFY_BIOS" ] && grep -q 'preseed/file=/preseed/custom.cfg' "$VERIFY_BIOS" || die "rebuilt BIOS menu missing CUSTOM preseed argument"
[ -n "$VERIFY_UEFI" ] && grep -q 'preseed/file=/preseed/custom.cfg' "$VERIFY_UEFI" || die "rebuilt UEFI menu missing CUSTOM preseed argument"
printf '%s\n' "$BYTES" > "$DIST/custom-os-$ARCH.iso.bytes"
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
printf 'CUSTOM ISO build passed; size %s bytes. UPM commit %s.\n' "$BYTES" "$UPM_COMMIT"

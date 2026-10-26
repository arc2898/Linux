#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORK=${CUSTOM_BUILD_DIR:-"$ROOT/.build"}
DIST="$ROOT/dist"
ARCH=${ARCH:-amd64}
DEBIAN_SUITE=${DEBIAN_SUITE:-stable}
BASE_URL="https://deb.debian.org/debian/dists/$DEBIAN_SUITE/main/installer-$ARCH/current/images/netboot"
SOURCE_ISO="$WORK/debian-mini.iso"
ISO_ROOT="$WORK/iso-root"
INITRD_TREE="$WORK/initrd-tree"
PATCHED_INITRD="$WORK/initrd-patched.gz"
OUTPUT="$DIST/custom-os-$ARCH.iso"

die() { printf 'CUSTOM ISO build error: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

for cmd in curl xorriso gzip cpio find sed awk grep mktemp; do need "$cmd"; done
[ "$ARCH" = amd64 ] || die "this ISO prototype currently supports amd64 only"
[ -f "$ROOT/installer/custom-tui.sh" ] || die "missing installer/custom-tui.sh"

mkdir -p "$WORK" "$DIST"
rm -rf "$ISO_ROOT" "$INITRD_TREE" "$PATCHED_INITRD"
mkdir -p "$ISO_ROOT" "$INITRD_TREE"

printf 'Downloading official Debian %s %s mini ISO...\n' "$DEBIAN_SUITE" "$ARCH"
curl --fail --location --retry 4 --retry-delay 2 --connect-timeout 20 \
    --output "$SOURCE_ISO" "$BASE_URL/mini.iso" || die "download failed: $BASE_URL/mini.iso"

printf 'Inspecting source image...\n'
xorriso -indev "$SOURCE_ISO" -toc >/dev/null 2>&1 || die "downloaded file is not a readable ISO"
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$ISO_ROOT" >/dev/null 2>&1 || die "could not extract source ISO"

INITRD_PATH=$(find "$ISO_ROOT" -type f -name initrd.gz -print | head -n 1)
[ -n "$INITRD_PATH" ] || die "could not locate initrd.gz in Debian mini ISO"
INITRD_REL=${INITRD_PATH#"$ISO_ROOT"/}
[ -f "$INITRD_PATH" ] || die "initrd is missing"

printf 'Patching initramfs at /%s...\n' "$INITRD_REL"
gzip -t "$INITRD_PATH" || die "initrd gzip integrity check failed"
(
    cd "$INITRD_TREE"
    gzip -dc "$INITRD_PATH" | cpio --extract --make-directories --no-absolute-filenames --quiet
) || die "could not unpack Debian Installer initramfs"

[ -e "$INITRD_TREE/init" ] || die "initramfs has no /init entry point"
[ -x "$INITRD_TREE/bin/sh" ] || die "initramfs has no /bin/sh"
cp "$ROOT/installer/custom-tui.sh" "$INITRD_TREE/custom-tui.sh"
chmod 0755 "$INITRD_TREE/custom-tui.sh"
if [ -e "$INITRD_TREE/init.custom-original" ]; then
    die "unexpected init.custom-original already exists"
fi
mv "$INITRD_TREE/init" "$INITRD_TREE/init.custom-original"
cat > "$INITRD_TREE/init" <<'WRAPPER'
#!/bin/sh
# CUSTOM preflight TUI: return to the unmodified Debian Installer init.
if [ -x /bin/sh ] && [ -f /custom-tui.sh ]; then
    /bin/sh /custom-tui.sh || true
fi
exec /init.custom-original "$@"
WRAPPER
chmod 0755 "$INITRD_TREE/init"

# Repack as a deterministic newc initramfs. Preserve existing Unix modes and links.
(
    cd "$INITRD_TREE"
    find . -print0 | cpio --null --create --format=newc --quiet --owner=0:0
) | gzip -9n > "$PATCHED_INITRD"
gzip -t "$PATCHED_INITRD" || die "patched initrd is corrupt"
cp "$PATCHED_INITRD" "$INITRD_PATH"

# Add the preseed reference to installer boot entries. The TUI writes this file
# before the original Debian Installer init proceeds.
find "$ISO_ROOT" -type f \( -name '*.cfg' -o -name '*.conf' \) -print0 |
while IFS= read -r -d '' cfg; do
    case "$cfg" in
        */grub.cfg|*/txt.cfg|*/menu.cfg|*/isolinux.cfg|*/syslinux.cfg)
            if grep -q '---' "$cfg"; then
                sed 's/---/--- preseed\/file=\/custom-preseed.cfg/g' "$cfg" > "$cfg.tmp"
                mv "$cfg.tmp" "$cfg"
            fi
            ;;
    esac
done

# Brand visible entries without replacing the vendor boot mechanics.
for cfg in "$ISO_ROOT/boot/grub/grub.cfg" "$ISO_ROOT/isolinux/txt.cfg" "$ISO_ROOT/isolinux/menu.cfg"; do
    if [ -f "$cfg" ]; then
        sed 's/Debian GNU\/Linux Installer/CUSTOM OS Network Installer/g; s/Debian Installer menu/CUSTOM OS Installer/g' "$cfg" > "$cfg.tmp"
        mv "$cfg.tmp" "$cfg"
    fi
done

printf 'Rebuilding ISO while replaying original BIOS/UEFI boot metadata...\n'
# Replay the source ISO's El Torito/isohybrid boot settings and replace only modified files.
set --
for path in "$INITRD_REL" boot/grub/grub.cfg isolinux/txt.cfg isolinux/menu.cfg isolinux/isolinux.cfg isolinux/syslinux.cfg; do
    candidate="$ISO_ROOT/$path"
    if [ -f "$candidate" ]; then
        set -- "$@" -map "$candidate" "/$path"
    fi
done
xorriso -indev "$SOURCE_ISO" -outdev "$OUTPUT" -boot_image any replay "$@" -commit >/dev/null 2>&1 || die "xorriso failed to replay boot metadata and write ISO"

[ -s "$OUTPUT" ] || die "ISO output is empty"
BYTES=$(wc -c < "$OUTPUT" | tr -d ' ')
MIB=$(( (BYTES + 1048575) / 1048576 ))
printf 'ISO path: %s\nSize: %s bytes (%s MiB)\n' "$OUTPUT" "$BYTES" "$MIB"
if [ "$BYTES" -ge 104857600 ]; then
    die "ISO is not under 100 MB (100 MiB threshold is 104857600 bytes)"
fi
xorriso -indev "$OUTPUT" -toc >/dev/null 2>&1 || die "built ISO failed xorriso validation"
xorriso -indev "$OUTPUT" -report_el_torito as_mkisofs 2>&1 | grep -q 'eltorito' || die "ISO does not report El Torito boot metadata"
printf '%s\n' "$BYTES" > "$DIST/custom-os-$ARCH.iso.bytes"
printf 'CUSTOM ISO build passed the size and boot-metadata checks.\n'

#!/bin/sh
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
WORK=${CUSTOM_BUILD_DIR:-"$ROOT/.build"}
DIST="$ROOT/dist"
ARCH=${ARCH:-amd64}
SUITE=${DEBIAN_SUITE:-stable}
BASE_URL="https://deb.debian.org/debian/dists/$SUITE/main/installer-$ARCH/current/images/netboot"
SOURCE_ISO="$WORK/debian-mini.iso"
ISO_ROOT="$WORK/iso-root"
INITRD_TREE="$WORK/initrd-tree"
PATCHED_INITRD="$WORK/initrd-patched.gz"
OUTPUT="$DIST/custom-os-$ARCH.iso"

die() { printf 'CUSTOM ISO build error: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command missing: $1"; }
for cmd in curl xorriso gzip cpio find sed grep wc tr sha256sum; do need "$cmd"; done
[ "$ARCH" = amd64 ] || die "only amd64 is currently supported"
[ -f "$ROOT/installer/custom-tui.sh" ] || die "missing CUSTOM TUI"
mkdir -p "$WORK" "$DIST"
rm -rf "$ISO_ROOT" "$INITRD_TREE" "$PATCHED_INITRD"
mkdir -p "$ISO_ROOT" "$INITRD_TREE"
curl --fail --location --retry 4 --retry-delay 2 --connect-timeout 20 --output "$SOURCE_ISO" "$BASE_URL/mini.iso" || die "Debian mini ISO download failed"
xorriso -indev "$SOURCE_ISO" -toc >/dev/null 2>&1 || die "source ISO invalid"
xorriso -osirrox on -indev "$SOURCE_ISO" -extract / "$ISO_ROOT" >/dev/null 2>&1 || die "ISO extraction failed"
INITRD_PATH=$(find "$ISO_ROOT" -type f -name initrd.gz -print | head -n 1)
[ -n "$INITRD_PATH" ] || die "initrd.gz not found"
INITRD_REL=${INITRD_PATH#"$ISO_ROOT"/}
gzip -t "$INITRD_PATH" || die "source initrd gzip invalid"
(cd "$INITRD_TREE" && gzip -dc "$INITRD_PATH" | cpio --extract --make-directories --no-absolute-filenames --quiet) || die "initramfs extract failed"
[ -e "$INITRD_TREE/init" ] || die "initramfs /init missing"
cp "$ROOT/installer/custom-tui.sh" "$INITRD_TREE/custom-tui.sh"
chmod 0755 "$INITRD_TREE/custom-tui.sh"
mv "$INITRD_TREE/init" "$INITRD_TREE/init.custom-original"
cat > "$INITRD_TREE/init" <<'WRAPPER'
#!/bin/sh
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
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i preseed/late_command string mkdir -p /target/etc/custom; cp /var/lib/custom/profile.env /target/etc/custom/profile.env; cp /var/lib/custom/packages.txt /target/etc/custom/packages.txt; in-target /bin/sh -c 'apt-get update && xargs -r apt-get install -y < /etc/custom/packages.txt'; in-target /bin/sh -c 'case "$(grep "^CUSTOM_LOGIN_SHELL=" /etc/custom/profile.env | cut -d= -f2)" in zsh) chsh -s /bin/zsh root;; fish) chsh -s /usr/bin/fish root;; esac'
PRESEED

# Patch all config files and explicitly assert both primary menu files.
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
for cfg in "$ISO_ROOT/isolinux/txt.cfg" "$ISO_ROOT/boot/grub/grub.cfg"; do
 [ -f "$cfg" ] || die "missing boot menu $cfg"
 grep -q 'preseed/file=/preseed/custom.cfg' "$cfg" || die "preseed argument absent from $cfg"
done
[ -s "$ISO_ROOT/preseed/custom.cfg" ] || die "preseed payload missing"
set --
for path in "$INITRD_REL" preseed/custom.cfg boot/grub/grub.cfg isolinux/txt.cfg isolinux/menu.cfg isolinux/isolinux.cfg isolinux/syslinux.cfg; do
 candidate="$ISO_ROOT/$path"
 [ ! -f "$candidate" ] || set -- "$@" -map "$candidate" "/$path"
done
xorriso -indev "$SOURCE_ISO" -outdev "$OUTPUT" -boot_image any replay "$@" -commit >/dev/null 2>&1 || die "xorriso ISO rebuild failed"
[ -s "$OUTPUT" ] || die "ISO output empty"
BYTES=$(wc -c < "$OUTPUT" | tr -d ' ')
[ "$BYTES" -lt 104857600 ] || die "ISO exceeds 100 MiB"
xorriso -indev "$OUTPUT" -toc >/dev/null 2>&1 || die "rebuilt ISO unreadable"
xorriso -indev "$OUTPUT" -report_el_torito plain 2>&1 | grep -qi 'El Torito' || die "El Torito boot catalogue missing"
printf '%s\n' "$BYTES" > "$DIST/custom-os-$ARCH.iso.bytes"
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
printf 'CUSTOM ISO build passed; size %s bytes.\n' "$BYTES"

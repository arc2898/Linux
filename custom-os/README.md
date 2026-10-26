# CUSTOM OS — minimal network installer

CUSTOM is a system builder and installer, not a fixed desktop distribution. This directory is an independent implementation; the existing repository contents and the earlier `CUSTOM/` prototype are left untouched.

## Goal

Build a Debian-based, text-mode network installer ISO targeting **under 100 MB**. The ISO downloads selected system packages from Debian during installation instead of bundling a complete operating system.

## Current implementation

- Uses Debian's official stable amd64 `mini.iso` as a tested boot foundation.
- Patches its initramfs to show a CUSTOM TUI before handing control back to Debian Installer.
- The TUI selects desktop environment, display manager, window manager, shell, package names, icon theme package, and records an optional GitHub repository URL.
- Generates a Debian Installer preseed file to request selected Debian packages and persists a CUSTOM profile on the installed system.
- Does not execute commands from GitHub repositories. A URL is recorded as metadata only.
- The bootloader used for this first iteration is Debian Installer's GRUB path; alternatives are not yet wired into the installation procedure.

## Build locally

On Debian/Ubuntu, install `curl xorriso gzip cpio file python3 shellcheck` and run the build as root (initramfs extraction preserves device entries):

```sh
sudo sudo sh custom-os/scripts/build-iso.sh
```

The script downloads the official Debian stable amd64 netboot mini ISO, injects the TUI and preseed hook, preserves the original boot catalog, and writes `dist/custom-os-amd64.iso`. Override `DEBIAN_SUITE` or `ARCH` only if the matching official Debian installer path exists.

## Verify

```sh
sh custom-os/tests/test-installer.sh
sh custom-os/scripts/build-iso.sh
```

The GitHub Actions workflow runs tests, builds the ISO, checks its size and El Torito boot metadata, and uploads it as an artifact. The artifact is only considered complete if the workflow passes.

## Current limits

- First ISO targets amd64; other architectures need separate boot-media testing.
- Network connectivity is required to install the target system.
- Package selection is passed to Debian Installer through preseed; all combinations still need end-to-end VM tests.
- GitHub projects are only recorded. Safe component installation requires explicit declarative recipes, pinned revisions, compatibility checks, and isolated execution.
- The ISO size target is checked by CI; it must not be assumed until a successful run reports the actual size.

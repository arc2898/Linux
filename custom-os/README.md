# CUSTOM OS — network installer

CUSTOM is a system builder, not a fixed distribution.

## Boot choice

The current amd64 network installer uses Debian's upstream boot stack: **ISOLINUX/Syslinux for legacy BIOS and GRUB for UEFI**. It keeps those vendor boot mechanisms intact while patching both kernel command lines. GRUB is also the selected installed-system bootloader for this Debian prototype.

## Installation and packages

The ISO is a network installer. It boots into the CUSTOM TUI, records the user's package selections in the installer initramfs, and then hands control to Debian Installer. A static preseed file is included in the ISO and requested by both BIOS and UEFI menu entries. Debian Installer's target phase is intended to install the requested packages with APT; package actions must run against the target root, not the RAM-based installer.

## Universal Package Manager

The [Universal Package Manager](https://github.com/arc2898/Universal-Package-Manager) is a Go CLI which already has native adapters for:
- Debian/Ubuntu: APT
- Arch: Pacman
- Fedora: DNF
- openSUSE/SUSE: Zypper
- Void: XBPS
- Gentoo: Portage/emerge

UPM currently executes commands against the running host; it does not expose a target-root or offline-root install API. Therefore this installer must not blindly call `upm install` from its initramfs. The integration plan is to extend UPM with an explicit target-root backend (or run it in the target chroot) and compile it into the installer. For this first Debian image, APT in the target phase is correct.

The first ISO still supports Debian stable amd64 only. Other bases need their own bootstrap and installation adapters; UPM supplies package operations, not base-system installation.

## Build and checks

Install `curl xorriso gzip cpio coreutils`, then:
```sh
sudo sh custom-os/scripts/build-iso.sh
sh custom-os/tests/test-installer.sh
```

The build checks ISO readability, El Torito boot metadata, BIOS and UEFI menu preseed arguments, and the under-100-MiB target. A full target-disk install remains a separate VM test.


## Universal Package Manager integration status

The linked Universal Package Manager (UPM) is written in Go and currently exposes a CLI that operates on the running host. It has package adapters for APT, Pacman, DNF, Zypper, XBPS and Portage. It does not yet provide a target-root/offline-root installation API. For this Debian installer prototype the selected package list is installed into the Debian target by APT during Debian Installer late_command; calling UPM inside the initramfs would target the installer environment, not the target installation. Full UPM integration and non-Debian base installers remain roadmap work.

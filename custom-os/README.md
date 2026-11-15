# CUSTOM OS — selective network installer

CUSTOM is a customizable Linux system builder, not a fixed distribution. The current image is a Debian stable amd64 installer prototype. Do not treat the other distribution profiles as installable yet.

## What is integrated

- **Hardware inventory:** scans PCI devices through Linux sysfs before the TUI. The report includes PCI vendor/device/class IDs and the currently bound kernel driver.
- **Selective firmware:** known Wi-Fi and GPU vendor/class mappings add only their Debian firmware packages; Intel/AMD CPU detection adds the matching microcode. Unknown devices are reported but do not trigger guessed packages.
- **Kernel drivers:** normal in-tree drivers are supplied by the Debian kernel and loaded through kernel hardware probing. CUSTOM does not layer duplicate vendor drivers or DKMS modules on top automatically.
- **Curated TUI:** desktop environment, display manager, window manager, login shell, icon theme, and package categories (terminal, internet, office/creative, development, system utilities), with validated optional package names.
- **Custom identity:** stores a validated system name and profile under /etc/custom, applies the hostname, and records the selected configuration.
- **UPM package install:** compiles a pinned Linux amd64 UPM binary into the ISO. Debian Installer late_command copies it to the target and runs its APT adapter inside the target chroot; package actions do not run in the installer RAM environment.
- **Boot:** retains upstream Debian ISOLINUX/Syslinux for legacy BIOS and GRUB for UEFI. Debian Installer selects and installs GRUB for the target system.

## Hardware driver policy

The detector uses sysfs and does not depend on lspci being present in the installer initramfs. It uses conservative mappings for Intel, Realtek, Broadcom, Atheros/Qualcomm and MediaTek wireless firmware, plus Intel, AMD and NVIDIA graphics firmware. It records kernel driver bindings for all detected PCI devices. It does not install proprietary NVIDIA modules, Broadcom STA, DKMS or other third-party driver stacks automatically; these require explicit compatibility and Secure Boot checks. Firmware selection is a recommendation from vendor/class IDs, not a successful device-function test.

Debian stable must have its non-free-firmware component enabled for firmware and microcode packages. The ISO's preseed enables that component. The target package operation is best-effort and logs status under /var/log/custom-install.log and /etc/custom/install-status.

## Universal Package Manager

UPM source: https://github.com/arc2898/Universal-Package-Manager

CUSTOM builds UPM from a pinned commit and runs it inside Debian Installer's target chroot. UPM therefore reads the target's os-release and uses the target's native manager. The UPM chroot-support work is in a separate draft PR: https://github.com/arc2898/Universal-Package-Manager/pull/1. The image pins commit 37d22bcef1b0f3e9da0ec215cdc2485fe339755f; it is not yet merged into UPM main.

## Base-system coverage

Debian stable amd64 is the only active installation backend. The prerequisite catalogue for Debian, Arch, Fedora, openSUSE, Void and Gentoo is in profiles/base-prerequisites.md. Arch requires pacstrap, Fedora a DNF/Anaconda deployment backend, openSUSE a rootfs bootstrap, Void an XBPS rootfs and Gentoo a Stage3 + Portage process. UPM cannot replace those base-system bootstrappers.

## Build and tests

The GitHub Actions workflow tests shell syntax, runs a synthetic hardware-detection fixture, tests UPM, compiles UPM statically for Linux amd64, builds the ISO, checks BIOS/UEFI menu payloads in the rebuilt ISO, and smoke-tests the TUI by booting its kernel/initrd directly in QEMU.

The image size ceiling is 150 MiB to leave room for bundled tooling and selected support files. The ISO build emits a byte count and SHA256 checksum.

**Not yet proven:** actual firmware boot of the ISO on BIOS and UEFI VMs, a complete target-disk installation, package installation outcomes across desktop choices, real hardware coverage, partition editing, dual boot, rollback and recovery. Do not install on a production disk yet.

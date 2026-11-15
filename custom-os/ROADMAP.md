# CUSTOM OS roadmap

## Implemented in current Debian prototype
- [x] Curated TUI choices and categorized package selections
- [x] Validate optional package names and GitHub owner/repository metadata (record-only)
- [x] PCI inventory using sysfs and active kernel-driver reporting
- [x] Mount procfs/sysfs before early hardware detection
- [x] Stage only detected Wi-Fi firmware before installer network setup
- [x] Conservative firmware and CPU-microcode package selection
- [x] UPM compiled into image and invoked inside Debian target chroot
- [x] Apply custom hostname and preserve profile/report/install logs
- [x] Keep Debian upstream BIOS ISOLINUX/Syslinux and UEFI GRUB boot paths
- [x] Inspect boot-menu payloads in the rebuilt ISO
- [x] Increase ISO size ceiling to 250 MiB for firmware payloads

## Debian install hardening still required
- [ ] Boot the actual ISO with SeaBIOS and OVMF/UEFI in QEMU
- [ ] Complete target installs to disposable BIOS and UEFI disks
- [ ] Verify all package selections, desktop tasks, display managers and user shell
- [ ] Add hardware test matrix for Intel/AMD/NVIDIA and wireless adapters
- [ ] Verify firmware package availability against the exact stable point release
- [ ] Add install transaction preview, disk selection and destructive-action guardrails
- [ ] Test failure recovery, network loss, mirror fallback and install logs

## Multi-base roadmap
- [x] Prepare prerequisite catalogue for Debian, Arch, Fedora, openSUSE, Void and Gentoo
- [ ] Debian bootstrap / debootstrap backend independent of Debian Installer
- [ ] Arch pacstrap backend and UPM Pacman validation
- [ ] Fedora target bootstrap / DNF integration
- [ ] openSUSE rootfs bootstrap / Zypper integration
- [ ] Void rootfs bootstrap / XBPS integration
- [ ] Gentoo Stage3 / Portage integration and profile selection
- [ ] Per-base package-category mapping and CI VM installation matrix

## Partitioning and multi-boot
- [ ] Disk/firmware inventory and clear target-disk selection
- [ ] Manual partition editor and dry-run transaction preview
- [ ] Guided install-alongside mode
- [ ] Safe EFI System Partition reuse
- [ ] GRUB os-prober and Windows/Linux menu validation
- [ ] End-to-end dual-boot tests on disposable VM disks

No destructive disk operations before an exact transaction preview and successful disposable-VM install tests.

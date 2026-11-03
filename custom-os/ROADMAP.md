# CUSTOM OS roadmap

## Boot and install
- [x] Keep Debian mini ISO's BIOS ISOLINUX and UEFI GRUB mechanisms
- [x] Patch both menu families to request the ISO-resident CUSTOM preseed
- [x] Build-time assertions for both menu arguments
- [ ] Boot actual ISO in QEMU BIOS and UEFI firmware
- [ ] Verify preseed and profile/package handoff end-to-end
- [ ] Complete installs to disposable BIOS and UEFI VM disks

## UPM and base systems
- [x] Inspect Universal Package Manager implementation and supported native adapters
- [ ] Extend UPM with target-root/chroot installation API
- [ ] Bundle a static UPM binary into initramfs/target installer
- [ ] Debian bootstrap and APT integration
- [ ] Arch bootstrap and Pacman integration
- [ ] Fedora bootstrap and DNF integration
- [ ] openSUSE bootstrap and Zypper integration
- [ ] Void bootstrap and XBPS integration
- [ ] Gentoo stage3/Portage integration

## Partitioning / multi-boot
- [ ] Disk and firmware inventory
- [ ] Manual partition editor and dry-run transaction view
- [ ] Guided install-alongside mode
- [ ] Safe EFI System Partition reuse
- [ ] GRUB os-prober and Windows/Linux menu validation
- [ ] End-to-end dual boot tests on disposable VM disks

No destructive disk operations before the installer can show an exact transaction preview and pass VM tests.

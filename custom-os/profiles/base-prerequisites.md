# CUSTOM base-system prerequisites (staging catalogue)

**Important:** Debian stable amd64 is the only base currently connected to the install flow. The other five entries are prerequisite manifests for future bootstrap adapters; they do not enable those bases in the current ISO. UPM supplies package operations, not the bootstrapper or distro installer.

| Base | Bootstrap mechanism | Core prerequisites to stage | Native package manager |
|---|---|---|---|
| Debian | debootstrap or Debian Installer | debootstrap, linux-image-amd64, grub-pc (BIOS) / grub-efi-amd64 (UEFI), efibootmgr, dosfstools, e2fsprogs, parted, ca-certificates, sudo, network-manager, selected non-free-firmware packages | APT |
| Arch | pacstrap from arch-install-scripts | arch-install-scripts, archlinux-keyring, base, linux, linux-firmware, grub, efibootmgr, dosfstools, e2fsprogs, parted, networkmanager, sudo | Pacman |
| Fedora | Anaconda / DNF-based target deployment (future adapter) | dnf, kernel-core, systemd, grub2-pc (BIOS) / grub2-efi-x64 and shim-x64 (UEFI), efibootmgr, dosfstools, e2fsprogs, parted, NetworkManager, sudo, linux-firmware | DNF |
| openSUSE | zypper + supported rootfs/image bootstrap (future adapter) | zypper, patterns-base-minimal_base, kernel-default, systemd, grub2, grub2-x86_64-efi, shim, efibootmgr, dosfstools, e2fsprogs, parted, NetworkManager, sudo, kernel-firmware | Zypper |
| Void | xbps-install into a prepared rootfs (future adapter) | base-system, linux, linux-firmware, grub, efibootmgr, dosfstools, e2fsprogs, parted, NetworkManager, sudo | XBPS |
| Gentoo | Stage3 extraction + Portage configuration (future adapter) | Stage3 tarball (bootstrap artifact, not a package), sys-kernel/gentoo-kernel-bin or user-selected kernel, sys-firmware/linux-firmware, sys-boot/grub, sys-fs/dosfstools, sys-fs/e2fsprogs, sys-block/parted, net-misc/networkmanager, app-admin/sudo; choose OpenRC or systemd profile explicitly | Portage (emerge) |

## Selection policy

- Detect firmware needs from PCI class/vendor IDs; only add a package when an explicit mapping exists.
- Keep in-kernel drivers supplied by the selected distro kernel. Do not install duplicate vendor drivers or DKMS modules automatically.
- Do not guess a driver for unknown hardware. Show it in the hardware report and continue with the distro kernel's normal probing.
- Keep BIOS and UEFI boot packages distinct. The active Debian ISO uses Debian Installer's existing ISOLINUX/Syslinux (BIOS) and GRUB (UEFI) boot media; its installed target uses GRUB.
- A future non-Debian backend must supply its own partitioner, bootstrap process, kernel, initramfs, firmware policy, bootloader install, network setup, and VM install tests before it can appear as an installable choice.

Package names and boot package splits can change between distro releases. Treat these entries as design manifests, not a guarantee that every item exists in every release or architecture. Resolve names against the exact target release before enabling a backend.

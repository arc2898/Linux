# CUSTOM OS roadmap

## First network installer
- [x] Independent project directory
- [x] Debian stable amd64 mini.iso build workflow
- [x] TUI wrapper before Debian Installer
- [x] Package/preseed profile selection for desktop, display manager, shell, window manager, icon package and extra packages
- [x] Optional GitHub URL recorded as metadata only
- [x] ISO size and El Torito metadata gates in CI
- [ ] Successful hosted run and artifact inspection
- [ ] End-to-end QEMU tests for BIOS and UEFI installation
- [ ] Test that the Debian Installer honors dynamically generated preseed values

## Component safety and portability
- [ ] Pinned GitHub recipe schema with checksum/commit and declared install method
- [ ] Compatibility metadata per base, architecture, init system, display server and package ecosystem
- [ ] Sandboxed build/validation of community recipes
- [ ] Additional bases beyond Debian
- [ ] Other bootloaders beyond GRUB, each with dedicated test coverage

A small network installer can stay below 100 MB by downloading the target packages during install. The ISO must still be tested on real and virtual hardware; static metadata checks are not a substitute for an end-to-end installation test.

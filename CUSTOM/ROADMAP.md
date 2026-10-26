# CUSTOM implementation roadmap

## Phase 0 — profile/TUI foundation
- [x] Debian-first profile defaults
- [x] TUI selection flow
- [x] Profile validation
- [x] Reviewable install plan
- [x] Public GitHub metadata inspection without executing remote code

## Phase 1 — bootable network-installer ISO
- [ ] Choose minimal boot stack and confirm BIOS/UEFI support matrix
- [ ] Build a minimal initramfs/runtime
- [ ] Include TUI runtime and network tools
- [ ] Support wired networking and Wi-Fi setup
- [ ] Build ISO and enforce size budget in CI (target <100 MB)
- [ ] Test BIOS and UEFI boot in QEMU

## Phase 2 — Debian installation adapter
- [ ] Detect architecture and firmware mode
- [ ] Resolve Debian mirror/release and package dependencies/download sizes
- [ ] Safely enumerate disks, require explicit target and confirmation
- [ ] Install Debian base via debootstrap
- [ ] Configure kernel, firmware, bootloader and selected packages
- [ ] Configure user, locale, timezone, hostname and network
- [ ] Add VM end-to-end and recovery tests

## Phase 3 — extensible components
- [ ] Declarative recipe schema with pinned tag/commit and checksums
- [ ] Sandboxed builds and artifact review
- [ ] Compatibility probes per base, architecture, display protocol and init system
- [ ] License and provenance reporting
- [ ] Add base-system adapters beyond Debian

## Design constraints
- Defaults are starting presets, not a fixed CUSTOM edition.
- The small ISO downloads selected packages at install time.
- Never run arbitrary GitHub README commands as root.
- Do not claim compatibility without a test or declared capability.
- Never partition or format until the user explicitly confirms the target disk.

# CUSTOM Linux

**CUSTOM is a configurable Linux system builder and text-mode network installer.** Its defaults are a starting profile, not a fixed edition.

The installer ISO is intentionally small: it boots into a terminal UI and downloads selected components during installation. The sub-100 MB ISO goal is a build target, not a guarantee until the boot image and initramfs are measured in CI.

## Status
This initial foundation provides a profile-driven TUI, validation, GitHub repository metadata inspection, and a reviewable install plan. It does **not yet perform disk installation or emit a tested bootable ISO**.

## Quick start
```sh
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
PYTHONPATH=. python -m custom
```
The standard-library TUI fallback works without Rich.

## Current flow
1. Choose base (Debian default), release, kernel policy, desktop, display manager, bootloader, icon theme, shell, and window manager.
2. Add packages and a GitHub repository metadata entry.
3. Validate the profile, then save a JSON profile and install plan.

Remote repositories are untrusted. CUSTOM does not blindly run README commands as root. A future recipe must be explicit, pinned, reviewed, and sandboxed before execution.

## Architecture
- Small network-installer ISO, with selected packages downloaded during installation.
- Debian adapter planned around debootstrap + apt.
- Extra bases require dedicated adapters; their package/boot semantics are not assumed to be identical.
- The ISO size target is <100 MB and must be verified by CI.

## Commands
```sh
PYTHONPATH=. python -m custom
PYTHONPATH=. python -m custom --validate
PYTHONPATH=. python -m custom --profile examples/debian-minimal.json --validate
PYTHONPATH=. python -m custom --plan plan.json
PYTHONPATH=. python -m custom --inspect-github OWNER/REPO
```
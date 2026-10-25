#!/bin/sh
# Best-effort Quickshell fallback: Nix profile then user-local source build.
set -eu
MODE=both
for arg in "$@"; do case "$arg" in --nix-only) MODE=nix;; --source-only) MODE=source;; --help) echo 'Usage: fallback-quickshell.sh [--nix-only|--source-only]'; exit 0;; *) echo "Unknown option: $arg" >&2; exit 2;; esac; done
if command -v qs >/dev/null 2>&1; then echo "Quickshell already found: $(command -v qs)"; exit 0; fi
if [ "$MODE" != source ] && command -v nix >/dev/null 2>&1; then
 echo '[FALLBACK] trying nix profile install nixpkgs#quickshell'
 if nix profile install nixpkgs#quickshell && command -v qs >/dev/null 2>&1; then echo '[OK] Quickshell installed via Nix'; exit 0; fi
 echo '[WARN] Nix did not make qs available'
fi
[ "$MODE" != nix ] || { echo 'Nix-only route failed.' >&2; exit 1; }
echo '[FALLBACK] checking source build prerequisites'
for tool in git cmake ninja pkg-config c++; do command -v "$tool" >/dev/null 2>&1 || { echo "Missing $tool. Install compiler, Qt6 development libraries, CMake, Ninja and pkg-config." >&2; exit 1; }; done
QT=$(pkg-config --modversion Qt6Core 2>/dev/null || echo missing)
echo "Qt6Core: $QT; consult upstream build requirements for exact Quickshell version."
SRC=\${XDG_DATA_HOME:-"$HOME/.local/share"}/src/quickshell
BUILD=\${XDG_CACHE_HOME:-"$HOME/.cache"}/everlumen/quickshell-build
mkdir -p "$(dirname "$SRC")" "$(dirname "$BUILD")" "$HOME/.local/bin"
if [ -d "$SRC/.git" ]; then git -C "$SRC" pull --ff-only; else git clone --depth 1 https://git.outfoxxed.me/quickshell/quickshell.git "$SRC"; fi
cmake -S "$SRC" -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build "$BUILD" --parallel
cmake --install "$BUILD"
command -v qs >/dev/null 2>&1 || { echo 'Build completed but qs is not on PATH; add ~/.local/bin to PATH.' >&2; exit 1; }
echo '[OK] Quickshell source-build fallback completed.'

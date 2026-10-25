#!/bin/sh
# Build the actual Universal Package Manager from its Go source repository.
set -eu
YES=0 INSTALL_GO=0
for arg in "$@"; do case "$arg" in --yes|-y) YES=1;; --install-go) INSTALL_GO=1;; --help) echo 'Usage: bootstrap-upm.sh [--yes] [--install-go]'; exit 0;; *) echo "Unknown option: $arg" >&2; exit 2;; esac; done
PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"; export PATH
if ! command -v go >/dev/null 2>&1; then
 [ "$INSTALL_GO" -eq 1 ] || { echo 'Go is required. Install it or explicitly pass --install-go.' >&2; exit 1; }
 [ -r /etc/os-release ] && . /etc/os-release || true
 if [ "$YES" -eq 0 ]; then printf 'Offer native package-manager installation of Go? [y/N] '; read answer || answer=; case "$answer" in y|Y|yes|YES) :;; *) echo Cancelled; exit 1;; esac; fi
 case "\${ID:-unknown} \${ID_LIKE:-}" in
  *debian*|*ubuntu*) sudo apt-get update && sudo apt-get install -y golang-go;;
  *fedora*|*rhel*) sudo dnf install -y golang;;
  *arch*) sudo pacman -Syu --needed --noconfirm go;;
  *opensuse*|*suse*) sudo zypper --non-interactive install go;;
  *alpine*) sudo apk add go;;
  *void*) sudo xbps-install -S go;;
  *) echo 'No safe automatic Go route. Install from https://go.dev/dl/.' >&2; exit 1;;
 esac
fi
SRC=\${XDG_DATA_HOME:-"$HOME/.local/share"}/src/Universal-Package-Manager
BIN=\${XDG_BIN_HOME:-"$HOME/.local/bin"}
mkdir -p "$(dirname "$SRC")" "$BIN"
if [ -d "$SRC/.git" ]; then git -C "$SRC" pull --ff-only; else git clone https://github.com/arc2898/Universal-Package-Manager.git "$SRC"; fi
cd "$SRC"
go mod download
go test ./...
go vet ./...
go build -trimpath -ldflags='-s -w' -o "$BIN/upm" .
chmod 0755 "$BIN/upm"
"$BIN/upm" -v
echo "[OK] built real UPM at $BIN/upm"

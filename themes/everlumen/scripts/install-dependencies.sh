#!/bin/sh
# Distro-aware install route: UPM first where safe, then native PM, then QS fallback.
set -u
PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"; export PATH
YES=0; EXTRAS=0; INSTALL_HYPRLAND=0; APT_UPDATED=0
for arg in "$@"; do case "$arg" in --yes|-y) YES=1;; --extras) EXTRAS=1;; --install-hyprland) INSTALL_HYPRLAND=1;; --help) echo 'Usage: install-dependencies.sh [--yes] [--extras] [--install-hyprland]'; exit 0;; *) echo "Unknown option: $arg" >&2; exit 2;; esac; done
[ -r /etc/os-release ] && . /etc/os-release || true
ID=${ID:-unknown}; ID_LIKE=${ID_LIKE:-}
case " $ID $ID_LIKE " in
 *" arch "*) PM=pacman; UPM_MANAGER=pacman; FAMILY=Arch;;
 *" debian "*|*" ubuntu "*) PM=apt; UPM_MANAGER=apt; FAMILY=Debian/Ubuntu;;
 *" fedora "*|*" rhel "*|*" centos "*) PM=dnf; UPM_MANAGER=dnf; FAMILY=Fedora/RHEL;;
 *" opensuse "*|*" suse "*) PM=zypper; UPM_MANAGER=zypper; FAMILY=openSUSE;;
 *" alpine "*) PM=apk; UPM_MANAGER=; FAMILY=Alpine;;
 *" void "*) PM=xbps; UPM_MANAGER=xbps; FAMILY=Void;;
 *" gentoo "*) PM=portage; UPM_MANAGER=portage; FAMILY=Gentoo;;
 *" nixos "*) PM=nix; UPM_MANAGER=; FAMILY=NixOS;;
 *" guix "*) PM=guix; UPM_MANAGER=; FAMILY=Guix;;
 *) PM=unknown; UPM_MANAGER=; FAMILY=unknown;;
esac
echo "EVERLUMEN dependency route: $ID / $FAMILY / $PM"
if [ "$YES" -eq 0 ]; then printf 'This may install packages. Hyprland itself is only attempted if --install-hyprland was provided. Continue? [y/N] '; read answer || answer=; case "$answer" in y|Y|yes|YES) :;; *) echo Cancelled; exit 0;; esac; fi
ROOT=${EVERLUMEN_SOURCE_DIR:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
UPM=$(command -v upm 2>/dev/null || true); [ -n "$UPM" ] || [ ! -x "$HOME/.local/bin/upm" ] || UPM="$HOME/.local/bin/upm"
runroot(){ if [ "$(id -u)" -eq 0 ]; then "$@"; elif command -v sudo >/dev/null 2>&1; then sudo "$@"; else echo 'Missing sudo/root; skipping system install.' >&2; return 1; fi; }
available(){
 pkg=$1
 case "$PM" in
  apt) apt-cache show "$pkg" >/dev/null 2>&1;;
  dnf) dnf -q list --available "$pkg" >/dev/null 2>&1;;
  pacman) pacman -Si "$pkg" >/dev/null 2>&1;;
  zypper) zypper -n info "$pkg" >/dev/null 2>&1;;
  apk) apk search -x "$pkg" 2>/dev/null | grep -q .;;
  xbps) xbps-query -Rs "^$pkg-[0-9]" >/dev/null 2>&1;;
  portage) emerge -s "$pkg" >/dev/null 2>&1;;
  nix) nix eval --raw "nixpkgs#$pkg.name" >/dev/null 2>&1;;
  guix) guix show "$pkg" >/dev/null 2>&1;;
  *) return 1;;
 esac
}
native_install(){
 pkg=$1
 case "$PM" in
  apt) if [ "$APT_UPDATED" -eq 0 ]; then runroot apt-get update || return 1; APT_UPDATED=1; fi; runroot apt-get install -y "$pkg";;
  dnf) runroot dnf install -y "$pkg";;
  pacman) runroot pacman -Syu --needed --noconfirm "$pkg";;
  zypper) runroot zypper --non-interactive install "$pkg";;
  apk) runroot apk add "$pkg";;
  xbps) runroot xbps-install -S "$pkg";;
  portage) runroot emerge --ask=n "$pkg";;
  nix) nix profile install "nixpkgs#$pkg";;
  guix) guix install "$pkg";;
  *) return 1;;
 esac
}
install_pkg(){
 pkg=$1
 echo "[SCAN] $pkg"
 # Arch's current UPM adapter uses pacman -S without a full upgrade; bypass it.
 if [ "$PM" != pacman ] && [ -n "$UPM" ] && [ -n "$UPM_MANAGER" ]; then
  echo "[UPM] trying $pkg through explicit $UPM_MANAGER adapter"
  if "$UPM" -b install "$UPM_MANAGER" "$pkg"; then return 0; fi
  echo '[WARN] UPM failed; attempting native package manager.'
 fi
 if ! available "$pkg"; then echo "[WARN] no confirmed $pkg candidate in $PM repositories"; return 1; fi
 native_install "$pkg" && { echo "[OK] $pkg installed via $PM"; return 0; }
 echo "[WARN] native install failed for $pkg"; return 1
}
if command -v Hyprland >/dev/null 2>&1; then echo '[OK] Hyprland installed'; elif [ "$INSTALL_HYPRLAND" -eq 1 ]; then install_pkg hyprland || echo '[WARN] Hyprland install attempt failed'; else echo '[INFO] Hyprland missing; explicit option required to install the compositor.'; fi
if command -v qs >/dev/null 2>&1; then echo '[OK] Quickshell installed'; else install_pkg quickshell || { echo '[INFO] Quickshell repository route failed; starting fallback.'; "$ROOT/scripts/fallback-quickshell.sh" || echo '[WARN] Quickshell fallback did not complete.'; }; fi
if [ "$EXTRAS" -eq 1 ]; then
 for pkg in hyprpaper hyprlock hypridle hyprpicker hyprsunset hyprpolkitagent xdg-desktop-portal-hyprland wl-clipboard grim slurp playerctl brightnessctl libnotify rofi; do
  if command -v "$pkg" >/dev/null 2>&1; then echo "[OK] $pkg already present"; else install_pkg "$pkg" || echo "[WARN] optional package $pkg left uninstalled"; fi
 done
fi
echo 'Done. Run everlumen-doctor for the post-install scan.'

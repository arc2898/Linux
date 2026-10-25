#!/bin/sh
set -u
PATH="$HOME/.local/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:$PATH"; export PATH
STRICT=0
[ "\${1:-}" = "--strict" ] && STRICT=1
RED='\033[38;2;255;83;120m'; GREEN='\033[38;2;198;255;59m'; CYAN='\033[38;2;59;247;238m'; DIM='\033[38;2;142;163;188m'; RESET='\033[0m'
ok=0; warn=0; fail=0
good(){ printf '%b[ OK ]%b %s\n' "$GREEN" "$RESET" "$*"; ok=$((ok+1)); }
warning(){ printf '%b[WARN]%b %s\n' "$DIM" "$RESET" "$*"; warn=$((warn+1)); }
bad(){ printf '%b[FAIL]%b %s\n' "$RED" "$RESET" "$*"; fail=$((fail+1)); }
[ -r /etc/os-release ] && . /etc/os-release || true
ID=\${ID:-unknown}; ID_LIKE=\${ID_LIKE:-}
printf '\n%bEVERLUMEN // NEUROGLASS DIAGNOSTIC%b\n' "$CYAN" "$RESET"
printf 'OS: %s / %s / version %s\n' "$ID" "$ID_LIKE" "\${VERSION_ID:-unknown}"
case " $ID $ID_LIKE " in *" arch "*) family=Arch;; *" debian "*|*" ubuntu "*) family=Debian/Ubuntu;; *" fedora "*|*" rhel "*) family=Fedora/RHEL;; *" suse "*) family=openSUSE;; *" alpine "*) family=Alpine;; *" void "*) family=Void;; *" gentoo "*) family=Gentoo;; *" nixos "*) family=NixOS;; *" guix "*) family=Guix;; *) family=unknown;; esac
printf 'Detected family: %s\n' "$family"
for tool in Hyprland hyprctl qs; do if command -v "$tool" >/dev/null 2>&1; then good "$tool => $(command -v "$tool")"; else bad "$tool not found"; fi; done
if [ -n "\${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then good 'Hyprland session signature present'; else warning 'Not running inside a live Hyprland session'; fi
if command -v hyprctl >/dev/null 2>&1; then hyprctl version 2>/dev/null | sed -n '1,2p' || warning 'hyprctl cannot contact compositor'; fi
for tool in upm kitty foot alacritty wezterm rofi fuzzel wofi hyprpaper hyprlock hypridle hyprpicker hyprsunset hyprpolkitagent xdg-desktop-portal-hyprland wl-copy wl-paste grim slurp notify-send playerctl wpctl brightnessctl nm-applet; do
 if command -v "$tool" >/dev/null 2>&1; then good "$tool available"; else warning "$tool missing (optional helper)"; fi
done
if command -v pkg-config >/dev/null 2>&1; then good 'pkg-config available for source-build checks'; else warning 'pkg-config missing; source-build fallback may need development packages'; fi
printf '\nSummary: %s OK / %s warnings / %s failures\n' "$ok" "$warn" "$fail"
[ "$STRICT" -eq 0 ] || [ "$fail" -eq 0 ]

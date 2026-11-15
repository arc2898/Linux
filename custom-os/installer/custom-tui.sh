#!/bin/sh
set -u
set -f
# shellcheck disable=SC2086,SC2154
exec </dev/console >/dev/console 2>&1 || exit 0
STATE_DIR=/var/lib/custom
PROFILE=/tmp/custom-profile.env
PACKAGE_FILE=/tmp/custom-packages
PACKAGES='ca-certificates sudo'
DESKTOP=none DISPLAY_MANAGER=none WINDOW_MANAGER=none LOGIN_SHELL=bash ICON_THEME=none GITHUB_REPO=
mkdir -p "$STATE_DIR"
valid_pkg() { case "$1" in ''|-*|*[!A-Za-z0-9+._-]*) return 1 ;; *) return 0 ;; esac; }
add_package() {
    if valid_pkg "$1"; then case " $PACKAGES " in *" $1 "*) ;; *) PACKAGES="$PACKAGES $1" ;; esac
    else printf 'Ignoring invalid package token: %s\n' "$1" >&2; fi
}
choose() {
    prompt=$1; default=$2; shift 2
    printf '\n%s\n' "$prompt" >&2
    for item in "$@"; do [ "$item" = "$default" ] && marker='*' || marker=' '; printf ' [%s] %s\n' "$marker" "$item" >&2; done
    printf '> ' >&2
    IFS= read -r answer || answer=
    [ -n "$answer" ] || answer=$default
    case " $* " in *" $answer "*) printf '%s' "$answer" ;; *) printf 'Invalid choice; using %s\n' "$default" >&2; printf '%s' "$default" ;; esac
}
choose_category() {
    title=$1; map=$2
    printf '\n%s\nEnter comma-separated numbers, or press Enter to skip.\nOptions: ' "$title"
    for entry in $map; do
        number=$(printf '%s' "$entry" | cut -d: -f1)
        package=$(printf '%s' "$entry" | cut -d: -f2-)
        printf '%s=%s  ' "$number" "$package"
    done
    printf '\n> '
    IFS= read -r selections || selections=
    normalized=$(printf '%s' "$selections" | tr ',' ' ')
    # shellcheck disable=SC2086
    for token in $normalized; do
        case "$token" in ''|*[!0-9]*) printf 'Ignoring invalid selection: %s\n' "$token" >&2 ;;
        *)
            matched=0
            for entry in $map; do
                number=$(printf '%s' "$entry" | cut -d: -f1)
                package=$(printf '%s' "$entry" | cut -d: -f2-)
                if [ "$token" = "$number" ]; then add_package "$package"; matched=1; fi
            done
            [ "$matched" -eq 1 ] || printf 'Unknown option: %s\n' "$token" >&2
            ;;
        esac
    done
}
printf '\nCUSTOM OS — selective installer\n'
printf 'Current install base: Debian stable (the only fully integrated base in this ISO).\n'
printf 'Other base profiles are being prepared, but are not selectable as working installers yet.\n'
printf 'Boot mode: '
if [ -d /sys/firmware/efi ]; then BOOT_MODE=uefi; printf 'UEFI\n'; else BOOT_MODE=bios; printf 'Legacy BIOS\n'; fi
printf 'Bootloader: GRUB (Debian Installer selects BIOS/UEFI target automatically).\n'
printf 'Kernel: Debian amd64 kernel (automatic, hardware-compatible default).\n'
printf '\nSystem name (letters, numbers, dot, dash; default custom): '
IFS= read -r CUSTOM_NAME || CUSTOM_NAME=custom
[ -n "$CUSTOM_NAME" ] || CUSTOM_NAME=custom
case "$CUSTOM_NAME" in ''|-*|*[!A-Za-z0-9.-]*|.*|*-) printf 'Invalid system name; using custom.\n' >&2; CUSTOM_NAME=custom ;; esac
name_length=$(printf '%s' "$CUSTOM_NAME" | wc -c | tr -d ' ')
[ "$name_length" -le 63 ] || CUSTOM_NAME=custom
DESKTOP=$(choose 'Desktop environment' none none xfce kde-plasma gnome mate cinnamon lxqt)
case "$DESKTOP" in
    xfce) add_package task-xfce-desktop ;; kde-plasma) add_package task-kde-desktop ;;
    gnome) add_package task-gnome-desktop ;; mate) add_package task-mate-desktop ;;
    cinnamon) add_package task-cinnamon-desktop ;; lxqt) add_package task-lxqt-desktop ;;
esac
case "$DESKTOP" in
    gnome) DISPLAY_MANAGER=$(choose 'Display manager (compatible with GNOME)' gdm3 none gdm3) ;;
    kde-plasma) DISPLAY_MANAGER=$(choose 'Display manager (compatible with KDE)' sddm none sddm) ;;
    xfce|mate|cinnamon|lxqt) DISPLAY_MANAGER=$(choose 'Display manager (compatible with selected desktop)' lightdm none lightdm) ;;
    *) DISPLAY_MANAGER=none; printf 'No display manager selected because no desktop environment is installed.\\n' ;;
esac
case "$DISPLAY_MANAGER" in lightdm|sddm|gdm3) add_package "$DISPLAY_MANAGER" ;; esac
WINDOW_MANAGER=$(choose 'Window manager (optional)' none none i3 openbox bspwm awesome sway)
case "$WINDOW_MANAGER" in
    i3) add_package i3-wm ;; openbox) add_package openbox ;; bspwm) add_package bspwm ;;
    awesome) add_package awesome ;; sway) add_package sway ;;
esac
LOGIN_SHELL=$(choose 'Login shell' bash bash zsh fish)
case "$LOGIN_SHELL" in zsh|fish) add_package "$LOGIN_SHELL" ;; esac
ICON_THEME=$(choose 'Icon theme' none none papirus breeze adwaita numix)
case "$ICON_THEME" in
    papirus) add_package papirus-icon-theme ;; breeze) add_package breeze-icon-theme ;;
    adwaita) add_package adwaita-icon-theme ;; numix) add_package numix-icon-theme ;;
esac
choose_category 'Essentials and terminal tools' '1:curl 2:wget 3:git 4:vim 5:nano 6:btop 7:fastfetch'
choose_category 'Internet and communication' '1:firefox-esr 2:chromium 3:thunderbird 4:transmission-gtk'
choose_category 'Office and creative' '1:libreoffice 2:vlc 3:gimp 4:inkscape 5:audacity 6:obs-studio'
choose_category 'Development' '1:build-essential 2:cmake 3:golang 4:rustc 5:cargo 6:python3-venv 7:nodejs 8:npm 9:default-jdk'
choose_category 'System utilities' '1:gparted 2:flatpak 3:timeshift 4:synaptic 5:ufw'
printf '\nExtra Debian package names (space-separated, optional): '
IFS= read -r EXTRA || EXTRA=
# shellcheck disable=SC2086
for package in $EXTRA; do add_package "$package"; done
printf '\nGitHub component (owner/repo only; recorded, NOT executed): '
IFS= read -r GITHUB_REPO || GITHUB_REPO=
case "$GITHUB_REPO" in
    '') ;;
    */*) case "$GITHUB_REPO" in *[!A-Za-z0-9._/-]*|/*|*/|*..*|*/*/*) GITHUB_REPO=; printf 'Invalid repository identifier ignored.\n' >&2 ;; esac ;;
    *) GITHUB_REPO=; printf 'Use owner/repo format; ignored.\n' >&2 ;;
esac
if [ -s "$STATE_DIR/hardware-packages.txt" ]; then
    while IFS= read -r package; do add_package "$package"; done < "$STATE_DIR/hardware-packages.txt"
fi
: > "$PACKAGE_FILE"
# shellcheck disable=SC2086
for package in $PACKAGES; do printf '%s\n' "$package" >> "$PACKAGE_FILE"; done
{
    printf 'CUSTOM_NAME=%s\n' "$CUSTOM_NAME"
    printf 'CUSTOM_BASE=debian\nCUSTOM_RELEASE=stable\n'
    printf 'CUSTOM_DESKTOP=%s\nCUSTOM_DISPLAY_MANAGER=%s\n' "$DESKTOP" "$DISPLAY_MANAGER"
    printf 'CUSTOM_WINDOW_MANAGER=%s\nCUSTOM_LOGIN_SHELL=%s\n' "$WINDOW_MANAGER" "$LOGIN_SHELL"
    printf 'CUSTOM_ICON_THEME=%s\nCUSTOM_GITHUB_COMPONENT=%s\n' "$ICON_THEME" "$GITHUB_REPO"
    printf 'CUSTOM_BOOT_MODE=%s\nCUSTOM_BOOTLOADER=grub\nCUSTOM_KERNEL=linux-image-amd64\n' "$BOOT_MODE"
    if [ -f "$STATE_DIR/upm-version" ]; then printf 'CUSTOM_UPM_VERSION=%s\n' "$(cat "$STATE_DIR/upm-version")"; fi
} > "$PROFILE"
cp "$PROFILE" "$STATE_DIR/profile.env"
cp "$PACKAGE_FILE" "$STATE_DIR/packages.txt"
[ ! -f /custom-install-target.sh ] || cp /custom-install-target.sh "$STATE_DIR/custom-install-target.sh"
[ ! -f /upm ] || cp /upm "$STATE_DIR/upm"
[ ! -f /upm-version ] || cp /upm-version "$STATE_DIR/upm-version"
printf '\nDetected hardware and active kernel drivers:\n'
[ ! -s "$STATE_DIR/hardware-report.txt" ] || cat "$STATE_DIR/hardware-report.txt"
printf '\nSelected target packages (%s):\n' "$(wc -l < "$PACKAGE_FILE" | tr -d ' ')"
cat "$PACKAGE_FILE"
printf '\nCUSTOM profile captured. Continuing to Debian Installer.\n'
exit 0

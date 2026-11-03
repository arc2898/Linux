#!/bin/sh
# Runs from Debian Installer initramfs before its original /init.
set -u
set -f
exec </dev/console >/dev/console 2>&1 || exit 0
PROFILE=/tmp/custom-profile.env
PACKAGE_FILE=/tmp/custom-packages
PACKAGES="ca-certificates sudo"
DESKTOP=none
DISPLAY_MANAGER=none
WINDOW_MANAGER=none
LOGIN_SHELL=bash
ICON_PACKAGE=default
GITHUB_URL=

choose() {
 prompt=$1; default=$2; shift 2
 printf '\n%s\n' "$prompt" >&2
 for item in "$@"; do
  [ "$item" = "$default" ] && marker='*' || marker=' '
  printf ' [%s] %s\n' "$marker" "$item" >&2
 done
 printf '> ' >&2
 IFS= read -r answer || answer=
 [ -n "$answer" ] || answer=$default
 case " $* " in *" $answer "*) printf '%s' "$answer";; *) printf 'Invalid choice; using %s\n' "$default" >&2; printf '%s' "$default";; esac
}
valid_pkg() { case "$1" in ''|-*|*[!A-Za-z0-9+._:-]*) return 1;; *) return 0;; esac; }
add_package() {
 if valid_pkg "$1"; then
  case " $PACKAGES " in *" $1 "*) ;; *) PACKAGES="$PACKAGES $1";; esac
 else printf 'Ignoring invalid package: %s\n' "$1"; fi
}
printf '\nCUSTOM OS — installer configuration\n'
printf 'Base: Debian stable | bootloader: GRUB\n'
DESKTOP=$(choose "Desktop environment" none none xfce kde-plasma gnome mate cinnamon lxqt)
case "$DESKTOP" in
 xfce) add_package task-xfce-desktop;;
 kde-plasma) add_package task-kde-desktop;;
 gnome) add_package task-gnome-desktop;;
 mate) add_package task-mate-desktop;;
 cinnamon) add_package task-cinnamon-desktop;;
 lxqt) add_package task-lxqt-desktop;;
esac
DEFAULT_DM=lightdm
[ "$DESKTOP" = kde-plasma ] && DEFAULT_DM=sddm
[ "$DESKTOP" = gnome ] && DEFAULT_DM=gdm3
DISPLAY_MANAGER=$(choose "Display manager" "$DEFAULT_DM" none lightdm sddm gdm3)
case "$DISPLAY_MANAGER" in lightdm|sddm|gdm3) add_package "$DISPLAY_MANAGER";; esac
WINDOW_MANAGER=$(choose "Additional window manager" none none i3 openbox bspwm awesome)
case "$WINDOW_MANAGER" in i3) add_package i3-wm;; openbox) add_package openbox;; bspwm) add_package bspwm;; awesome) add_package awesome;; esac
LOGIN_SHELL=$(choose "Login shell" bash bash zsh fish)
case "$LOGIN_SHELL" in zsh|fish) add_package "$LOGIN_SHELL";; esac
printf 'Icon theme package (default to skip): '
IFS= read -r ICON_PACKAGE || ICON_PACKAGE=default
[ -n "$ICON_PACKAGE" ] || ICON_PACKAGE=default
[ "$ICON_PACKAGE" = default ] || add_package "$ICON_PACKAGE"
printf 'Extra Debian package names (space separated): '
IFS= read -r EXTRA || EXTRA=
# shellcheck disable=SC2086
for package in $EXTRA; do add_package "$package"; done
printf 'Optional GitHub repository URL to record (not executed): '
IFS= read -r GITHUB_URL || GITHUB_URL=
case "$GITHUB_URL" in ''|https://github.com/*/*) ;; *) GITHUB_URL=; printf 'Invalid URL ignored.\n';; esac
cat > "$PROFILE" <<EOF
CUSTOM_NAME=custom
CUSTOM_BASE=debian
CUSTOM_RELEASE=stable
CUSTOM_DESKTOP=$DESKTOP
CUSTOM_DISPLAY_MANAGER=$DISPLAY_MANAGER
CUSTOM_WINDOW_MANAGER=$WINDOW_MANAGER
CUSTOM_LOGIN_SHELL=$LOGIN_SHELL
CUSTOM_ICON_PACKAGE=$ICON_PACKAGE
CUSTOM_GITHUB_COMPONENT_URL=$GITHUB_URL
CUSTOM_BOOTLOADER=grub
EOF
printf '%s\n' "$PACKAGES" | tr ' ' '\n' | sed '/^$/d' > "$PACKAGE_FILE"
printf '\nCUSTOM profile captured. Debian Installer will continue.\n'
exit 0

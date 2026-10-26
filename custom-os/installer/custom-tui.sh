#!/bin/sh
# Runs from the Debian Installer initramfs before its original /init.
# This is a selection UI only; it never installs packages or runs GitHub code.
set -u
set -f

exec </dev/console >/dev/console 2>&1 || exit 0

PROFILE=/custom-profile.env
PRESEED=/custom-preseed.cfg
PACKAGES="ca-certificates sudo"
DESKTOP=none
DISPLAY_MANAGER=none
WINDOW_MANAGER=none
LOGIN_SHELL=bash
ICON_PACKAGE=default
GITHUB_URL=""

choose() {
    prompt=$1
    default=$2
    shift 2
    printf '\n%s\n' "$prompt" >&2
    for item in "$@"; do
        if [ "$item" = "$default" ]; then
            printf '  * %s (default)\n' "$item" >&2
        else
            printf '    %s\n' "$item" >&2
        fi
    done
    printf '> ' >&2
    IFS= read -r answer || answer=""
    [ -n "$answer" ] || answer=$default
    case " $* " in
        *" $answer "*) printf '%s' "$answer" ;;
        *) printf 'Invalid choice; using %s\n' "$default" >&2; printf '%s' "$default" ;;
    esac
}

valid_pkg() {
    case "$1" in
        ""|-*|*[!a-zA-Z0-9+._:-]*) return 1 ;;
        *) return 0 ;;
    esac
}

add_package() {
    candidate=$1
    if valid_pkg "$candidate"; then
        case " $PACKAGES " in
            *" $candidate "*) ;;
            *) PACKAGES="$PACKAGES $candidate" ;;
        esac
    else
        printf 'Skipping invalid package name: %s\n' "$candidate"
    fi
}

printf '\n'
printf '============================================================\n'
printf '                  CUSTOM OS INSTALLER\n'
printf '       Choose components; Debian packages download online\n'
printf '============================================================\n'
printf 'Base system: Debian stable (the first supported base)\n'
printf 'Kernel: newest kernel supported by the selected Debian suite\n'
printf 'Bootloader: GRUB (the currently integrated installer path)\n'
printf '\nThis configuration step does not write to disk.\n'

DESKTOP=$(choose "Desktop environment" none none xfce kde-plasma gnome mate cinnamon lxqt)
case "$DESKTOP" in
    xfce) add_package task-xfce-desktop ;;
    kde-plasma) add_package task-kde-desktop ;;
    gnome) add_package task-gnome-desktop ;;
    mate) add_package task-mate-desktop ;;
    cinnamon) add_package task-cinnamon-desktop ;;
    lxqt) add_package task-lxqt-desktop ;;
esac

DEFAULT_DM=lightdm
[ "$DESKTOP" = kde-plasma ] && DEFAULT_DM=sddm
[ "$DESKTOP" = gnome ] && DEFAULT_DM=gdm3
DISPLAY_MANAGER=$(choose "Display manager" "$DEFAULT_DM" none lightdm sddm gdm3)
case "$DISPLAY_MANAGER" in
    lightdm|sddm|gdm3) add_package "$DISPLAY_MANAGER" ;;
esac

WINDOW_MANAGER=$(choose "Additional window manager" none none i3 openbox bspwm awesome)
case "$WINDOW_MANAGER" in
    i3) add_package i3-wm ;;
    openbox) add_package openbox ;;
    bspwm) add_package bspwm ;;
    awesome) add_package awesome ;;
esac

LOGIN_SHELL=$(choose "Login shell" bash bash zsh fish)
case "$LOGIN_SHELL" in
    zsh|fish) add_package "$LOGIN_SHELL" ;;
esac

printf '\nOptional icon theme package name (default keeps Debian defaults): '
IFS= read -r ICON_PACKAGE || ICON_PACKAGE=default
if [ -n "$ICON_PACKAGE" ] && [ "$ICON_PACKAGE" != default ]; then
    if valid_pkg "$ICON_PACKAGE"; then add_package "$ICON_PACKAGE"
    else printf 'Invalid package name; keeping default icon theme.\n'; ICON_PACKAGE=default
    fi
fi

printf 'Extra Debian package names (comma or space separated; blank for none): '
IFS= read -r EXTRA_RAW || EXTRA_RAW=""
EXTRA_RAW=$(printf '%s' "$EXTRA_RAW" | tr ',' ' ')
for package in $EXTRA_RAW; do
    add_package "$package"
done

printf 'Optional GitHub repository URL to record (not executed): '
IFS= read -r GITHUB_URL || GITHUB_URL=""
case "$GITHUB_URL" in
    "") ;;
    https://github.com/*/*)
        case "$GITHUB_URL" in
            *[!a-zA-Z0-9:/._-]*)
                printf 'URL contains unsupported characters; URL not recorded.\n'
                GITHUB_URL=""
                ;;
        esac
        ;;
    *)
        printf 'Only https://github.com/OWNER/REPO URLs are accepted; URL not recorded.\n'
        GITHUB_URL=""
        ;;
esac

cat > "$PROFILE" <<EOF
CUSTOM_NAME=custom
CUSTOM_BASE=debian
CUSTOM_RELEASE=stable
CUSTOM_KERNEL=debian-suite-latest-compatible
CUSTOM_DESKTOP=$DESKTOP
CUSTOM_DISPLAY_MANAGER=$DISPLAY_MANAGER
CUSTOM_WINDOW_MANAGER=$WINDOW_MANAGER
CUSTOM_LOGIN_SHELL=$LOGIN_SHELL
CUSTOM_ICON_PACKAGE=$ICON_PACKAGE
CUSTOM_PACKAGES=$PACKAGES
CUSTOM_GITHUB_COMPONENT_URL=$GITHUB_URL
CUSTOM_BOOTLOADER=grub
EOF

cat > "$PRESEED" <<EOF
d-i pkgsel/upgrade select none
d-i pkgsel/include string $PACKAGES
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i preseed/late_command string mkdir -p /target/etc/custom; cp /custom-profile.env /target/etc/custom/profile.env
EOF

printf '\nCUSTOM configuration prepared.\n'
printf 'Selected desktop: %s\n' "$DESKTOP"
printf 'Selected packages: %s\n' "$PACKAGES"
printf 'GitHub URL, if supplied, is stored as metadata only.\n'
printf 'Starting Debian Installer...\n'
sleep 2
exit 0

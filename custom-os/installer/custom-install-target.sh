#!/bin/sh
# Called by Debian Installer late_command; all package operations run in /target.
set -u
SOURCE=/var/lib/custom
TARGET=/target
LOG="$TARGET/var/log/custom-install.log"
mkdir -p "$TARGET/etc/custom" "$TARGET/var/log" "$TARGET/usr/local/bin"
exec >> "$LOG" 2>&1
for file in profile.env packages.txt hardware-report.txt hardware-packages.txt; do
    if [ -f "$SOURCE/$file" ]; then cp "$SOURCE/$file" "$TARGET/etc/custom/$file"; fi
done
system_name=$(sed -n 's/^CUSTOM_NAME=//p' "$SOURCE/profile.env" 2>/dev/null | sed -n '1p')
case "$system_name" in ''|*[!A-Za-z0-9.-]*|-*|*-) system_name=custom ;; esac
name_length=$(printf '%s' "$system_name" | wc -c | tr -d ' ')
[ "$name_length" -le 63 ] || system_name=custom
printf '%s\n' "$system_name" > "$TARGET/etc/hostname"
if [ -f "$TARGET/etc/hosts" ] && ! awk -v name="$system_name" '$2 == name { found=1 } END { exit !found }' "$TARGET/etc/hosts"; then
    printf '127.0.1.1\t%s\n' "$system_name" >> "$TARGET/etc/hosts"
fi
if [ ! -s "$SOURCE/upm" ]; then
    echo 'ERROR: bundled UPM binary missing; package selection cannot be installed through UPM.'
    echo 'UPM_MISSING' > "$TARGET/etc/custom/install-status"
    exit 0
fi
cp "$SOURCE/upm" "$TARGET/usr/local/bin/upm"
chmod 0755 "$TARGET/usr/local/bin/upm"
if ! command -v in-target >/dev/null 2>&1; then
    echo 'ERROR: Debian Installer in-target helper is unavailable.'
    echo 'IN_TARGET_MISSING' > "$TARGET/etc/custom/install-status"
    exit 0
fi
if in-target apt-get update; then echo 'APT metadata refreshed in target.'
else echo 'WARNING: apt-get update failed; continuing with configured package cache.'; fi
if [ -s "$SOURCE/packages.txt" ]; then
    package_csv=$(tr '\n' ',' < "$SOURCE/packages.txt" | sed 's/,$//')
    if [ -n "$package_csv" ]; then
        if in-target /usr/local/bin/upm -b install apt "$package_csv"; then
            echo 'UPM_PACKAGE_INSTALL=success' > "$TARGET/etc/custom/install-status"
        else
            echo 'UPM_PACKAGE_INSTALL=partial-or-failed' > "$TARGET/etc/custom/install-status"
            echo 'WARNING: one or more selected packages could not be installed; see this log.'
        fi
    fi
fi
login_shell=$(sed -n 's/^CUSTOM_LOGIN_SHELL=//p' "$SOURCE/profile.env" 2>/dev/null | sed -n '1p')
case "$login_shell" in bash) shell_path=/bin/bash ;; zsh) shell_path=/usr/bin/zsh ;; fish) shell_path=/usr/bin/fish ;; *) shell_path= ;; esac
if [ -n "$shell_path" ] && [ -x "$TARGET$shell_path" ]; then
    user_name=$(awk -F: '$3 >= 1000 && $3 < 60000 && $6 ~ /^\/home\// { print $1; exit }' "$TARGET/etc/passwd")
    if [ -n "$user_name" ]; then
        if in-target usermod -s "$shell_path" "$user_name"; then echo "Login shell set to $shell_path for $user_name."
        else echo "WARNING: could not set login shell for $user_name."; fi
    else echo 'No regular user found yet; selected shell is installed and recorded for manual application.'; fi
fi
printf 'CUSTOM_INSTALL_COMPLETED=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || echo unknown)" >> "$TARGET/etc/custom/install-status"
echo 'CUSTOM target configuration handoff completed.'

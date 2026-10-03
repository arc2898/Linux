#!/bin/bash

# Linux Brand Modifier Uninstaller
# This script removes the 'lbm' command and restores backups if available.

PROJECT_DIR="/opt/linux-brand-modifier"
BIN_FILE="/usr/local/bin/lbm"
BACKUP_BASE="/var/lib/lbm/backups"

echo "Uninstalling Linux Brand Modifier..."

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./uninstall.sh)"
  exit 1
fi

# Restore latest backup if user wants
if [ -d "$BACKUP_BASE" ]; then
    LATEST_BACKUP=$(ls -td $BACKUP_BASE/*/ | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        echo "Found system backup at $LATEST_BACKUP"
        read -p "Do you want to restore the latest system backup? (y/n): " confirm
        if [[ $confirm == [yY] ]]; then
            MAPPING_FILE="${LATEST_BACKUP}mapping.txt"
            if [ -f "$MAPPING_FILE" ]; then
                echo "Restoring files..."
                while IFS=: read -r backup_name original_path; do
                    if [ -f "${LATEST_BACKUP}${backup_name}" ]; then
                        cp "${LATEST_BACKUP}${backup_name}" "$original_path"
                        echo "Restored $original_path"
                    fi
                done < "$MAPPING_FILE"
            else
                echo "Warning: No mapping file found in backup. Manual restoration may be required."
            fi
            
            # Rebuild GRUB if needed
            echo "Refreshing bootloader configuration..."
            if command -v update-grub &> /dev/null; then
                update-grub > /dev/null 2>&1
            elif command -v grub-mkconfig &> /dev/null; then
                grub-mkconfig -o /boot/grub/grub.cfg > /dev/null 2>&1
            elif command -v grub2-mkconfig &> /dev/null; then
                grub2-mkconfig -o /boot/grub2/grub.cfg > /dev/null 2>&1
            fi
        fi
    fi
fi

# Remove files
rm -f $BIN_FILE
rm -rf $PROJECT_DIR
# We keep the backups just in case, unless explicitly requested to delete
read -p "Do you want to delete all system backups? (y/n): " delete_backups
if [[ $delete_backups == [yY] ]]; then
    rm -rf /var/lib/lbm
fi

echo "Uninstallation complete!"

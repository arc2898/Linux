#!/bin/bash

# Linux Brand Modifier Installer
# This script installs the 'lbm' command to your system.

PROJECT_DIR="/opt/linux-brand-modifier"
BIN_FILE="/usr/local/bin/lbm"

echo "Installing Linux Brand Modifier..."

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo ./install.sh)"
  exit 1
fi

# Install dependencies
echo "Checking dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install rich blessed --break-system-packages 2>/dev/null || pip3 install rich blessed
else
    echo "pip3 not found. Please install python3-pip."
    exit 1
fi

# Create directory and copy files
mkdir -p $PROJECT_DIR
cp main.py core.py uninstall.sh $PROJECT_DIR/
chmod +x $PROJECT_DIR/uninstall.sh

# Create wrapper script
cat <<EOF > $BIN_FILE
#!/bin/bash
# Ensure script is run as root
if [ "\$EUID" -ne 0 ]; then
  echo "Please run as root (sudo lbm)"
  exit 1
fi
python3 $PROJECT_DIR/main.py "\$@"
EOF

chmod +x $BIN_FILE

echo "Installation complete!"
echo "You can now run the tool by typing: sudo lbm"
echo "To uninstall and restore, run: sudo $PROJECT_DIR/uninstall.sh"

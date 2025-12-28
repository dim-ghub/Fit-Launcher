#!/bin/bash

# Fit-Launcher Installation Script
set -e

echo "Installing Fit-Launcher..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Detect system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Get latest release info
echo "Fetching latest release information..."
API_URL="https://api.github.com/repos/dim-ghub/Fit-Launcher/releases/latest"
RELEASE_INFO=$(curl -s "$API_URL")

# Extract download URL for the binary
BINARY_URL=$(echo "$RELEASE_INFO" | grep -Eo '"browser_download_url": ?"[^"]*Fit-Launcher[^"]*'" | grep "$ARCH" | grep -v ".sig" | head -1 | sed 's/"browser_download_url": "//' | sed 's/"//')

if [ -z "$BINARY_URL" ]; then
    echo "Error: Could not find binary for architecture $ARCH"
    exit 1
fi

echo "Downloading Fit-Launcher binary from: $BINARY_URL"
curl -L -o "$TEMP_DIR/Fit-Launcher" "$BINARY_URL"

# Make binary executable
chmod +x "$TEMP_DIR/Fit-Launcher"

# Install to /usr/bin (requires sudo)
echo "Installing binary to /usr/bin/Fit-Launcher..."
if sudo mv "$TEMP_DIR/Fit-Launcher" /usr/bin/Fit-Launcher; then
    echo "Binary installed successfully."
else
    echo "Error: Failed to install binary. Please check permissions."
    exit 1
fi

# Download icon
echo "Downloading icon..."
ICON_DIR="$HOME/.local/share/icons"
mkdir -p "$ICON_DIR"
curl -L -o "$ICON_DIR/fit-launcher.png" "https://raw.githubusercontent.com/dim-ghub/Fit-Launcher/refs/heads/master/src-tauri/icons/icon.png"

# Create .desktop file
echo "Creating desktop entry..."
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/Fit Launcher.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Fit Launcher
Comment=Game launcher and manager
Exec=/usr/bin/Fit-Launcher
Icon=$HOME/.local/share/icons/fit-launcher.png
Terminal=false
Categories=Game;Utility;
StartupWMClass=fit-launcher
EOF

# Make .desktop file executable
chmod +x "$DESKTOP_DIR/Fit Launcher.desktop"

# Update desktop database
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

echo ""
echo "Fit-Launcher installation completed successfully!"
echo "You can now run Fit-Launcher from your applications menu or by typing 'Fit-Launcher' in terminal."
#!/bin/bash

# Fit Launcher Linux Installer Script
# Downloads and installs Fit Launcher on Linux systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# App details
APP_NAME="Fit-Launcher"
APP_EXECUTABLE="Fit Launcher"
DESKTOP_FILE="com.fitlauncher.carrotrub.desktop"
INSTALL_DIR="$HOME/.local/share/Fit-Launcher"
DESKTOP_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"

# GitHub repository details
REPO_OWNER="dim-ghub"
REPO_NAME="Fit-Launcher"

echo -e "${BLUE}Fit Launcher Linux Installer${NC}"
echo "================================"

# Function to detect system architecture
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="x64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        *)
            echo -e "${RED}Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}Detected architecture: $ARCH${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    if ! command_exists curl; then
        echo -e "${YELLOW}Installing curl...${NC}"
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command_exists dnf; then
            sudo dnf install -y curl
        elif command_exists pacman; then
            sudo pacman -S curl
        else
            echo -e "${RED}Could not install curl. Please install it manually.${NC}"
            exit 1
        fi
    fi
    
    if ! command_exists unzip; then
        echo -e "${YELLOW}Installing unzip...${NC}"
        if command_exists apt-get; then
            sudo apt-get install -y unzip
        elif command_exists dnf; then
            sudo dnf install -y unzip
        elif command_exists pacman; then
            sudo pacman -S unzip
        else
            echo -e "${RED}Could not install unzip. Please install it manually.${NC}"
            exit 1
        fi
    fi
}

# Function to create directories
create_directories() {
    echo -e "${YELLOW}Creating directories...${NC}"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DESKTOP_DIR"
    mkdir -p "$BIN_DIR"
}

# Function to download latest release
download_release() {
    echo -e "${YELLOW}Fetching latest release information...${NC}"
    
    # Get latest release tag
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest" | grep -o '"tag_name": "[^"]*' | sed -E 's/.*"([^"]*)".*/\1/')
    
    if [ -z "$LATEST_RELEASE" ]; then
        echo -e "${RED}Failed to fetch latest release information${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Latest release: $LATEST_RELEASE${NC}"
    
    # Download URL for the zip file
    DOWNLOAD_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$LATEST_RELEASE/release.zip"
    
    echo -e "${YELLOW}Downloading Fit Launcher...${NC}"
    curl -L -o "/tmp/fit-launcher-release.zip" "$DOWNLOAD_URL"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download Fit Launcher${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Download completed${NC}"
}

# Function to extract and install
extract_install() {
    echo -e "${YELLOW}Extracting Fit Launcher...${NC}"
    
    # Remove old installation
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Removing old installation...${NC}"
        rm -rf "$INSTALL_DIR"
    fi
    
    # Extract to installation directory
    cd /tmp
    unzip -q "fit-launcher-release.zip"
    
    # Find the extracted directory (it might have a different name)
    EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "*Fit*" -o -name "*fit*" | head -1 | cut -c3-)
    
    if [ -z "$EXTRACTED_DIR" ]; then
        echo -e "${RED}Could not find extracted directory${NC}"
        exit 1
    fi
    
    # Move to installation directory
    mv "$EXTRACTED_DIR" "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/$APP_EXECUTABLE"
    
    echo -e "${GREEN}Extraction completed${NC}"
}

# Function to create desktop entry
create_desktop_entry() {
    echo -e "${YELLOW}Creating desktop entry...${NC}"
    
    cat > "$DESKTOP_DIR/$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Fit Launcher
Comment=A game launcher and manager
Exec=$INSTALL_DIR/$APP_EXECUTABLE
Icon=$INSTALL_DIR/icons/128x128.png
Terminal=false
StartupWMClass=fit-launcher
Categories=Game;
EOF
    
    chmod +x "$DESKTOP_DIR/$DESKTOP_FILE"
    
    # Update desktop database
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    
    echo -e "${GREEN}Desktop entry created${NC}"
}

# Function to create symlink in PATH
create_symlink() {
    echo -e "${YELLOW}Creating command-line shortcut...${NC}"
    
    # Remove existing symlink
    if [ -L "$BIN_DIR/fit-launcher" ]; then
        rm "$BIN_DIR/fit-launcher"
    fi
    
    # Create new symlink
    ln -s "$INSTALL_DIR/$APP_EXECUTABLE" "$BIN_DIR/fit-launcher"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$HOME/.bashrc"
        echo -e "${YELLOW}Added $BIN_DIR to PATH. Please run: source ~/.bashrc${NC}"
    fi
    
    echo -e "${GREEN}Command-line shortcut created${NC}"
}

# Function to cleanup
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    rm -f "/tmp/fit-launcher-release.zip"
    rm -rf "/tmp/$EXTRACTED_DIR" 2>/dev/null || true
    echo -e "${GREEN}Cleanup completed${NC}"
}

# Function to show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}To launch Fit Launcher:${NC}"
    echo "  • From your applications menu"
    echo "  • From terminal: fit-launcher"
    echo "  • Direct: $INSTALL_DIR/$APP_EXECUTABLE"
    echo ""
    echo -e "${YELLOW}Note: If this is your first time running, you may need to:${NC}"
    echo "  1. Log out and log back in (for desktop entry to appear)"
    echo "  2. Run: source ~/.bashrc (for command-line access)"
    echo ""
}

# Main installation flow
main() {
    echo -e "${BLUE}Starting Fit Launcher installation...${NC}"
    echo ""
    
    detect_arch
    install_dependencies
    create_directories
    download_release
    extract_install
    create_desktop_entry
    create_symlink
    cleanup
    show_completion
}

# Run main function
main "$@"

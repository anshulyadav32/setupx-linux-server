<<<<<<< HEAD
#!/usr/bin/env bash
# SetupX Installation Script
# Installs SetupX CLI tool to the system

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation paths
INSTALL_DIR="/usr/local/bin/setupx"
SETUPX_BIN="/usr/local/bin/setupx"
SLX_BIN="/usr/local/bin/slx"

echo -e "${BLUE}🚀 SetupX Installation${NC}"
echo "========================"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  Running as root. This is not recommended for installation.${NC}"
    echo "Please run as a regular user with sudo privileges."
    exit 1
fi

# Check if sudo is available
if ! command -v sudo >/dev/null 2>&1; then
    echo -e "${RED}❌ sudo is required but not available${NC}"
    exit 1
fi

# Get current directory
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$CURRENT_DIR")"

echo -e "${BLUE}📁 Installing from: $PROJECT_ROOT${NC}"
echo ""

# Create installation directory
echo -e "${YELLOW}📂 Creating installation directory...${NC}"
sudo mkdir -p "$INSTALL_DIR"

# Copy all files
echo -e "${YELLOW}📋 Copying files...${NC}"
sudo cp -r "$PROJECT_ROOT"/* "$INSTALL_DIR/"

# Make scripts executable
echo -e "${YELLOW}🔧 Setting permissions...${NC}"
sudo chmod +x "$INSTALL_DIR/setupx"
sudo chmod +x "$INSTALL_DIR/slx"
sudo chmod +x "$INSTALL_DIR/scripts"/*.sh
sudo chmod +x "$INSTALL_DIR/test"/*.sh

# Create symlinks
echo -e "${YELLOW}🔗 Creating symlinks...${NC}"
sudo ln -sf "$INSTALL_DIR/setupx" "$SETUPX_BIN"
sudo ln -sf "$INSTALL_DIR/slx" "$SLX_BIN"

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo -e "${YELLOW}📦 Installing jq dependency...${NC}"
    sudo apt update
    sudo apt install -y jq
fi

echo ""
echo -e "${GREEN}✅ SetupX installed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Usage Examples:${NC}"
echo "  setupx install curl"
echo "  setupx check nodejs"
echo "  setupx list"
echo "  setupx -sh final-ssh-root-login -p passwordroot"
echo "  slx install docker"
echo "  slx -sh deploy-node-app"
echo ""
echo -e "${BLUE}🔧 Available Scripts:${NC}"
for script in "$INSTALL_DIR/scripts"/*.sh; do
    script_name=$(basename "$script" .sh)
    echo "  📄 $script_name"
done
echo ""
echo -e "${GREEN}🎉 SetupX is ready to use!${NC}"
echo "Run 'setupx help' for more information."
=======
#!/bin/bash
# SetupX Installation Script
# Installs SetupX to the system and adds it to PATH

INSTALL_PATH="${1:-/usr/local/bin/setupx}"
FORCE="${2:-false}"

# Get the current script location
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "SetupX Installation Script"
echo "========================="
echo ""

# Check if already installed
if [ -d "$INSTALL_PATH" ] && [ "$FORCE" != "true" ]; then
    echo "SetupX is already installed at: $INSTALL_PATH"
    read -p "Do you want to reinstall? (y/N): " response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

echo "Installing SetupX to: $INSTALL_PATH"

# Create installation directory
if [ ! -d "$INSTALL_PATH" ]; then
    mkdir -p "$INSTALL_PATH"
    echo "✓ Created installation directory"
fi

# Copy all files to installation directory
echo "Copying files..."

# Copy all files and folders
cp -r "$SCRIPT_ROOT"/* "$INSTALL_PATH/"

echo "✓ Files copied successfully"

# Create setupx.sh in installation directory (main entry point)
cat > "$INSTALL_PATH/setupx.sh" << 'EOF'
#!/bin/bash
# SetupX Main Entry Point
# This file is the main entry point for SetupX

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import core modules
source "$SCRIPT_DIR/src/utils/logger.sh"
source "$SCRIPT_DIR/src/utils/helpers.sh"
source "$SCRIPT_DIR/src/core/engine.sh"
source "$SCRIPT_DIR/src/core/json-loader.sh"

# Call the main setupx.sh with all arguments
MAIN_SCRIPT_PATH="$SCRIPT_DIR/setupx.sh"

if [ -f "$MAIN_SCRIPT_PATH" ]; then
    bash "$MAIN_SCRIPT_PATH" "$@"
else
    echo "Error: setupx.sh not found in $SCRIPT_DIR"
    echo "Please ensure SetupX is properly installed."
fi
EOF

chmod +x "$INSTALL_PATH/setupx.sh"
echo "✓ Created main entry point"

# Create wsx.sh alias
cat > "$INSTALL_PATH/wsx.sh" << 'EOF'
#!/bin/bash
# WSX - Alias for SetupX CLI
# This is a shorter alternative command name for SetupX

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the main SetupX CLI with all arguments
SETUPX_PATH="$SCRIPT_DIR/setupx.sh"

if [ -f "$SETUPX_PATH" ]; then
    bash "$SETUPX_PATH" "$@"
else
    echo "Error: setupx.sh not found in $SCRIPT_DIR"
    echo "Please ensure SetupX is properly installed."
fi
EOF

chmod +x "$INSTALL_PATH/wsx.sh"
echo "✓ Created wsx alias"

# Add to PATH
echo "Adding SetupX to PATH..."

# Get current PATH
CURRENT_PATH="$PATH"

if [[ "$CURRENT_PATH" != *"$INSTALL_PATH"* ]]; then
    # Add to ~/.bashrc
    echo "export PATH=\"\$PATH:$INSTALL_PATH\"" >> ~/.bashrc
    echo "✓ Added to ~/.bashrc"
    
    # Add to ~/.profile
    echo "export PATH=\"\$PATH:$INSTALL_PATH\"" >> ~/.profile
    echo "✓ Added to ~/.profile"
    
    # Update current session PATH
    export PATH="$PATH:$INSTALL_PATH"
    echo "✓ Updated current session PATH"
else
    echo "✓ Already in PATH"
fi

# Test installation
echo ""
echo "Testing installation..."

TEST_SCRIPT="$INSTALL_PATH/setupx.sh"
if [ -f "$TEST_SCRIPT" ]; then
    if bash "$TEST_SCRIPT" version >/dev/null 2>&1; then
        echo "✓ Installation test successful"
    else
        echo "⚠ Installation test had issues but files are in place"
    fi
fi

echo ""
echo "🎉 SetupX Installation Complete!"
echo "Installation path: $INSTALL_PATH"
echo ""
echo "You can now use SetupX with:"
echo "  setupx help"
echo "  wsx help"
echo ""
echo "Note: You may need to restart your terminal or run 'source ~/.bashrc' for PATH changes to take effect."
>>>>>>> 9e1ea186d43fe9861fbae8546614bd4b7813437f

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

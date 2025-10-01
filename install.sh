#!/bin/bash
# SetupX Linux - One Line Installer
# Complete Linux development environment setup tool

echo "🚀 SetupX Linux - One Line Installer"
echo "===================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    echo "The script will use sudo when needed"
    exit 1
fi

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "📦 Installing jq (required for SetupX)..."
    sudo apt update
    sudo apt install -y jq
fi

# Create installation directory
INSTALL_DIR="/usr/local/bin/setupx"
echo "📁 Creating installation directory: $INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

# Download and install SetupX
echo "⬇️ Downloading SetupX..."
cd /tmp
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/setupx.sh -o setupx.sh
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/config.json -o config.json

# Create src directory structure
sudo mkdir -p "$INSTALL_DIR/src/core"
sudo mkdir -p "$INSTALL_DIR/src/utils"
sudo mkdir -p "$INSTALL_DIR/src/config/modules"
sudo mkdir -p "$INSTALL_DIR/scripts"

# Download core files
echo "📥 Downloading core files..."
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/core/engine.sh -o engine.sh
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/core/json-loader.sh -o json-loader.sh
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/utils/helpers.sh -o helpers.sh
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/utils/logger.sh -o logger.sh

# Download module files
echo "📥 Downloading modules..."
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/package-managers.json -o package-managers.json
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/web-development.json -o web-development.json
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/common-development.json -o common-development.json
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/system-security.json -o system-security.json
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/scripts.json -o scripts.json
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/ai-development-tools.json -o ai-development-tools.json
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/cloud-development.json -o cloud-development.json
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/src/config/modules/devops.json -o devops.json

# Download script files
echo "📥 Downloading scripts..."
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/scripts/final-ssh-root-login.sh -o final-ssh-root-login.sh
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/scripts/nginx-domain.sh -o nginx-domain.sh
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/scripts/pm2-deploy.sh -o pm2-deploy.sh
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/scripts/setcp.sh -o setcp.sh

# Copy files to installation directory
echo "📋 Installing SetupX..."
sudo cp setupx.sh "$INSTALL_DIR/"
sudo cp config.json "$INSTALL_DIR/"
sudo cp engine.sh "$INSTALL_DIR/src/core/"
sudo cp json-loader.sh "$INSTALL_DIR/src/core/"
sudo cp helpers.sh "$INSTALL_DIR/src/utils/"
sudo cp logger.sh "$INSTALL_DIR/src/utils/"
sudo cp *.json "$INSTALL_DIR/src/config/modules/"
sudo cp *.sh "$INSTALL_DIR/scripts/"

# Make scripts executable
echo "🔧 Setting permissions..."
sudo chmod +x "$INSTALL_DIR/setupx.sh"
sudo chmod +x "$INSTALL_DIR/src/core/*.sh"
sudo chmod +x "$INSTALL_DIR/src/utils/*.sh"
sudo chmod +x "$INSTALL_DIR/scripts/*.sh"

# Create symlinks
echo "🔗 Creating symlinks..."
sudo ln -sf "$INSTALL_DIR/setupx.sh" /usr/local/bin/setupx
sudo ln -sf "$INSTALL_DIR/setupx.sh" /usr/local/bin/wsx

# Add to PATH if not already there
if ! echo "$PATH" | grep -q "/usr/local/bin"; then
    echo "📝 Adding to PATH..."
    echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
    export PATH="/usr/local/bin:$PATH"
fi

# Clean up
cd "$HOME"
rm -rf /tmp/setupx.sh /tmp/config.json /tmp/*.sh /tmp/*.json

echo ""
echo "🎉 SetupX Linux installed successfully!"
echo "======================================"
echo ""
echo "📋 Installation Details:"
echo "  Install Directory: $INSTALL_DIR"
echo "  Executable: /usr/local/bin/setupx"
echo "  Alias: /usr/local/bin/wsx"
echo ""
echo "🚀 Quick Start:"
echo "  setupx help                    # Show help"
echo "  setupx list                    # List all modules"
echo "  setupx install-module package-managers  # Install package managers"
echo "  setupx -sh setcp -p postgresql newpass123  # Reset database password"
echo ""
echo "📚 Documentation:"
echo "  https://github.com/anshulyadav32/setupx-linux-server"
echo "  https://anshulyadav32.github.io/setupx-linux-server/"
echo ""
echo "✨ SetupX is ready to use!"

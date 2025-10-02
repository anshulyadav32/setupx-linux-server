#!/bin/bash
# SetupX Linux - One Line Installer
# Complete Linux development environment setup tool

echo "🚀 SetupX Linux - One Line Installer"
echo "===================================="
echo ""

# Always run as root - no check needed
echo "🔧 Running SetupX installer as root..."

# Update and upgrade system
echo "🔄 Updating and upgrading system packages..."
apt update
apt upgrade -y
apt autoremove -y
apt autoclean

# Install essential tools
echo "📦 Installing essential development tools..."
apt install -y curl wget git jq python3 python3-pip python3-venv build-essential

# Install GitHub CLI
echo "📦 Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update
apt install -y gh

# Install NVM (Node Version Manager)
echo "📦 Installing NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install latest LTS Node.js
echo "📦 Installing Node.js LTS..."
nvm install --lts
nvm use --lts
nvm alias default lts/*

# Install PM2 globally
echo "📦 Installing PM2..."
npm install -g pm2

# Install additional useful tools
echo "📦 Installing additional development tools..."
apt install -y vim nano htop tree unzip zip

# Create installation directory
INSTALL_DIR="/usr/local/bin/setupx"
echo "📁 Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

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
cp setupx.sh "$INSTALL_DIR/"
cp config.json "$INSTALL_DIR/"
cp engine.sh "$INSTALL_DIR/src/core/"
cp json-loader.sh "$INSTALL_DIR/src/core/"
cp helpers.sh "$INSTALL_DIR/src/utils/"
cp logger.sh "$INSTALL_DIR/src/utils/"
cp *.json "$INSTALL_DIR/src/config/modules/"
cp *.sh "$INSTALL_DIR/scripts/"

# Make scripts executable
echo "🔧 Setting permissions..."
chmod +x "$INSTALL_DIR/setupx.sh"
chmod +x "$INSTALL_DIR/src/core/engine.sh"
chmod +x "$INSTALL_DIR/src/core/json-loader.sh"
chmod +x "$INSTALL_DIR/src/utils/helpers.sh"
chmod +x "$INSTALL_DIR/src/utils/logger.sh"
chmod +x "$INSTALL_DIR/scripts/final-ssh-root-login.sh"
chmod +x "$INSTALL_DIR/scripts/nginx-domain.sh"
chmod +x "$INSTALL_DIR/scripts/pm2-deploy.sh"
chmod +x "$INSTALL_DIR/scripts/setcp.sh"

# Create symlinks
echo "🔗 Creating symlinks..."
# Remove existing files/directories
rm -rf /usr/local/bin/setupx
rm -rf /usr/local/bin/wsx
# Create symlinks to the main script
ln -s "$INSTALL_DIR/setupx.sh" /usr/local/bin/setupx
ln -s "$INSTALL_DIR/setupx.sh" /usr/local/bin/wsx

# Add to PATH for all users
echo "📝 Adding to PATH for all users..."
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/bash.bashrc
echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile

# Add NVM to all users
echo 'export NVM_DIR="$HOME/.nvm"' >> /etc/bash.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /etc/bash.bashrc
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /etc/bash.bashrc

# Set up NVM for root user
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Refresh environment
export PATH="/usr/local/bin:$PATH"

# Clean up
cd "$HOME"
rm -rf /tmp/setupx.sh /tmp/config.json /tmp/*.sh /tmp/*.json

# Verify installation
echo "🔍 Verifying installation..."
if [ -f "/usr/local/bin/setupx" ] && [ -x "/usr/local/bin/setupx" ]; then
    echo "✅ SetupX executable created successfully"
else
    echo "❌ SetupX executable not found or not executable"
    exit 1
fi

if [ -f "$INSTALL_DIR/setupx.sh" ]; then
    echo "✅ Main script installed successfully"
else
    echo "❌ Main script not found"
    exit 1
fi

if [ -f "$INSTALL_DIR/config.json" ]; then
    echo "✅ Configuration file installed successfully"
else
    echo "❌ Configuration file not found"
    exit 1
fi

# Test the installation
echo "🧪 Testing SetupX..."
if /usr/local/bin/setupx --help >/dev/null 2>&1; then
    echo "✅ SetupX is working correctly"
else
    echo "⚠️ SetupX installed but may have issues"
fi

echo ""
echo "🎉 SetupX Linux installed successfully!"
echo "======================================"
echo ""
echo "📋 Installation Details:"
echo "  Install Directory: $INSTALL_DIR"
echo "  Executable: /usr/local/bin/setupx"
echo "  Alias: /usr/local/bin/wsx"
echo ""
echo "🔧 Installed Tools:"
echo "  ✅ System updated and upgraded"
echo "  ✅ Git, Python3, jq, curl, wget"
echo "  ✅ GitHub CLI (gh)"
echo "  ✅ NVM with Node.js LTS"
echo "  ✅ PM2 process manager"
echo "  ✅ Vim, nano, htop, tree"
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
echo ""
echo "💡 Note: If 'setupx' command is not found, run:"
echo "  source /etc/bash.bashrc"
echo "  or"
echo "  export PATH=\"/usr/local/bin:\$PATH\""
echo ""
echo "🔄 To refresh environment immediately:"
echo "  source /etc/bash.bashrc && setupx help"

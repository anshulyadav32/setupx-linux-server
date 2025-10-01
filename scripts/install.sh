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

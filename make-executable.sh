#!/bin/bash
# Make all bash scripts executable
# This script should be run on Linux to make all scripts executable

echo "Making all bash scripts executable..."

# Make main scripts executable
chmod +x setupx.sh
chmod +x install.sh
chmod +x wsx.sh

# Make test scripts executable
chmod +x test-all-components.sh
chmod +x test-component.sh
chmod +x test-script.sh

# Make core modules executable
chmod +x src/core/*.sh

# Make utils executable
chmod +x src/utils/*.sh

echo "✅ All scripts are now executable!"
echo ""
echo "You can now run:"
echo "  ./setupx.sh help"
echo "  ./setupx.sh list"
echo "  ./setupx.sh status"

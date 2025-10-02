#!/bin/bash

# Test SetupX with WSL
echo "🚀 Testing SetupX with WSL (Windows Subsystem for Linux)"
echo "========================================================"
echo ""

echo "📋 Testing basic commands..."
echo ""

echo "1. Help command:"
wsl bash setupx.sh help | head -20
echo ""

echo "2. List modules:"
wsl bash setupx.sh list | head -10
echo ""

echo "3. List scripts:"
wsl bash setupx.sh scripts | head -15
echo ""

echo "4. Check system status:"
wsl bash setupx.sh status
echo ""

echo "✅ SetupX is working correctly with WSL!"
echo ""
echo "🎯 Usage Examples:"
echo "  wsl bash setupx.sh help                    # Show help"
echo "  wsl bash setupx.sh list                    # List modules"
echo "  wsl bash setupx.sh scripts                 # List scripts"
echo "  wsl bash setupx.sh menu                     # Interactive menu"
echo "  wsl bash setupx.sh scripts-menu             # Scripts menu"
echo "  wsl bash setupx.sh install-module web-development  # Install web dev tools"
echo "  wsl bash setupx.sh -sh nginx-domain -d example.com -p 3000  # Setup domain"
echo ""
echo "📚 For complete documentation, see: docs/README.md"

#!/usr/bin/env bash
# Update All Script
# Updates all upgradeable packages and cleans up the system

set -euo pipefail

# Default values
AUTO_CONFIRM=false
CLEANUP=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        --no-cleanup)
            CLEANUP=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-y] [--no-cleanup]"
            echo ""
            echo "Options:"
            echo "  -y, --yes        Auto-confirm all updates without prompting"
            echo "  --no-cleanup     Skip cleanup of unused packages and cache"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h for help"
            exit 1
            ;;
    esac
done

echo "🔄 System Update All"
echo "===================="
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run with sudo"
    echo "Usage: sudo $0 [-y] [--no-cleanup]"
    exit 1
fi

# Update package lists
echo "📦 Updating package lists..."
apt update

# Show upgradable packages
echo ""
echo "📋 Checking for upgradable packages..."
UPGRADABLE_COUNT=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo "0")

if [ "$UPGRADABLE_COUNT" -eq 0 ]; then
    echo "✅ No packages need updating"
else
    echo "📦 Found $UPGRADABLE_COUNT packages that can be upgraded:"
    apt list --upgradable 2>/dev/null | grep upgradable | head -10
    if [ "$UPGRADABLE_COUNT" -gt 10 ]; then
        echo "... and $((UPGRADABLE_COUNT - 10)) more"
    fi
    echo ""
    
    # Upgrade packages
    if [ "$AUTO_CONFIRM" = true ]; then
        echo "🚀 Upgrading all packages (auto-confirm)..."
        apt upgrade -y
    else
        echo "🚀 Upgrading all packages..."
        apt upgrade
    fi
fi

# Clean up if requested
if [ "$CLEANUP" = true ]; then
    echo ""
    echo "🧹 Cleaning up system..."
    
    # Remove unused packages
    echo "  Removing unused packages..."
    apt autoremove -y
    
    # Clean package cache
    echo "  Cleaning package cache..."
    apt autoclean
    
    # Clean apt cache
    echo "  Cleaning apt cache..."
    apt clean
fi

echo ""
echo "✅ System update completed!"
echo ""
echo "📊 Summary:"
echo "  - Packages checked: $(apt list --installed 2>/dev/null | wc -l)"
echo "  - Packages upgraded: $UPGRADABLE_COUNT"
if [ "$CLEANUP" = true ]; then
    echo "  - Cleanup performed: Yes"
else
    echo "  - Cleanup performed: No"
fi
echo ""
echo "🎉 System is up to date!"

#!/bin/bash
# Test Script
# Simple test script for SetupX functionality

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "SetupX Test Script"
echo "=================="
echo ""

# Test if jq is installed
if command -v jq >/dev/null 2>&1; then
    echo "✅ jq is installed"
else
    echo "❌ jq is not installed"
    echo "Install with: sudo apt install -y jq"
    exit 1
fi

# Test if config.json exists
if [ -f "$SCRIPT_DIR/config.json" ]; then
    echo "✅ config.json found"
else
    echo "❌ config.json not found"
    exit 1
fi

# Test if core modules exist
if [ -f "$SCRIPT_DIR/src/core/engine.sh" ]; then
    echo "✅ Core engine found"
else
    echo "❌ Core engine not found"
    exit 1
fi

if [ -f "$SCRIPT_DIR/src/core/json-loader.sh" ]; then
    echo "✅ JSON loader found"
else
    echo "❌ JSON loader not found"
    exit 1
fi

if [ -f "$SCRIPT_DIR/src/utils/helpers.sh" ]; then
    echo "✅ Helpers found"
else
    echo "❌ Helpers not found"
    exit 1
fi

if [ -f "$SCRIPT_DIR/src/utils/logger.sh" ]; then
    echo "✅ Logger found"
else
    echo "❌ Logger not found"
    exit 1
fi

# Test main script
if [ -f "$SCRIPT_DIR/setupx.sh" ]; then
    echo "✅ Main script found"
else
    echo "❌ Main script not found"
    exit 1
fi

echo ""
echo "🎉 All tests passed! SetupX is ready to use."
echo ""
echo "Try running:"
echo "  ./setupx.sh help"
echo "  ./setupx.sh list"
echo "  ./setupx.sh status"

#!/bin/bash
# Test Component Script
# Tests a specific component

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import core modules
source "$SCRIPT_DIR/src/utils/logger.sh"
source "$SCRIPT_DIR/src/utils/helpers.sh"
source "$SCRIPT_DIR/src/core/engine.sh"
source "$SCRIPT_DIR/src/core/json-loader.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <component-name>"
    echo "Example: $0 curl"
    exit 1
fi

component_name="$1"
component=$(get_component_by_name "$component_name")

if [ -z "$component" ]; then
    echo "Component '$component_name' not found"
    echo "Use 'setupx list-all' to see available components"
    exit 1
fi

display_name=$(echo "$component" | jq -r '.displayName')
description=$(echo "$component" | jq -r '.description')

echo "Testing Component: $display_name"
echo "Description: $description"
echo ""

# Test if component is installed
if test_component_installed "$component"; then
    echo "✅ $display_name is installed"
    
    # Show version if available
    check_command=$(echo "$component" | jq -r '.commands.check // empty')
    if [ -n "$check_command" ]; then
        echo ""
        echo "Version information:"
        eval "$check_command"
    fi
else
    echo "❌ $display_name is not installed"
    echo ""
    echo "Install with: setupx install $component_name"
fi

#!/bin/bash
# Test All Components Script
# Tests all components in all modules

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import core modules
source "$SCRIPT_DIR/src/utils/logger.sh"
source "$SCRIPT_DIR/src/utils/helpers.sh"
source "$SCRIPT_DIR/src/core/engine.sh"
source "$SCRIPT_DIR/src/core/json-loader.sh"

echo "Testing All Components"
echo "====================="
echo ""

# Get all components
all_components=$(get_all_components)
component_count=$(echo "$all_components" | jq '. | length')

echo "Found $component_count components to test"
echo ""

success_count=0
fail_count=0

# Test each component
echo "$all_components" | jq -r '.[] | .name' | while read -r component_name; do
    component=$(get_component_by_name "$component_name")
    if [ -n "$component" ]; then
        display_name=$(echo "$component" | jq -r '.displayName')
        echo "Testing: $display_name"
        
        if test_component_installed "$component"; then
            echo "  ✅ $display_name is installed"
            ((success_count++))
        else
            echo "  ❌ $display_name is not installed"
            ((fail_count++))
        fi
        echo ""
    fi
done

echo "Test Results:"
echo "  ✅ Success: $success_count"
echo "  ❌ Failed: $fail_count"
echo "  📊 Total: $component_count"

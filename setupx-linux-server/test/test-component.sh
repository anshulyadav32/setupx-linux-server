#!/bin/bash
# Test Component Script - JSON Driven
# Tests a specific component using JSON configuration

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load test configuration
TEST_CONFIG="$SCRIPT_DIR/test-config.json"

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <component-name>"
    echo "Example: $0 curl"
    echo ""
    echo "Available components from test config:"
    jq -r '.testSuites.components.tests[].name' "$TEST_CONFIG" | sed 's/^/  /'
    exit 1
fi

component_name="$1"

# Check if component exists in test config
if ! jq -e ".testSuites.components.tests[] | select(.name == \"$component_name\")" "$TEST_CONFIG" >/dev/null; then
    echo "❌ Component '$component_name' not found in test configuration"
    echo "Available components:"
    jq -r '.testSuites.components.tests[].name' "$TEST_CONFIG" | sed 's/^/  /'
    exit 1
fi

# Get test configuration for component
test_config=$(jq -r ".testSuites.components.tests[] | select(.name == \"$component_name\")" "$TEST_CONFIG")
command=$(echo "$test_config" | jq -r '.command')
expected=$(echo "$test_config" | jq -r '.expected')

echo "🧪 Testing Component: $component_name"
echo "Command: $command"
echo "Expected: $expected"
echo ""

# Run the test
if eval "$command" 2>/dev/null | grep -q "$expected"; then
    echo "✅ $component_name test passed"
    echo "Output:"
    eval "$command" 2>/dev/null | head -1
else
    echo "❌ $component_name test failed"
    echo "Command output:"
    eval "$command" 2>&1 || echo "Command not found or failed"
fi

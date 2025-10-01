#!/bin/bash
# Test Script Script - JSON Driven
# Tests deployment scripts using JSON configuration

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_CONFIG="$SCRIPT_DIR/test-config.json"

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <script-name>"
    echo "Example: $0 final-ssh-root-login"
    echo ""
    echo "Available scripts from test config:"
    jq -r '.testSuites.scripts.tests[].name' "$TEST_CONFIG" | sed 's/^/  /'
    exit 1
fi

script_name="$1"

# Check if script exists in test config
if ! jq -e ".testSuites.scripts.tests[] | select(.name == \"$script_name\")" "$TEST_CONFIG" >/dev/null; then
    echo "❌ Script '$script_name' not found in test configuration"
    echo "Available scripts:"
    jq -r '.testSuites.scripts.tests[].name' "$TEST_CONFIG" | sed 's/^/  /'
    exit 1
fi

# Get test configuration for script
test_config=$(jq -r ".testSuites.scripts.tests[] | select(.name == \"$script_name\")" "$TEST_CONFIG")
script_file=$(echo "$test_config" | jq -r '.script')
args=$(echo "$test_config" | jq -r '.args[]?' | tr '\n' ' ')
expected=$(echo "$test_config" | jq -r '.expected')

echo "🧪 Testing Script: $script_name"
echo "Script: $script_file"
echo "Args: $args"
echo "Expected: $expected"
echo ""

# Check if script file exists
script_path="$PROJECT_ROOT/scripts/$script_file"
if [ ! -f "$script_path" ]; then
    echo "❌ Script file not found: $script_path"
    exit 1
fi

# Make script executable
chmod +x "$script_path"

# Run the script with test arguments
echo "Running script..."
if echo "$args" | xargs "$script_path" 2>&1 | grep -q "$expected"; then
    echo "✅ $script_name test passed"
    echo "Script executed successfully and produced expected output"
else
    echo "❌ $script_name test failed"
    echo "Script output:"
    echo "$args" | xargs "$script_path" 2>&1 || echo "Script execution failed"
fi

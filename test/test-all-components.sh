#!/bin/bash
# Test All Components Script - JSON Driven
# Tests all components defined in JSON configuration

set -euo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_CONFIG="$SCRIPT_DIR/test-config.json"

echo "🧪 SetupX Component Test Suite"
echo "==============================="
echo ""

# Test all components from JSON config
components=$(jq -r '.testSuites.components.tests[].name' "$TEST_CONFIG")
total_tests=0
passed_tests=0
failed_tests=0

for component in $components; do
    total_tests=$((total_tests + 1))
    echo "Testing: $component"
    
    if "$SCRIPT_DIR/test-component.sh" "$component" >/dev/null 2>&1; then
        echo "✅ $component - PASSED"
        passed_tests=$((passed_tests + 1))
    else
        echo "❌ $component - FAILED"
        failed_tests=$((failed_tests + 1))
    fi
    echo ""
done

echo "📊 Test Results Summary"
echo "======================="
echo "Total Tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"
echo "Success Rate: $(( (passed_tests * 100) / total_tests ))%"

if [ $failed_tests -eq 0 ]; then
    echo ""
    echo "🎉 All tests passed!"
    exit 0
else
    echo ""
    echo "⚠️  Some tests failed. Check the output above."
    exit 1
fi

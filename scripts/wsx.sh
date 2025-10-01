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

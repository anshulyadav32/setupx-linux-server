#!/bin/bash
# SetupX Helper Utility
# Common helper functions used across SetupX

test_administrator() {
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

get_setupx_version() {
    local config_path="$SCRIPT_DIR/../../config.json"
    if [ -f "$config_path" ]; then
        jq -r '.version' "$config_path"
    else
        echo "2.0.0"
    fi
}

update_environment_path() {
    local path_to_add="$1"
    
    if [ -n "$path_to_add" ] && [ -d "$path_to_add" ]; then
        export PATH="$PATH:$path_to_add"
        write_setupx_info "Added $path_to_add to PATH"
    fi
    
    # Refresh environment variables
    source ~/.bashrc 2>/dev/null || true
    source ~/.profile 2>/dev/null || true
    write_setupx_info "Environment PATH refreshed"
}

test_command_exists() {
    local command="$1"
    
    if command -v "$command" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

invoke_refresh_env() {
    # Refresh environment variables
    source ~/.bashrc 2>/dev/null || true
    source ~/.profile 2>/dev/null || true
    write_setupx_info "Environment variables refreshed"
}

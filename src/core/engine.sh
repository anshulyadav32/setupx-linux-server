#!/bin/bash
# SetupX Core Engine
# Executes commands from JSON configuration

invoke_component_command() {
    local component="$1"
    local action="$2"
    
    local command=$(echo "$component" | jq -r ".commands.$action // empty")
    
    if [ -z "$command" ]; then
        local display_name=$(echo "$component" | jq -r '.displayName')
        echo "Action '$action' not available for $display_name"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    
    echo ""
    echo "Executing: $display_name - $action"
    echo "Command: $command"
    echo ""
    
    # Execute the command
    if eval "$command"; then
        echo "$display_name - $action completed successfully"
        
        # Execute path refresh if specified
        local path_command=$(echo "$component" | jq -r '.commands.path // empty')
        if [ -n "$path_command" ]; then
            eval "$path_command" 2>/dev/null || echo "Warning: Path refresh failed"
        fi
        
        # Refresh environment variables
        source ~/.bashrc 2>/dev/null || true
        source ~/.profile 2>/dev/null || true
        
        return 0
    else
        echo "$display_name - $action failed with exit code: $?"
        return 1
    fi
}

get_all_components() {
    local all_components="[]"
    local modules_path="$SCRIPT_DIR/../config/modules"
    
    if [ -d "$modules_path" ]; then
        for json_file in "$modules_path"/*.json; do
            if [ -f "$json_file" ]; then
                local module_data=$(cat "$json_file")
                local module_name=$(echo "$module_data" | jq -r '.name')
                
                echo "$module_data" | jq -r '.components | to_entries[] | .key' | while read -r component_name; do
                    local component=$(echo "$module_data" | jq -r ".components.$component_name")
                    local component_with_module=$(echo "$component" | jq --arg module_name "$module_name" --arg file_name "$(basename "$json_file")" '. + {moduleName: $module_name, moduleFile: $file_name}')
                    echo "$component_with_module"
                done
            fi
        done
    fi
    
    # Also check main config file
    local main_config_path="$SCRIPT_DIR/../config/setupx.json"
    if [ -f "$main_config_path" ]; then
        local main_config=$(cat "$main_config_path")
        if echo "$main_config" | jq -e '.components' >/dev/null 2>&1; then
            echo "$main_config" | jq -r '.components | to_entries[] | .key' | while read -r component_name; do
                local component=$(echo "$main_config" | jq -r ".components.$component_name")
                local component_with_module=$(echo "$component" | jq '. + {moduleName: "main", moduleFile: "setupx.json"}')
                echo "$component_with_module"
            done
        fi
    fi
}

get_component_by_name() {
    local component_name="$1"
    
    local all_components=$(get_all_components)
    local component=$(echo "$all_components" | jq -r ".[] | select(.name == \"$component_name\")" | head -n1)
    
    if [ -z "$component" ]; then
        # Try fuzzy match
        component=$(echo "$all_components" | jq -r ".[] | select(.name | contains(\"$component_name\")) or select(.displayName | contains(\"$component_name\"))" | head -n1)
    fi
    
    echo "$component"
}

get_components_by_category() {
    local category="$1"
    
    local all_components=$(get_all_components)
    echo "$all_components" | jq -r ".[] | select(.category == \"$category\")"
}

get_components_by_module() {
    local module_name="$1"
    
    local all_components=$(get_all_components)
    echo "$all_components" | jq -r ".[] | select(.moduleName == \"$module_name\")"
}

get_module_config() {
    local module_name="$1"
    
    local module_path="$SCRIPT_DIR/../config/modules/$module_name.json"
    
    if [ -f "$module_path" ]; then
        cat "$module_path"
    else
        echo "Module configuration not found: $module_path" >&2
        echo "null"
    fi
}

get_all_module_configs() {
    local all_modules="[]"
    local modules_path="$SCRIPT_DIR/../config/modules"
    
    if [ -d "$modules_path" ]; then
        for json_file in "$modules_path"/*.json; do
            if [ -f "$json_file" ]; then
                local module_data=$(cat "$json_file")
                all_modules=$(echo "$all_modules" | jq ". + [$module_data]")
            fi
        done
    fi
    
    echo "$all_modules"
}

get_dynamic_paths() {
    local tool_type="$1"
    local paths="[]"
    
    case "$tool_type" in
        "Python")
            # Dynamic Python detection
            for version in 3.13 3.12 3.11 3.10 3.9 3.8; do
                paths=$(echo "$paths" | jq ". + [\"/usr/bin/python$version\", \"/usr/local/bin/python$version\", \"$HOME/.local/bin/python$version\"]")
            done
            # Check PATH for python
            for dir in $(echo "$PATH" | tr ':' ' '); do
                if [ -d "$dir" ] && [ -x "$dir/python" ]; then
                    paths=$(echo "$paths" | jq ". + [\"$dir/python\"]")
                fi
            done
            ;;
        "PythonSitePackages")
            # Dynamic Python site-packages detection
            for version in 3.13 3.12 3.11 3.10 3.9 3.8; do
                paths=$(echo "$paths" | jq ". + [\"/usr/lib/python$version/site-packages\", \"/usr/local/lib/python$version/site-packages\", \"$HOME/.local/lib/python$version/site-packages\"]")
            done
            ;;
        "NodeJS")
            # Dynamic Node.js detection
            paths=$(echo "$paths" | jq ". + [\"/usr/bin/node\", \"/usr/local/bin/node\", \"$HOME/.local/bin/node\"]")
            # Check PATH for node
            for dir in $(echo "$PATH" | tr ':' ' '); do
                if [ -d "$dir" ] && [ -x "$dir/node" ]; then
                    paths=$(echo "$paths" | jq ". + [\"$dir/node\"]")
                fi
            done
            ;;
        "NPM")
            # Dynamic npm detection
            paths=$(echo "$paths" | jq ". + [\"$HOME/.npm\", \"/usr/local/lib/node_modules/npm\"]")
            # Check PATH for npm
            for dir in $(echo "$PATH" | tr ':' ' '); do
                if [ -d "$dir" ] && [ -x "$dir/npm" ]; then
                    paths=$(echo "$paths" | jq ". + [\"$dir\"]")
                fi
            done
            ;;
        "Snap")
            # Dynamic Snap detection
            paths=$(echo "$paths" | jq ". + [\"/snap/bin\", \"/var/lib/snapd/snap\"]")
            ;;
        "Flatpak")
            # Dynamic Flatpak detection
            paths=$(echo "$paths" | jq ". + [\"/usr/bin/flatpak\", \"/var/lib/flatpak\"]")
            ;;
        "Apt")
            # Dynamic APT detection
            paths=$(echo "$paths" | jq ". + [\"/usr/bin/apt\", \"/var/lib/dpkg\"]")
            ;;
        "Pip")
            # Dynamic pip detection
            paths=$(echo "$paths" | jq ". + [\"/usr/bin/pip\", \"/usr/local/bin/pip\", \"$HOME/.local/bin/pip\"]")
            ;;
    esac
    
    echo "$paths" | jq -r '.[]' | grep -v '^null$'
}

test_component_installed() {
    local component="$1"
    
    # Try the check command first
    local check_command=$(echo "$component" | jq -r '.commands.check // empty')
    if [ -n "$check_command" ]; then
        if eval "$check_command" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Dynamic detection methods for common tools
    local component_name=$(echo "$component" | jq -r '.name' | tr '[:upper:]' '[:lower:]')
    
    # Check for Python
    if [ "$component_name" = "python" ]; then
        local python_paths=$(get_dynamic_paths "Python")
        for path in $python_paths; do
            if [ -x "$path" ]; then
                return 0
            fi
        done
    fi
    
    # Check for pip-based tools
    if [[ "$component_name" =~ ^(jupyter|tensorflow|pytorch|pandas|ansible)$ ]]; then
        local site_packages_paths=$(get_dynamic_paths "PythonSitePackages")
        for python_path in $site_packages_paths; do
            if [ -d "$python_path" ]; then
                local package_path="$python_path/$component_name"
                if [ -d "$package_path" ]; then
                    return 0
                fi
            fi
        done
    fi
    
    # Check for Node.js tools
    if [[ "$component_name" =~ ^(nodejs|yarn|react-tools|vue-tools|angular-tools|vite)$ ]]; then
        if [ "$component_name" = "nodejs" ]; then
            local node_paths=$(get_dynamic_paths "NodeJS")
            for path in $node_paths; do
                if [ -x "$path" ]; then
                    return 0
                fi
            done
        elif [ "$component_name" = "yarn" ]; then
            local yarn_paths=(
                "$HOME/.local/bin/yarn"
                "/usr/bin/yarn"
                "/usr/local/bin/yarn"
            )
            for yarn_path in "${yarn_paths[@]}"; do
                if [ -x "$yarn_path" ]; then
                    return 0
                fi
            done
        else
            local npm_paths=$(get_dynamic_paths "NPM")
            for npm_path in $npm_paths; do
                if [ -d "$npm_path" ]; then
                    local package_path="$npm_path/node_modules/$component_name"
                    if [ -d "$package_path" ]; then
                        return 0
                    fi
                fi
            done
        fi
    fi
    
    
    # Check for VS Code
    if [ "$component_name" = "vscode" ]; then
        local vscode_paths=(
            "/usr/bin/code"
            "/usr/local/bin/code"
            "$HOME/.local/bin/code"
            "/snap/bin/code"
        )
        for vscode_path in "${vscode_paths[@]}"; do
            if [ -x "$vscode_path" ]; then
                return 0
            fi
        done
    fi
    
    # Check for Docker
    if [ "$component_name" = "docker" ]; then
        if command -v docker >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Check for snap packages
    if command -v snap >/dev/null 2>&1; then
        if snap list "$component_name" >/dev/null 2>&1; then
            return 0
        fi
    fi
    
    # Check for flatpak packages
    if command -v flatpak >/dev/null 2>&1; then
        if flatpak list | grep -q "$component_name"; then
            return 0
        fi
    fi
    
    # Check for apt packages
    if command -v dpkg >/dev/null 2>&1; then
        if dpkg -l | grep -q "^ii.*$component_name"; then
            return 0
        fi
    fi
    
    return 1
}

#!/bin/bash
# SetupX Core Engine
# Executes commands from JSON configuration

# Load configuration
load_config() {
    local config_file="$SCRIPT_DIR/../config.json"
    if [ -f "$config_file" ]; then
        cat "$config_file"
    else
        echo "{}"
    fi
}

# Get configuration value
get_config_value() {
    local key="$1"
    local config=$(load_config)
    echo "$config" | jq -r ".$key // empty"
}

# Get paths from configuration
get_paths() {
    local config=$(load_config)
    echo "$config" | jq -r '.paths'
}

# Get modules path
get_modules_path() {
    local paths=$(get_paths)
    echo "$paths" | jq -r '.modules // "src/config/modules"'
}

# Get scripts path
get_scripts_path() {
    local paths=$(get_paths)
    echo "$paths" | jq -r '.scripts // "scripts"'
}

# Get test path
get_test_path() {
    local paths=$(get_paths)
    echo "$paths" | jq -r '.test // "test"'
}

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
    local modules_path=$(get_modules_path)
    local full_modules_path="$SCRIPT_DIR/../$modules_path"
    
    if [ -d "$full_modules_path" ]; then
        for json_file in "$full_modules_path"/*.json; do
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
    
    local modules_path=$(get_modules_path)
    local module_path="$SCRIPT_DIR/../$modules_path/$module_name.json"
    
    if [ -f "$module_path" ]; then
        cat "$module_path"
    else
        echo "Module configuration not found: $module_path" >&2
        echo "null"
    fi
}

get_all_module_configs() {
    local all_modules="[]"
    local modules_path=$(get_modules_path)
    local full_modules_path="$SCRIPT_DIR/../$modules_path"
    
    if [ -d "$full_modules_path" ]; then
        for json_file in "$full_modules_path"/*.json; do
            if [ -f "$json_file" ]; then
                local module_data=$(cat "$json_file")
                all_modules=$(echo "$all_modules" | jq ". + [$module_data]")
            fi
        done
    fi
    
    echo "$all_modules"
}

# Dynamic path detection
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

# Component installation
install_component() {
    local component_name="$1"
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        echo "Use 'setupx list-all' to see available components"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    echo "Installing: $display_name"
    
    if invoke_component_command "$component" "install"; then
        echo "✅ $display_name installed successfully"
    else
        echo "❌ $display_name installation failed"
        return 1
    fi
}

# Component removal
remove_component() {
    local component_name="$1"
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    echo "Removing: $display_name"
    
    if invoke_component_command "$component" "remove"; then
        echo "✅ $display_name removed successfully"
    else
        echo "❌ $display_name removal failed"
        return 1
    fi
}

# Component update
update_component() {
    local component_name="$1"
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    echo "Updating: $display_name"
    
    if invoke_component_command "$component" "update"; then
        echo "✅ $display_name updated successfully"
    else
        echo "❌ $display_name update failed"
        return 1
    fi
}

# Component check
check_component() {
    local component_name="$1"
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    
    if test_component_installed "$component"; then
        echo "✅ $display_name is installed"
        
        # Show version if available
        local check_command=$(echo "$component" | jq -r '.commands.check // empty')
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
}

# Component verification
verify_component() {
    local component_name="$1"
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    echo "Verifying: $display_name"
    
    if invoke_component_command "$component" "verify"; then
        echo "✅ $display_name verification passed"
    else
        echo "❌ $display_name verification failed"
        return 1
    fi
}

# Component testing
test_component() {
    local component_name="$1"
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    echo "Testing: $display_name"
    
    if invoke_component_command "$component" "test"; then
        echo "✅ $display_name test passed"
    else
        echo "❌ $display_name test failed"
        return 1
    fi
}

# List modules
list_modules() {
    local all_modules=$(get_all_module_configs)
    echo "Available Modules:"
    echo "$all_modules" | jq -r '.[] | "  \(.name) - \(.description)"' | sort
}

# List all components
list_all_components() {
    local all_components=$(get_all_components)
    echo "Available Components:"
    echo "$all_components" | jq -r '.[] | "  \(.name) - \(.displayName)"' | sort
}

# List components in module
list_components_in_module() {
    local module_name="$1"
    local module_config=$(get_module_config "$module_name")
    
    if [ "$module_config" = "null" ]; then
        echo "Module '$module_name' not found"
        return 1
    fi
    
    local module_display_name=$(echo "$module_config" | jq -r '.displayName')
    echo "Components in $module_display_name:"
    echo "$module_config" | jq -r '.components | to_entries[] | "  \(.key) - \(.value.displayName)"'
}

# Install module
install_module() {
    local module_name="$1"
    local module_config=$(get_module_config "$module_name")
    
    if [ "$module_config" = "null" ]; then
        echo "Module '$module_name' not found"
        return 1
    fi
    
    local module_display_name=$(echo "$module_config" | jq -r '.displayName')
    echo "Installing module: $module_display_name"
    
    local components=$(echo "$module_config" | jq -r '.components | to_entries[] | .key')
    local success_count=0
    local total_count=0
    
    for component_name in $components; do
        total_count=$((total_count + 1))
        if install_component "$component_name"; then
            success_count=$((success_count + 1))
        fi
    done
    
    echo ""
    echo "Module installation completed: $success_count/$total_count components installed"
}

# Check common tools status
check_common_tools_status() {
    local config=$(load_config)
    local common_tools=$(echo "$config" | jq -r '.statusCheck.commonTools[]')
    
    echo "Common Development Tools Status:"
    echo "================================="
    
    for tool in $common_tools; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "✅ $tool"
        else
            echo "❌ $tool"
        fi
    done
}

# Search components
search_components() {
    local keyword="$1"
    local all_components=$(get_all_components)
    
    echo "Search results for '$keyword':"
    echo "$all_components" | jq -r ".[] | select(.name | contains(\"$keyword\")) or select(.displayName | contains(\"$keyword\")) | \"  \(.name) - \(.displayName)\""
}
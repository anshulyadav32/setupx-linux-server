#!/bin/bash
# SetupX JSON Loader
# Handles loading and parsing JSON configuration files

get_setupx_config() {
    local config_path="$SCRIPT_DIR/../config/setupx.json"
    
    if [ -f "$config_path" ]; then
        cat "$config_path"
    else
        echo "Main configuration file not found: $config_path" >&2
        echo "null"
    fi
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

save_setupx_config() {
    local config="$1"
    local config_path="$SCRIPT_DIR/../config/setupx.json"
    
    if echo "$config" | jq . >/dev/null 2>&1; then
        echo "$config" > "$config_path"
        echo "Configuration saved successfully"
        return 0
    else
        echo "Error saving configuration: Invalid JSON" >&2
        return 1
    fi
}

new_module_config() {
    local module_name="$1"
    local display_name="$2"
    local description="$3"
    local category="${4:-development}"
    
    local module_path="$SCRIPT_DIR/../config/modules/$module_name.json"
    
    local module_template=$(cat <<EOF
{
  "name": "$module_name",
  "displayName": "$display_name",
  "description": "$description",
  "category": "$category",
  "priority": 1,
  "status": "available",
  "components": {}
}
EOF
)
    
    echo "$module_template" > "$module_path"
    echo "Module configuration created: $module_path"
    return 0
}

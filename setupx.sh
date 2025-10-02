#!/bin/bash
# SetupX - Modular Linux Development Environment Setup Tool
# JSON-Driven CLI Architecture
# Version: 2.0.0

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If this is a symlink, get the actual installation directory
if [ -L "${BASH_SOURCE[0]}" ]; then
    # Get the target of the symlink
    TARGET=$(readlink "${BASH_SOURCE[0]}")
    # Get the directory of the target
    SCRIPT_DIR="$(cd "$(dirname "$TARGET")" && pwd)"
fi

# Import core modules
source "$SCRIPT_DIR/src/utils/logger.sh"
source "$SCRIPT_DIR/src/utils/helpers.sh"
source "$SCRIPT_DIR/src/core/engine.sh"
source "$SCRIPT_DIR/src/core/json-loader.sh"

show_banner() {
    # Load config for version
    local config_path="$SCRIPT_DIR/config.json"
    local version=$(jq -r '.version' "$config_path")
    local title=$(jq -r '.cli.banner.title' "$config_path")
    local subtitle=$(jq -r '.cli.banner.subtitle' "$config_path")
    local description=$(jq -r '.cli.banner.description' "$config_path")
    
    echo "
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   ███████╗███████╗████████╗██╗   ██╗██████╗ ██╗  ██╗    ║
║   ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗╚██╗██╔╝    ║
║   ███████╗█████╗     ██║   ██║   ██║██████╔╝ ╚███╔╝     ║
║   ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝  ██╔██╗     ║
║   ███████║███████╗   ██║   ╚██████╔╝██║     ██╔╝ ██╗    ║
║   ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝  ╚═╝    ║
║                                                           ║
║          $subtitle          ║
║                   $description                ║
║                      Version $version                      ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
"
}

show_help() {
    show_banner
    
    echo "USAGE:"
    echo "    setupx <command> [arguments]"
    echo ""
    
    echo "COMMANDS:"
    echo "    help                          Show this help message"
    echo "    list                          List all available modules"
    echo "    list-all                      List all components from all modules"
    echo "    status                        Show system status and installed components"
    echo "    install <component>           Install a specific component"
    echo "    remove <component>            Remove/uninstall a component"
    echo "    update <component>            Update a component"
    echo "    check <component>             Check if a component is installed"
    echo "    verify <component>            Verify component installation"
    echo "    test <component>              Test component functionality"
    echo "    install-module <module>       Install all components in a module"
    echo "    list-module <module>          List components in a specific module"
    echo "    search <query>                Search for components"
    echo "    -sh <script> [args]           Run a script with arguments"
    echo "    version                       Show SetupX version"
    echo ""
    
    echo "EXAMPLES:"
    echo "    setupx list                   # List all modules"
    echo "    setupx list-all               # List all components"
    echo "    setupx install curl            # Install cURL"
    echo "    setupx install nodejs          # Install Node.js"
    echo "    setupx check curl             # Check if cURL is installed"
    echo "    setupx install-module web-development  # Install all web dev tools"
    echo "    setupx list-module package-managers    # List package managers"
    echo "    setupx search docker          # Search for Docker component"
    echo "    setupx -sh gcprootlogin -p rootpass ubuntupass  # Enable GCP root login"
    echo "    setupx -sh system-update    # Update system packages"
    echo "    setupx -sh setcp -p postgresql newpass123      # Reset PostgreSQL password"
    echo "    setupx -sh nginx-domain -d example.com -p 3000 # Setup Nginx domain"
    echo "    setupx -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp  # Deploy with PM2"
    echo ""
    
    echo "AVAILABLE MODULES:"
    get_all_module_configs | jq -r '.[] | "    \(.name) - \(.description)"' | sort
    echo ""
    echo "For more information: https://github.com/anshulyadav32/setupx-linux-setup"
}

show_list() {
    echo ""
    echo "Available SetupX Modules:"
    echo ""
    
    local modules=$(get_all_module_configs)
    local module_count=$(echo "$modules" | jq '. | length')
    
    if [ "$module_count" -eq 0 ]; then
        echo "No modules found. Check your configuration."
        return
    fi
    
    echo "$modules" | jq -r '.[] | "  \(.displayName) (\(.components | keys | length) components)\n    ID: \(.name)\n    \(.description)\n"'
    
    echo "Total modules: $module_count"
    echo "Use 'setupx list-module <module-name>' to see components in a module"
}

show_list_all() {
    echo ""
    echo "All Available Components:"
    echo ""
    
    local all_components=$(get_all_components)
    local component_count=$(echo "$all_components" | jq '. | length')
    
    if [ "$component_count" -eq 0 ]; then
        echo "No components found. Check your configuration."
        return
    fi
    
    # Group by category
    echo "$all_components" | jq -r 'group_by(.category) | .[] | "\(.[0].category):\n" + (.[] | "  \([if test_component_installed then "[+]" else "[ ]" end]) \(.displayName) (\(.name))")'
    
    echo ""
    echo "Total components: $component_count"
}

show_status() {
    echo ""
    echo "SetupX System Status"
    echo ""
    
    # Load config for version and tools to check
    local config_path="$SCRIPT_DIR/config.json"
    local version=$(jq -r '.version' "$config_path")
    
    # Show version
    echo "SetupX Version: $version"
    echo ""
    
    # Get tools to check from config
    local tools_to_check=$(jq -r '.statusCheck.commonTools[]' "$config_path")
    
    # Group tools by category
    local all_components=$(get_all_components)
    
    # Display by category
    echo "$all_components" | jq -r 'group_by(.category) | .[] | "\(.[0].category | ascii_upcase):\n" + (.[] | "  \([if test_component_installed then "[+]" else "[ ]" end]) \(.displayName)")'
}

invoke_install() {
    local component_name="$1"
    
    if [ -z "$component_name" ]; then
        echo "Error: Component name required"
        echo "Usage: setupx install <component-name>"
        return 1
    fi
    
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        echo "Use 'setupx list-all' to see available components"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    local description=$(echo "$component" | jq -r '.description')
    
    echo ""
    echo "Installing: $display_name"
    echo "Description: $description"
    echo ""
    
    if invoke_component_command "$component" "install"; then
        echo ""
        echo "[SUCCESS] $display_name installed successfully!"
    else
        echo ""
        echo "[FAILED] Failed to install $display_name"
    fi
}

invoke_remove() {
    local component_name="$1"
    
    if [ -z "$component_name" ]; then
        echo "Error: Component name required"
        echo "Usage: setupx remove <component-name>"
        return 1
    fi
    
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    
    echo ""
    echo "Removing: $display_name"
    echo ""
    
    if invoke_component_command "$component" "remove"; then
        echo ""
        echo "[SUCCESS] $display_name removed successfully!"
    else
        echo ""
        echo "[FAILED] Failed to remove $display_name"
    fi
}

invoke_check() {
    local component_name="$1"
    
    if [ -z "$component_name" ]; then
        echo "Error: Component name required"
        echo "Usage: setupx check <component-name>"
        return 1
    fi
    
    local component=$(get_component_by_name "$component_name")
    
    if [ -z "$component" ]; then
        echo "Component '$component_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$component" | jq -r '.displayName')
    
    echo ""
    echo "Checking: $display_name"
    
    if test_component_installed "$component"; then
        echo "[+] $display_name is installed"
        
        # Show version if available
        local check_command=$(echo "$component" | jq -r '.commands.check // empty')
        if [ -n "$check_command" ]; then
            echo ""
            echo "Version information:"
            eval "$check_command" >/dev/null 2>&1
        fi
    else
        echo "[-] $display_name is not installed"
        echo "Install with: setupx install $component_name"
    fi
}

invoke_install_module() {
    local module_name="$1"
    
    if [ -z "$module_name" ]; then
        echo "Error: Module name required"
        echo "Usage: setupx install-module <module-name>"
        return 1
    fi
    
    local module=$(get_module_config "$module_name")
    
    if [ -z "$module" ]; then
        echo "Module '$module_name' not found"
        echo "Use 'setupx list' to see available modules"
        return 1
    fi
    
    local display_name=$(echo "$module" | jq -r '.displayName')
    local description=$(echo "$module" | jq -r '.description')
    
    echo ""
    echo "Installing module: $display_name"
    echo "$description"
    echo ""
    
    local component_count=$(echo "$module" | jq '.components | keys | length')
    echo "This module contains $component_count components"
    echo ""
    
    local success_count=0
    local fail_count=0
    
    echo "$module" | jq -r '.components | to_entries[] | .key' | while read -r component_name; do
        local component=$(echo "$module" | jq -r ".components.$component_name")
        local component_display_name=$(echo "$component" | jq -r '.displayName')
        
        echo "Installing $component_display_name..."
        
        if invoke_component_command "$component" "install"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        
        echo ""
    done
    
    echo ""
    echo "Module installation complete:"
    echo "  [+] Success: $success_count"
    echo "  [-] Failed: $fail_count"
}

invoke_list_module() {
    local module_name="$1"
    
    if [ -z "$module_name" ]; then
        echo "Error: Module name required"
        echo "Usage: setupx list-module <module-name>"
        return 1
    fi
    
    local module=$(get_module_config "$module_name")
    
    if [ -z "$module" ]; then
        echo "Module '$module_name' not found"
        return 1
    fi
    
    local display_name=$(echo "$module" | jq -r '.displayName')
    local description=$(echo "$module" | jq -r '.description')
    
    echo ""
    echo "Module: $display_name"
    echo "$description"
    echo ""
    
    echo "$module" | jq -r '.components | to_entries[] | .key' | while read -r component_name; do
        local component=$(echo "$module" | jq -r ".components.$component_name")
        local component_display_name=$(echo "$component" | jq -r '.displayName')
        local component_description=$(echo "$component" | jq -r '.description')
        
        if test_component_installed "$component"; then
            echo "  [+] $component_display_name"
        else
            echo "  [ ] $component_display_name"
        fi
        echo "      $component_description"
        echo "      Install with: setupx install $component_name"
        echo ""
    done
}

invoke_search() {
    local query="$1"
    
    if [ -z "$query" ]; then
        echo "Error: Search query required"
        echo "Usage: setupx search <query>"
        return 1
    fi
    
    echo ""
    echo "Searching for: $query"
    echo ""
    
    local all_components=$(get_all_components)
    local results=$(echo "$all_components" | jq "[.[] | select(.name | contains(\"$query\")) or select(.displayName | contains(\"$query\")) or select(.description | contains(\"$query\"))]")
    local result_count=$(echo "$results" | jq '. | length')
    
    if [ "$result_count" -eq 0 ]; then
        echo "No components found matching '$query'"
        return
    fi
    
    echo "Found $result_count component(s):"
    echo ""
    
    echo "$results" | jq -r '.[] | "  \([if test_component_installed then "[+]" else "[ ]" end]) \(.displayName)\n      \(.description)\n      Module: \(.moduleName)\n      Install with: setupx install \(.name)\n"'
}

invoke_script() {
    local script_name="$1"
    shift
    local script_args="$@"
    
    if [ -z "$script_name" ]; then
        echo "Error: Script name required"
        echo "Usage: setupx -sh <script-name> [arguments]"
        echo ""
        echo "Available scripts:"
        echo "  gcprootlogin    - Enable root login for GCP VM"
        echo "  system-update   - Update system packages"
        echo "  backup-system   - Create system backup"
        echo "  setcp           - Reset database passwords (PostgreSQL, MySQL, MongoDB)"
        echo "  nginx-domain    - Configure new domain in Nginx with SSL"
        echo "  pm2-deploy      - Deploy application with PM2 and port configuration"
        return 1
    fi
    
    # Check if script exists in scripts module
    local scripts_module=$(get_module_config "scripts")
    if [ -z "$scripts_module" ]; then
        echo "Error: Scripts module not found"
        return 1
    fi
    
    local script_component=$(echo "$scripts_module" | jq -r ".components.$script_name")
    if [ "$script_component" = "null" ] || [ -z "$script_component" ]; then
        echo "Error: Script '$script_name' not found"
        echo "Available scripts:"
        echo "$scripts_module" | jq -r '.components | to_entries[] | "  \(.key) - \(.value.displayName)"'
        return 1
    fi
    
    local display_name=$(echo "$script_component" | jq -r '.displayName')
    local description=$(echo "$script_component" | jq -r '.description')
    
    echo "Running script: $display_name"
    echo "Description: $description"
    echo ""
    
    # Handle specific scripts
    case "$script_name" in
        "gcprootlogin")
            if [ -f "$SCRIPT_DIR/gcprootlogin.sh" ]; then
                chmod +x "$SCRIPT_DIR/gcprootlogin.sh"
                "$SCRIPT_DIR/gcprootlogin.sh" $script_args
            else
                echo "Error: gcprootlogin.sh script not found"
                return 1
            fi
            ;;
        "system-update")
            echo "Running system update..."
            sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean
            echo "System update completed"
            ;;
        "backup-system")
            echo "Creating system backup..."
            local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
            sudo tar -czf "/tmp/${backup_name}.tar.gz" --exclude=/proc --exclude=/tmp --exclude=/mnt --exclude=/dev --exclude=/sys /
            echo "Backup created: /tmp/${backup_name}.tar.gz"
            ;;
        "setcp")
            if [ -f "$SCRIPT_DIR/setcp.sh" ]; then
                chmod +x "$SCRIPT_DIR/setcp.sh"
                "$SCRIPT_DIR/setcp.sh" $script_args
            else
                echo "Error: setcp.sh script not found"
                return 1
            fi
            ;;
        "nginx-domain")
            if [ -f "$SCRIPT_DIR/nginx-domain.sh" ]; then
                chmod +x "$SCRIPT_DIR/nginx-domain.sh"
                "$SCRIPT_DIR/nginx-domain.sh" $script_args
            else
                echo "Error: nginx-domain.sh script not found"
                return 1
            fi
            ;;
        "pm2-deploy")
            if [ -f "$SCRIPT_DIR/pm2-deploy.sh" ]; then
                chmod +x "$SCRIPT_DIR/pm2-deploy.sh"
                "$SCRIPT_DIR/pm2-deploy.sh" $script_args
            else
                echo "Error: pm2-deploy.sh script not found"
                return 1
            fi
            ;;
        *)
            echo "Error: Unknown script '$script_name'"
            return 1
            ;;
    esac
}

# Main command router
case "$1" in
    "help"|"-h"|"--help")
        show_help
        ;;
    "list")
        show_list
        ;;
    "list-all")
        show_list_all
        ;;
    "status")
        show_status
        ;;
    "install")
        invoke_install "$2"
        ;;
    "remove")
        invoke_remove "$2"
        ;;
    "update")
        component=$(get_component_by_name "$2")
        if [ -n "$component" ]; then
            invoke_component_command "$component" "update"
        fi
        ;;
    "check")
        invoke_check "$2"
        ;;
    "verify")
        component=$(get_component_by_name "$2")
        if [ -n "$component" ]; then
            invoke_component_command "$component" "verify"
        fi
        ;;
    "test")
        component=$(get_component_by_name "$2")
        if [ -n "$component" ]; then
            invoke_component_command "$component" "test"
        fi
        ;;
    "install-module")
        invoke_install_module "$2"
        ;;
    "list-module")
        invoke_list_module "$2"
        ;;
    "search")
        invoke_search "$2"
        ;;
    "version")
        local config_path="$SCRIPT_DIR/config.json"
        local version=$(jq -r '.version' "$config_path")
        local description=$(jq -r '.cli.banner.description' "$config_path")
        local author=$(jq -r '.author' "$config_path")
        local repository=$(jq -r '.repository' "$config_path")
        
        show_banner
        echo "SetupX Version: $version"
        echo "Architecture: $description"
        echo "Author: $author"
        echo "Repository: $repository"
        ;;
    "-sh"|"--script")
        invoke_script "$2" "${@:3}"
        ;;
    "")
        show_banner
        echo "Run 'setupx help' for usage information"
        echo ""
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'setupx help' for available commands"
        ;;
esac

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

# Fallback: if modules still not found, try the standard installation directory
if [ ! -f "$SCRIPT_DIR/src/utils/logger.sh" ]; then
    SCRIPT_DIR="/usr/local/lib/setupx"
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
    echo "    scripts                       List all available scripts"
    echo "    scripts-menu                  Scripts-only interactive menu"
    echo "    menu                          Interactive menu system"
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
    echo "    setupx scripts                # List all available scripts"
    echo "    setupx scripts-menu           # Scripts-only interactive menu"
    echo "    setupx menu                   # Interactive menu system"
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

invoke_list_scripts() {
    echo ""
    echo "Available Scripts:"
    echo "=================="
    
    local scripts_module=$(get_module_config "scripts")
    if [ "$scripts_module" != "null" ] && [ -n "$scripts_module" ]; then
        echo "$scripts_module" | jq -r '.components[] | "  \(.name) - \(.displayName)\n    \(.description)\n    Usage: \(.usage)\n"' 2>/dev/null || echo "  Error loading scripts from configuration"
    else
        echo "  Error: Scripts module not found"
        echo "  Make sure the scripts module is properly configured"
    fi
    
    echo ""
    echo "Use 'setupx -sh <script-name> [arguments]' to run a script"
    echo "Use 'setupx -sh' to see available scripts with descriptions"
}

invoke_interactive_menu() {
    while true; do
        clear
        show_banner
        echo ""
        echo "🚀 SetupX Interactive Menu"
        echo "=========================="
        echo ""
        echo "1) 📦 Install Components"
        echo "2) 🔧 Run Scripts"
        echo "3) 📋 List Modules"
        echo "4) 🔍 Search Components"
        echo "5) 📊 System Status"
        echo "6) ❓ Help"
        echo "7) 🚪 Exit"
        echo ""
        read -p "Select an option (1-7): " choice
        
        case $choice in
            1)
                menu_install_components
                ;;
            2)
                menu_run_scripts
                ;;
            3)
                menu_list_modules
                ;;
            4)
                menu_search_components
                ;;
            5)
                menu_system_status
                ;;
            6)
                show_help
                read -p "Press Enter to continue..."
                ;;
            7)
                echo ""
                echo "👋 Thank you for using SetupX!"
                echo "Run 'setupx help' for command-line usage"
                exit 0
                ;;
            *)
                echo "❌ Invalid option. Please select 1-7."
                sleep 2
                ;;
        esac
    done
}

menu_install_components() {
    while true; do
        clear
        echo "📦 Install Components"
        echo "===================="
        echo ""
        echo "1) 🏗️  Install by Module"
        echo "2) 🔧 Install Individual Component"
        echo "3) 📋 List Available Modules"
        echo "4) 🔙 Back to Main Menu"
        echo ""
        read -p "Select an option (1-4): " choice
        
        case $choice in
            1)
                menu_install_by_module
                ;;
            2)
                menu_install_individual
                ;;
            3)
                show_list
                read -p "Press Enter to continue..."
                ;;
            4)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-4."
                sleep 2
                ;;
        esac
    done
}

menu_install_by_module() {
    echo ""
    echo "Available Modules:"
    echo "=================="
    
    local modules=$(get_all_module_configs)
    local module_count=$(echo "$modules" | jq 'length')
    local i=1
    
    echo "$modules" | jq -r '.[] | "\(.name)|\(.displayName)|\(.description)"' | while IFS='|' read -r name display_name description; do
        echo "$i) $display_name"
        echo "   $description"
        echo ""
        i=$((i+1))
    done
    
    echo "$((module_count + 1))) 🔙 Back"
    echo ""
    read -p "Select module to install (1-$((module_count + 1))): " choice
    
    if [ "$choice" -eq "$((module_count + 1))" ]; then
        return
    fi
    
    local selected_module=$(echo "$modules" | jq -r ".[$((choice-1))].name" 2>/dev/null)
    if [ -n "$selected_module" ] && [ "$selected_module" != "null" ]; then
        echo ""
        echo "🚀 Installing module: $selected_module"
        invoke_install_module "$selected_module"
        read -p "Press Enter to continue..."
    else
        echo "❌ Invalid selection"
        sleep 2
    fi
}

menu_install_individual() {
    echo ""
    read -p "Enter component name to install: " component_name
    
    if [ -n "$component_name" ]; then
        echo ""
        echo "🚀 Installing component: $component_name"
        invoke_install "$component_name"
        read -p "Press Enter to continue..."
    else
        echo "❌ Component name required"
        sleep 2
    fi
}

menu_run_scripts() {
    while true; do
        clear
        echo "🔧 Run Scripts"
        echo "=============="
        echo ""
        echo "1) 📋 List All Scripts"
        echo "2) 🚀 Run Script by Name"
        echo "3) 🌐 Nginx Domain Setup (Guided)"
        echo "4) 🚀 PM2 Deployment (Guided)"
        echo "5) 🗄️ Database Management (Guided)"
        echo "6) 🔐 Security Setup (Guided)"
        echo "7) 🔙 Back to Main Menu"
        echo ""
        read -p "Select an option (1-7): " choice
        
        case $choice in
            1)
                invoke_list_scripts
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                read -p "Enter script name: " script_name
                if [ -n "$script_name" ]; then
                    echo ""
                    echo "🚀 Running script: $script_name"
                    invoke_script "$script_name"
                    read -p "Press Enter to continue..."
                else
                    echo "❌ Script name required"
                    sleep 2
                fi
                ;;
            3)
                menu_nginx_domain_guided
                ;;
            4)
                menu_pm2_deploy_guided
                ;;
            5)
                menu_database_guided
                ;;
            6)
                menu_security_guided
                ;;
            7)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-7."
                sleep 2
                ;;
        esac
    done
}

menu_list_modules() {
    clear
    show_list
    echo ""
    read -p "Enter module name to see details (or press Enter to go back): " module_name
    
    if [ -n "$module_name" ]; then
        invoke_list_module "$module_name"
        read -p "Press Enter to continue..."
    fi
}

menu_search_components() {
    echo ""
    read -p "Enter search query: " query
    
    if [ -n "$query" ]; then
        invoke_search "$query"
        read -p "Press Enter to continue..."
    else
        echo "❌ Search query required"
        sleep 2
    fi
}

menu_system_status() {
    clear
    echo "📊 System Status"
    echo "================"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "✅ Running as root"
    else
        echo "⚠️  Not running as root (some operations may require sudo)"
    fi
    
    # Check essential tools
    echo ""
    echo "🔧 Essential Tools:"
    for tool in curl wget git jq python3; do
        if command -v "$tool" >/dev/null 2>&1; then
            echo "  ✅ $tool"
        else
            echo "  ❌ $tool"
        fi
    done
    
    # Check SetupX installation
    echo ""
    echo "📦 SetupX Status:"
    if [ -f "$SCRIPT_DIR/config.json" ]; then
        echo "  ✅ Configuration loaded"
    else
        echo "  ❌ Configuration not found"
    fi
    
    if [ -f "$SCRIPT_DIR/setupx.sh" ]; then
        echo "  ✅ Main script found"
    else
        echo "  ❌ Main script not found"
    fi
    
    # Check modules
    local modules=$(get_all_module_configs)
    local module_count=$(echo "$modules" | jq 'length' 2>/dev/null || echo "0")
    echo "  📋 Modules available: $module_count"
    
    echo ""
    read -p "Press Enter to continue..."
}

menu_nginx_domain_guided() {
    clear
    echo "🌐 Nginx Domain Setup (Guided)"
    echo "==============================="
    echo ""
    echo "This will help you configure a new domain with Nginx and SSL."
    echo ""
    
    # Get domain name
    read -p "Enter domain name (e.g., example.com): " domain
    if [ -z "$domain" ]; then
        echo "❌ Domain name is required"
        sleep 2
        return
    fi
    
    # Get port
    read -p "Enter backend port (default: 3000): " port
    port=${port:-3000}
    
    # Ask for SSL
    echo ""
    echo "Do you want to enable SSL with Let's Encrypt? (y/n)"
    read -p "Enable SSL [y]: " ssl_choice
    ssl_choice=${ssl_choice:-y}
    
    # Build command
    local command="setupx -sh nginx-domain -d $domain -p $port"
    if [ "$ssl_choice" = "y" ] || [ "$ssl_choice" = "Y" ]; then
        command="$command -s"
    fi
    
    echo ""
    echo "🚀 Command to execute:"
    echo "$command"
    echo ""
    read -p "Execute this command? (y/n) [y]: " execute
    execute=${execute:-y}
    
    if [ "$execute" = "y" ] || [ "$execute" = "Y" ]; then
        echo ""
        echo "🌐 Setting up Nginx domain: $domain"
        eval "$command"
        read -p "Press Enter to continue..."
    else
        echo "❌ Command cancelled"
        sleep 2
    fi
}

menu_pm2_deploy_guided() {
    clear
    echo "🚀 PM2 Deployment (Guided)"
    echo "=========================="
    echo ""
    echo "This will help you deploy an application with PM2."
    echo ""
    
    # Get app name
    read -p "Enter application name (e.g., myapp): " app_name
    if [ -z "$app_name" ]; then
        echo "❌ Application name is required"
        sleep 2
        return
    fi
    
    # Get port
    read -p "Enter application port (default: 3000): " port
    port=${port:-3000}
    
    # Get directory
    read -p "Enter application directory (default: /var/www/$app_name): " directory
    directory=${directory:-/var/www/$app_name}
    
    # Get environment
    echo ""
    echo "Select environment:"
    echo "1) development"
    echo "2) production"
    echo "3) staging"
    read -p "Choose environment (1-3) [1]: " env_choice
    env_choice=${env_choice:-1}
    
    case $env_choice in
        1) environment="development" ;;
        2) environment="production" ;;
        3) environment="staging" ;;
        *) environment="development" ;;
    esac
    
    # Build command
    local command="setupx -sh pm2-deploy -n $app_name -p $port -d $directory -e $environment"
    
    echo ""
    echo "🚀 Command to execute:"
    echo "$command"
    echo ""
    read -p "Execute this command? (y/n) [y]: " execute
    execute=${execute:-y}
    
    if [ "$execute" = "y" ] || [ "$execute" = "Y" ]; then
        echo ""
        echo "🚀 Deploying application: $app_name"
        eval "$command"
        read -p "Press Enter to continue..."
    else
        echo "❌ Command cancelled"
        sleep 2
    fi
}

menu_database_guided() {
    while true; do
        clear
        echo "🗄️ Database Management (Guided)"
        echo "==============================="
        echo ""
        echo "1) 📦 Install Database"
        echo "2) 🔄 Reset Database Password"
        echo "3) 💾 Create Database Backup"
        echo "4) 📊 Check Database Status"
        echo "5) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-5): " choice
        
        case $choice in
            1)
                menu_database_install_guided
                ;;
            2)
                menu_database_reset_guided
                ;;
            3)
                menu_database_backup_guided
                ;;
            4)
                echo ""
                echo "📊 Checking database status..."
                invoke_script "database-status"
                read -p "Press Enter to continue..."
                ;;
            5)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-5."
                sleep 2
                ;;
        esac
    done
}

menu_database_install_guided() {
    clear
    echo "📦 Install Database (Guided)"
    echo "============================"
    echo ""
    echo "Available databases:"
    echo "1) PostgreSQL"
    echo "2) MySQL"
    echo "3) MariaDB"
    echo "4) MongoDB"
    echo "5) Redis"
    echo "6) Cassandra"
    echo "7) Elasticsearch"
    echo "8) Neo4j"
    echo "9) InfluxDB"
    echo "10) CouchDB"
    echo "11) SQLite"
    echo ""
    read -p "Select database (1-11): " db_choice
    
    case $db_choice in
        1) db_type="postgresql" ;;
        2) db_type="mysql" ;;
        3) db_type="mariadb" ;;
        4) db_type="mongodb" ;;
        5) db_type="redis" ;;
        6) db_type="cassandra" ;;
        7) db_type="elasticsearch" ;;
        8) db_type="neo4j" ;;
        9) db_type="influxdb" ;;
        10) db_type="couchdb" ;;
        11) db_type="sqlite" ;;
        *)
            echo "❌ Invalid selection"
            sleep 2
            return
            ;;
    esac
    
    echo ""
    echo "🚀 Installing $db_type..."
    invoke_script "database-manager" "install-$db_type"
    read -p "Press Enter to continue..."
}

menu_database_reset_guided() {
    clear
    echo "🔄 Reset Database Password (Guided)"
    echo "==================================="
    echo ""
    echo "Available databases:"
    echo "1) PostgreSQL"
    echo "2) MySQL"
    echo "3) MariaDB"
    echo "4) MongoDB"
    echo "5) Redis"
    echo ""
    read -p "Select database (1-5): " db_choice
    
    case $db_choice in
        1) db_type="postgresql" ;;
        2) db_type="mysql" ;;
        3) db_type="mariadb" ;;
        4) db_type="mongodb" ;;
        5) db_type="redis" ;;
        *)
            echo "❌ Invalid selection"
            sleep 2
            return
            ;;
    esac
    
    read -p "Enter new password (default: ${db_type}123): " new_password
    new_password=${new_password:-${db_type}123}
    
    echo ""
    echo "🔄 Resetting $db_type password..."
    invoke_script "database-reset" "$db_type" "$new_password"
    read -p "Press Enter to continue..."
}

menu_database_backup_guided() {
    clear
    echo "💾 Create Database Backup (Guided)"
    echo "=================================="
    echo ""
    echo "Available databases:"
    echo "1) PostgreSQL"
    echo "2) MySQL"
    echo "3) MongoDB"
    echo ""
    read -p "Select database (1-3): " db_choice
    
    case $db_choice in
        1) db_type="postgresql" ;;
        2) db_type="mysql" ;;
        3) db_type="mongodb" ;;
        *)
            echo "❌ Invalid selection"
            sleep 2
            return
            ;;
    esac
    
    echo ""
    echo "💾 Creating $db_type backup..."
    invoke_script "database-backup" "$db_type"
    read -p "Press Enter to continue..."
}

menu_security_guided() {
    while true; do
        clear
        echo "🔐 Security Setup (Guided)"
        echo "==========================="
        echo ""
        echo "1) 🔑 Enable SSH Root Login"
        echo "2) 🛡️ Setup UFW Firewall"
        echo "3) 🚫 Install Fail2Ban"
        echo "4) 🔒 Setup SSL Certificate"
        echo "5) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-5): " choice
        
        case $choice in
            1)
                menu_ssh_root_guided
                ;;
            2)
                echo ""
                echo "🛡️ Setting up UFW firewall..."
                invoke_script "system-security" "ufw"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo "🚫 Installing Fail2Ban..."
                invoke_script "system-security" "fail2ban"
                read -p "Press Enter to continue..."
                ;;
            4)
                menu_ssl_guided
                ;;
            5)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-5."
                sleep 2
                ;;
        esac
    done
}

menu_ssh_root_guided() {
    clear
    echo "🔑 Enable SSH Root Login (Guided)"
    echo "================================="
    echo ""
    read -p "Enter root password: " root_password
    if [ -z "$root_password" ]; then
        echo "❌ Root password is required"
        sleep 2
        return
    fi
    
    echo ""
    echo "🔑 Enabling SSH root login..."
    invoke_script "final-ssh-root-login" "-p" "$root_password"
    read -p "Press Enter to continue..."
}

menu_ssl_guided() {
    clear
    echo "🔒 Setup SSL Certificate (Guided)"
    echo "================================="
    echo ""
    read -p "Enter domain name (e.g., example.com): " domain
    if [ -z "$domain" ]; then
        echo "❌ Domain name is required"
        sleep 2
        return
    fi
    
    echo ""
    echo "Include www subdomain? (y/n)"
    read -p "Include www [y]: " include_www
    include_www=${include_www:-y}
    
    local command="setupx -sh ssl-setup -d $domain"
    if [ "$include_www" = "n" ] || [ "$include_www" = "N" ]; then
        command="$command --no-www"
    fi
    
    echo ""
    echo "🔒 Command to execute:"
    echo "$command"
    echo ""
    read -p "Execute this command? (y/n) [y]: " execute
    execute=${execute:-y}
    
    if [ "$execute" = "y" ] || [ "$execute" = "Y" ]; then
        echo ""
        echo "🔒 Setting up SSL for: $domain"
        eval "$command"
        read -p "Press Enter to continue..."
    else
        echo "❌ Command cancelled"
        sleep 2
    fi
}

invoke_scripts_menu() {
    while true; do
        clear
        show_banner
        echo ""
        echo "🔧 SetupX Scripts Menu"
        echo "======================"
        echo ""
        echo "1) 🌐 Nginx Domain Setup"
        echo "2) 🚀 PM2 Deployment"
        echo "3) 🗄️ Database Management"
        echo "4) 🔐 Security Setup"
        echo "5) 📊 System Administration"
        echo "6) 🔧 Development Tools"
        echo "7) 📋 List All Scripts"
        echo "8) 🔙 Back to Main Menu"
        echo ""
        read -p "Select a script category (1-8): " choice
        
        case $choice in
            1)
                menu_nginx_scripts
                ;;
            2)
                menu_pm2_scripts
                ;;
            3)
                menu_database_scripts
                ;;
            4)
                menu_security_scripts
                ;;
            5)
                menu_system_scripts
                ;;
            6)
                menu_development_scripts
                ;;
            7)
                invoke_list_scripts
                read -p "Press Enter to continue..."
                ;;
            8)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-8."
                sleep 2
                ;;
        esac
    done
}

menu_nginx_scripts() {
    while true; do
        clear
        echo "🌐 Nginx Scripts"
        echo "================"
        echo ""
        echo "1) 🌐 Setup Nginx Domain (Guided)"
        echo "2) 🔒 Setup SSL Certificate (Guided)"
        echo "3) 📋 List Nginx Scripts"
        echo "4) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-4): " choice
        
        case $choice in
            1)
                menu_nginx_domain_guided
                ;;
            2)
                menu_ssl_guided
                ;;
            3)
                echo ""
                echo "🌐 Available Nginx Scripts:"
                echo "  - nginx-domain: Configure Nginx domain with SSL"
                echo "  - ssl-setup: Setup SSL certificates with Let's Encrypt"
                read -p "Press Enter to continue..."
                ;;
            4)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-4."
                sleep 2
                ;;
        esac
    done
}

menu_pm2_scripts() {
    while true; do
        clear
        echo "🚀 PM2 Scripts"
        echo "=============="
        echo ""
        echo "1) 🚀 PM2 Deployment (Guided)"
        echo "2) 📦 Deploy from Git (Guided)"
        echo "3) 📋 List PM2 Scripts"
        echo "4) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-4): " choice
        
        case $choice in
            1)
                menu_pm2_deploy_guided
                ;;
            2)
                menu_pm2_git_guided
                ;;
            3)
                echo ""
                echo "🚀 Available PM2 Scripts:"
                echo "  - pm2-deploy: Deploy application with PM2"
                echo "  - deploy-node-git: Deploy Node.js app from Git repository"
                read -p "Press Enter to continue..."
                ;;
            4)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-4."
                sleep 2
                ;;
        esac
    done
}

menu_pm2_git_guided() {
    clear
    echo "📦 Deploy from Git (Guided)"
    echo "==========================="
    echo ""
    echo "This will help you deploy a Node.js application from a Git repository."
    echo ""
    
    # Get web name
    read -p "Enter web application name (e.g., myapp): " web_name
    if [ -z "$web_name" ]; then
        echo "❌ Web application name is required"
        sleep 2
        return
    fi
    
    # Get app name
    read -p "Enter PM2 application name (e.g., myapp-pm2): " app_name
    app_name=${app_name:-${web_name}-pm2}
    
    # Get git URL
    read -p "Enter Git repository URL: " git_url
    if [ -z "$git_url" ]; then
        echo "❌ Git repository URL is required"
        sleep 2
        return
    fi
    
    # Get port
    read -p "Enter application port (default: 3000): " port
    port=${port:-3000}
    
    # Build command
    local command="setupx -sh deploy-node-git -w $web_name -a $app_name -g $git_url -p $port"
    
    echo ""
    echo "📦 Command to execute:"
    echo "$command"
    echo ""
    read -p "Execute this command? (y/n) [y]: " execute
    execute=${execute:-y}
    
    if [ "$execute" = "y" ] || [ "$execute" = "Y" ]; then
        echo ""
        echo "📦 Deploying from Git: $web_name"
        eval "$command"
        read -p "Press Enter to continue..."
    else
        echo "❌ Command cancelled"
        sleep 2
    fi
}

menu_database_scripts() {
    while true; do
        clear
        echo "🗄️ Database Scripts"
        echo "==================="
        echo ""
        echo "1) 📦 Install Database"
        echo "2) 🔄 Reset Database Password"
        echo "3) 💾 Create Database Backup"
        echo "4) 📊 Check Database Status"
        echo "5) 🔧 Database Manager"
        echo "6) 📋 List Database Scripts"
        echo "7) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-7): " choice
        
        case $choice in
            1)
                menu_database_install_guided
                ;;
            2)
                menu_database_reset_guided
                ;;
            3)
                menu_database_backup_guided
                ;;
            4)
                echo ""
                echo "📊 Checking database status..."
                invoke_script "database-status"
                read -p "Press Enter to continue..."
                ;;
            5)
                menu_database_manager_guided
                ;;
            6)
                echo ""
                echo "🗄️ Available Database Scripts:"
                echo "  - database-manager: Comprehensive database management"
                echo "  - database-reset: Reset database passwords"
                echo "  - database-backup: Create database backups"
                echo "  - database-status: Check database status"
                echo "  - setcp: Database password manager"
                echo "  - reset-postgres: Reset PostgreSQL database"
                echo "  - reset-mysql: Reset MySQL database"
                echo "  - reset-mongodb: Reset MongoDB database"
                read -p "Press Enter to continue..."
                ;;
            7)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-7."
                sleep 2
                ;;
        esac
    done
}

menu_database_manager_guided() {
    clear
    echo "🔧 Database Manager (Guided)"
    echo "==========================="
    echo ""
    echo "Available database actions:"
    echo "1) Install PostgreSQL"
    echo "2) Install MySQL"
    echo "3) Install MariaDB"
    echo "4) Install MongoDB"
    echo "5) Install Redis"
    echo "6) Install Cassandra"
    echo "7) Install Elasticsearch"
    echo "8) Install Neo4j"
    echo "9) Install InfluxDB"
    echo "10) Install CouchDB"
    echo "11) Install SQLite"
    echo "12) Install Database Tools"
    echo ""
    read -p "Select database action (1-12): " action_choice
    
    case $action_choice in
        1) action="install-postgresql" ;;
        2) action="install-mysql" ;;
        3) action="install-mariadb" ;;
        4) action="install-mongodb" ;;
        5) action="install-redis" ;;
        6) action="install-cassandra" ;;
        7) action="install-elasticsearch" ;;
        8) action="install-neo4j" ;;
        9) action="install-influxdb" ;;
        10) action="install-couchdb" ;;
        11) action="install-sqlite" ;;
        12) action="install-tools" ;;
        *)
            echo "❌ Invalid selection"
            sleep 2
            return
            ;;
    esac
    
    echo ""
    echo "🔧 Executing database manager: $action"
    invoke_script "database-manager" "$action"
    read -p "Press Enter to continue..."
}

menu_security_scripts() {
    while true; do
        clear
        echo "🔐 Security Scripts"
        echo "=================="
        echo ""
        echo "1) 🔑 Enable SSH Root Login"
        echo "2) 🛡️ Setup UFW Firewall"
        echo "3) 🚫 Install Fail2Ban"
        echo "4) 🔒 Setup SSL Certificate"
        echo "5) 📋 List Security Scripts"
        echo "6) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-6): " choice
        
        case $choice in
            1)
                menu_ssh_root_guided
                ;;
            2)
                echo ""
                echo "🛡️ Setting up UFW firewall..."
                invoke_script "system-security" "ufw"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo "🚫 Installing Fail2Ban..."
                invoke_script "system-security" "fail2ban"
                read -p "Press Enter to continue..."
                ;;
            4)
                menu_ssl_guided
                ;;
            5)
                echo ""
                echo "🔐 Available Security Scripts:"
                echo "  - final-ssh-root-login: Enable SSH root login"
                echo "  - ssl-setup: Setup SSL certificates"
                echo "  - system-security: UFW firewall and Fail2Ban"
                read -p "Press Enter to continue..."
                ;;
            6)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-6."
                sleep 2
                ;;
        esac
    done
}

menu_system_scripts() {
    while true; do
        clear
        echo "📊 System Administration Scripts"
        echo "==============================="
        echo ""
        echo "1) 🔄 System Update"
        echo "2) 💾 System Backup"
        echo "3) 📊 System Status"
        echo "4) 🔧 PostgreSQL Remote Setup"
        echo "5) 📋 List System Scripts"
        echo "6) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-6): " choice
        
        case $choice in
            1)
                echo ""
                echo "🔄 Updating system..."
                invoke_script "update-all" "-y"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo "💾 Creating system backup..."
                invoke_script "backup-system"
                read -p "Press Enter to continue..."
                ;;
            3)
                menu_system_status
                ;;
            4)
                menu_postgres_remote_guided
                ;;
            5)
                echo ""
                echo "📊 Available System Scripts:"
                echo "  - update-all: Update all system packages"
                echo "  - backup-system: Create system backup"
                echo "  - postgres-remote: Configure PostgreSQL for remote access"
                read -p "Press Enter to continue..."
                ;;
            6)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-6."
                sleep 2
                ;;
        esac
    done
}

menu_postgres_remote_guided() {
    clear
    echo "🔧 PostgreSQL Remote Setup (Guided)"
    echo "==================================="
    echo ""
    read -p "Enter PostgreSQL port (default: 5432): " port
    port=${port:-5432}
    
    read -p "Enter allowed IP addresses (default: 0.0.0.0/0): " allowed_ips
    allowed_ips=${allowed_ips:-0.0.0.0/0}
    
    local command="setupx -sh postgres-remote -p $port -i $allowed_ips"
    
    echo ""
    echo "🔧 Command to execute:"
    echo "$command"
    echo ""
    read -p "Execute this command? (y/n) [y]: " execute
    execute=${execute:-y}
    
    if [ "$execute" = "y" ] || [ "$execute" = "Y" ]; then
        echo ""
        echo "🔧 Setting up PostgreSQL remote access..."
        eval "$command"
        read -p "Press Enter to continue..."
    else
        echo "❌ Command cancelled"
        sleep 2
    fi
}

menu_development_scripts() {
    while true; do
        clear
        echo "🔧 Development Tools Scripts"
        echo "==========================="
        echo ""
        echo "1) 📦 Install Development Stack"
        echo "2) 🐳 Docker Setup"
        echo "3) ☸️ Kubernetes Setup"
        echo "4) 📋 List Development Scripts"
        echo "5) 🔙 Back to Scripts Menu"
        echo ""
        read -p "Select an option (1-5): " choice
        
        case $choice in
            1)
                echo ""
                echo "📦 Installing development stack..."
                invoke_script "install-module" "web-development"
                read -p "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo "🐳 Setting up Docker..."
                invoke_script "install" "docker"
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                echo "☸️ Setting up Kubernetes..."
                invoke_script "install" "kubectl"
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo "🔧 Available Development Scripts:"
                echo "  - web-development: Complete web development stack"
                echo "  - docker: Container platform"
                echo "  - kubectl: Kubernetes command-line tool"
                read -p "Press Enter to continue..."
                ;;
            5)
                return
                ;;
            *)
                echo "❌ Invalid option. Please select 1-5."
                sleep 2
                ;;
        esac
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
        
        # Get scripts from JSON configuration
        local scripts_module=$(get_module_config "scripts")
        if [ "$scripts_module" != "null" ]; then
            echo "$scripts_module" | jq -r '.components[] | "  \(.name) - \(.description)"' 2>/dev/null || echo "  Error loading scripts from configuration"
        else
            echo "  Error: Scripts module not found"
        fi
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
    "scripts")
        invoke_list_scripts
        ;;
    "menu")
        invoke_interactive_menu
        ;;
    "scripts-menu")
        invoke_scripts_menu
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

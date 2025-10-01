# SetupX JSON-Driven Architecture

## Overview

SetupX now uses a **JSON-driven architecture** that minimizes PowerShell script files and stores all component data, commands, and configurations in modular JSON files.

## Architecture Benefits

✅ **Minimal Scripts** - Only 6 core PowerShell files instead of 68+ component scripts  
✅ **Data-Driven** - All component logic stored in easily editable JSON files  
✅ **Modular** - Each module has its own JSON file for easy management  
✅ **Easy to Extend** - Add new components by editing JSON, no scripting required  
✅ **Consistent** - All components follow the same command structure  
✅ **Maintainable** - Update commands without touching PowerShell code  

---

## Directory Structure

```
setupx-windows-setup/
├── setupx-new.ps1              # Main CLI (JSON-driven)
├── src/
│   ├── core/
│   │   ├── engine.ps1          # Command executor (reads & executes JSON commands)
│   │   └── json-loader.ps1     # JSON configuration loader
│   ├── utils/
│   │   ├── logger.ps1          # Logging utilities
│   │   └── helpers.ps1         # Helper functions
│   └── config/
│       ├── setupx.json         # Main configuration (optional)
│       └── modules/            # Modular JSON files (one per module)
│           ├── package-managers.json
│           ├── web-development.json
│           ├── common-development.json
│           ├── backend-development.json
│           ├── cloud-development.json
│           ├── mobile-development.json
│           ├── data-science.json
│           ├── devops.json
│           └── wsl-linux.json
```

**Total Files:** 6 PowerShell scripts + 9 JSON files = 15 files total  
**Previous Architecture:** 87+ files

---

## JSON Module Structure

Each module JSON file follows this structure:

```json
{
  "name": "module-name",
  "displayName": "Human Readable Name",
  "description": "Module description",
  "category": "development",
  "priority": 1,
  "status": "fully-working",
  "components": {
    "component-name": {
      "name": "component-name",
      "displayName": "Component Display Name",
      "description": "Component description",
      "installMethod": "chocolatey",
      "website": "https://example.com",
      "status": "working",
      "category": "category-name",
      "commands": {
        "install": "command to install",
        "remove": "command to remove",
        "update": "command to update",
        "check": "command to check if installed",
        "verify": "command to verify installation",
        "test": "command to test functionality",
        "path": "command to refresh PATH (optional)"
      }
    }
  }
}
```

---

## Component Commands

Each component can have these command types:

| Command | Purpose | Required |
|---------|---------|----------|
| `install` | Install the component | ✅ Yes |
| `remove` | Uninstall the component | ⚠️ Recommended |
| `update` | Update to latest version | ⚠️ Recommended |
| `check` | Check if installed | ✅ Yes |
| `verify` | Verify installation details | ❌ Optional |
| `test` | Test functionality | ❌ Optional |
| `path` | Refresh environment PATH | ❌ Optional |

Commands are standard PowerShell or system commands stored as strings in JSON.

---

## CLI Usage

### Basic Commands

```powershell
# Show help
.\setupx-new.ps1 help

# List all modules
.\setupx-new.ps1 list

# List all components
.\setupx-new.ps1 list-all

# Show system status
.\setupx-new.ps1 status

# Install a component
.\setupx-new.ps1 install chocolatey
.\setupx-new.ps1 install nodejs
.\setupx-new.ps1 install git

# Check if installed
.\setupx-new.ps1 check nodejs

# Remove a component
.\setupx-new.ps1 remove nodejs

# Update a component
.\setupx-new.ps1 update nodejs

# Search for components
.\setupx-new.ps1 search docker
.\setupx-new.ps1 search python
```

### Module Commands

```powershell
# List components in a module
.\setupx-new.ps1 list-module web-development

# Install all components in a module
.\setupx-new.ps1 install-module package-managers
.\setupx-new.ps1 install-module web-development
.\setupx-new.ps1 install-module common-development
```

---

## How It Works

### 1. **JSON Loading**
- `json-loader.ps1` reads all JSON files from `src/config/modules/`
- Parses and loads component definitions into memory
- No script files needed for each component

### 2. **Command Execution**
- `engine.ps1` receives component object and action (install/remove/update)
- Reads the command string from JSON
- Executes using `Invoke-Expression`
- Handles success/failure and logging

### 3. **CLI Routing**
- `setupx-new.ps1` parses user commands
- Routes to appropriate functions
- Uses engine to execute component commands from JSON

### Flow Diagram

```
User Input
    ↓
CLI Parser (setupx-new.ps1)
    ↓
JSON Loader (json-loader.ps1) → Loads module JSONs
    ↓
Engine (engine.ps1) → Gets component & command
    ↓
Invoke-Expression → Executes command string
    ↓
Logger → Shows results
```

---

## Adding New Components

### Option 1: Add to Existing Module

Edit the module JSON file (e.g., `web-development.json`):

```json
{
  "components": {
    "new-component": {
      "name": "new-component",
      "displayName": "New Component",
      "description": "Description here",
      "installMethod": "chocolatey",
      "website": "https://example.com",
      "status": "working",
      "category": "web-development",
      "commands": {
        "install": "choco install new-component -y",
        "remove": "choco uninstall new-component -y",
        "update": "choco upgrade new-component -y",
        "check": "new-component --version"
      }
    }
  }
}
```

### Option 2: Create New Module

Create a new JSON file in `src/config/modules/`:

`src/config/modules/my-module.json`:

```json
{
  "name": "my-module",
  "displayName": "My Module",
  "description": "My custom module",
  "category": "development",
  "priority": 10,
  "status": "available",
  "components": {
    "my-component": {
      "name": "my-component",
      "displayName": "My Component",
      "description": "Custom component",
      "commands": {
        "install": "choco install my-component -y",
        "check": "my-component --version"
      }
    }
  }
}
```

No PowerShell coding required!

---

## Available Modules

| Module | Components | Status |
|--------|-----------|--------|
| package-managers | 3 | ✅ Working |
| web-development | 7 | ✅ Working |
| common-development | 4 | ✅ Working |
| backend-development | 4 | ✅ Working |
| cloud-development | 5 | ✅ Working |
| mobile-development | 3 | ✅ Working |
| data-science | 4 | ✅ Working |
| devops | 3 | ✅ Working |
| wsl-linux | 3 | ✅ Working |

**Total: 36 components across 9 modules**

---

## Command Examples

### Install Development Environment

```powershell
# Quick setup
.\setupx-new.ps1 install-module package-managers
.\setupx-new.ps1 install-module common-development

# Full stack developer
.\setupx-new.ps1 install chocolatey
.\setupx-new.ps1 install nodejs
.\setupx-new.ps1 install git
.\setupx-new.ps1 install vscode
.\setupx-new.ps1 install docker
.\setupx-new.ps1 install python

# Check status
.\setupx-new.ps1 status

# Verify installations
.\setupx-new.ps1 check nodejs
.\setupx-new.ps1 check git
.\setupx-new.ps1 check python
```

### Search and Install

```powershell
# Find components
.\setupx-new.ps1 search flutter
.\setupx-new.ps1 search aws
.\setupx-new.ps1 search jupyter

# Install found components
.\setupx-new.ps1 install flutter
.\setupx-new.ps1 install aws-cli
.\setupx-new.ps1 install jupyter
```

---

## Extending the System

### Add Custom Commands

You can add any PowerShell command to the JSON:

```json
"commands": {
  "install": "iwr https://example.com/install.ps1 | iex",
  "custom-action": "Write-Host 'Custom action'; Get-Process"
}
```

### Multi-Step Commands

Use semicolons for multiple commands:

```json
"install": "choco install tool -y; refreshenv; tool --init"
```

### Conditional Commands

```json
"install": "if (-not (Get-Command tool)) { choco install tool -y }"
```

---

## Migration from Old Architecture

If you have the old script-based architecture:

1. **Keep using `setupx-new.ps1`** for JSON-driven approach
2. **Old `setupx.ps1`** still works with flat `setupx.json`
3. **Gradually migrate** components to module JSONs

Both systems can coexist!

---

## Advantages Over Script-Based Approach

| Aspect | Script-Based | JSON-Driven |
|--------|-------------|-------------|
| Files to maintain | 68+ scripts | 9 JSON files |
| Add component | Write .ps1 script | Edit JSON |
| Update command | Edit .ps1 file | Edit JSON string |
| Learning curve | PowerShell required | JSON editing |
| Consistency | Manual | Enforced by structure |
| Version control | Large diffs | Small JSON diffs |
| Testing | Test each script | Test engine once |

---

## Testing

Test the new system:

```powershell
# Test help
.\setupx-new.ps1 help

# Test listing
.\setupx-new.ps1 list
.\setupx-new.ps1 list-all
.\setupx-new.ps1 list-module web-development

# Test installation (safe: just chocolatey check)
.\setupx-new.ps1 check chocolatey

# Test search
.\setupx-new.ps1 search node

# Test status
.\setupx-new.ps1 status
```

---

## Troubleshooting

### JSON Syntax Errors

```powershell
# Test JSON validity
Get-Content src/config/modules/module-name.json | ConvertFrom-Json
```

### Component Not Found

```powershell
# List all components
.\setupx-new.ps1 list-all

# Search for component
.\setupx-new.ps1 search component-name
```

### Command Execution Failures

- Check `$LASTEXITCODE` in commands
- Verify command exists in PATH
- Test command manually first

---

## Future Enhancements

- [ ] Remote JSON loading from GitHub
- [ ] JSON schema validation
- [ ] Component dependencies in JSON
- [ ] Pre/post install hooks
- [ ] Custom module repositories
- [ ] JSON-based configuration management
- [ ] Component versioning in JSON

---

## Summary

**Before:** 87+ files (4 core + 2 utils + 68+ component scripts + 13 module dirs)  
**After:** 15 files (6 scripts + 9 JSON files)

**Result:** 83% fewer files, easier maintenance, more flexibility!

---

## Quick Start

```powershell
# 1. Navigate to project
cd C:\Users\aypc\setupx-windows-setup

# 2. Run CLI
.\setupx-new.ps1 help

# 3. List available components
.\setupx-new.ps1 list-all

# 4. Install something
.\setupx-new.ps1 install chocolatey

# 5. Check status
.\setupx-new.ps1 status
```

**That's it! No complex setup, just JSON configuration!** 🎉


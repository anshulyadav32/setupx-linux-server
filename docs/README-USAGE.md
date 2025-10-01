# SetupX - Windows Development Setup Tool

**Version:** 2.0.0  
**Author:** anshulyadav32

Individual Component Windows Development Setup Tool with PowerShell commands

## Quick Start

### Using SetupX (Full Command)

```powershell
# List all available components
.\setupx.ps1 list

# Check status of all components
.\setupx.ps1 status

# Install a component
.\setupx.ps1 install chocolatey

# Check if a component is installed
.\setupx.ps1 check git

# Update a component
.\setupx.ps1 update nodejs

# Remove a component
.\setupx.ps1 remove python
```

### Using WSX (Short Alias)

```powershell
# Same commands with shorter alias
.\wsx.ps1 list
.\wsx.ps1 status
.\wsx.ps1 install nodejs
.\wsx.ps1 check docker
```

## Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `list` | List all available components | `.\setupx.ps1 list` |
| `status` | Check status of all components | `.\setupx.ps1 status` |
| `install [component]` | Install a specific component | `.\setupx.ps1 install chocolatey` |
| `remove [component]` | Remove/uninstall a component | `.\setupx.ps1 remove nodejs` |
| `update [component]` | Update component to latest version | `.\setupx.ps1 update git` |
| `check [component]` | Check if component is installed | `.\setupx.ps1 check python` |
| `verify [component]` | Verify component installation | `.\setupx.ps1 verify docker` |
| `test [component]` | Test component functionality | `.\setupx.ps1 test terraform` |
| `refresh` | Refresh environment variables | `.\setupx.ps1 refresh` |
| `help` | Show help message | `.\setupx.ps1 help` |

## Available Components

### Package Managers
- **chocolatey** - Community package manager for Windows
- **scoop** - Portable applications manager for development tools
- **winget** - Microsoft's official Windows package manager

### Web Development
- **nodejs** - JavaScript runtime and package manager
- **yarn** - Fast, reliable, and secure dependency management

### Common Development
- **git** - Distributed version control system
- **vscode** - Lightweight, powerful source code editor

### Backend Development
- **python** - Python programming language and pip package manager
- **docker** - Containerization platform for applications

### Cloud Development
- **aws-cli** - Command line interface for Amazon Web Services
- **azure-cli** - Command line interface for Microsoft Azure

### Mobile Development
- **flutter** - Google's UI toolkit for building natively compiled applications
- **react-native** - Framework for building native apps with React

### Data Science
- **jupyter** - Interactive computing environment for data science
- **tensorflow** - Machine learning framework

### Game Development
- **unity** - Cross-platform game engine

### DevOps
- **terraform** - Infrastructure as code tool

### Security
- **nmap** - Network discovery and security auditing tool

### WSL Linux
- **wsl** - Windows Subsystem for Linux 2 with Ubuntu

## Common Workflows

### Quick Setup (Essential Tools)
```powershell
.\setupx.ps1 install chocolatey
.\setupx.ps1 install git
.\setupx.ps1 install vscode
.\setupx.ps1 status
```

### Full Stack Developer Setup
```powershell
.\setupx.ps1 install chocolatey
.\setupx.ps1 install nodejs
.\setupx.ps1 install git
.\setupx.ps1 install vscode
.\setupx.ps1 install docker
.\setupx.ps1 status
```

### Mobile Developer Setup
```powershell
.\setupx.ps1 install chocolatey
.\setupx.ps1 install flutter
.\setupx.ps1 install react-native
.\setupx.ps1 install git
.\setupx.ps1 install vscode
.\setupx.ps1 status
```

### Cloud Developer Setup
```powershell
.\setupx.ps1 install chocolatey
.\setupx.ps1 install aws-cli
.\setupx.ps1 install azure-cli
.\setupx.ps1 install docker
.\setupx.ps1 install terraform
.\setupx.ps1 status
```

### Data Scientist Setup
```powershell
.\setupx.ps1 install chocolatey
.\setupx.ps1 install python
.\setupx.ps1 install jupyter
.\setupx.ps1 install tensorflow
.\setupx.ps1 install git
.\setupx.ps1 status
```

## Features

✅ **Individual Component System** - Install, update, or remove components independently  
✅ **Automatic Environment Refresh** - PATH and environment variables refreshed after every command  
✅ **Component Status Checking** - Verify installations with version information  
✅ **PowerShell Commands** - Direct PowerShell commands for each operation  
✅ **Comprehensive Testing** - Test component functionality after installation  
✅ **Color-Coded Output** - Easy-to-read status messages with colors  
✅ **Error Handling** - Graceful error handling with detailed messages  

## How It Works

Each component has comprehensive PowerShell commands for:

1. **install** - Installation command
2. **remove** - Uninstallation command
3. **update** - Update to latest version
4. **check** - Check if component is installed
5. **verify** - Verify installation and configuration
6. **test** - Test component functionality
7. **path** - Refresh environment variables

After every command, the environment is automatically refreshed to ensure PATH and other variables are up-to-date.

## Configuration

All component configurations are stored in `src/config/setupx.json`

Each component includes:
- Name and display name
- Description
- Installation method
- Website
- Status
- Category
- Complete set of PowerShell commands

## Testing

A comprehensive test suite is available in `test.json` with:
- Individual component tests
- Test suites by category
- Test steps with expected outputs
- Cleanup procedures

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Internet connection (for installation)
- Optional: Administrator privileges (some components work better as regular user)

## Tips

1. **Always run** `.\setupx.ps1 status` after installations to verify
2. **Use** `.\setupx.ps1 refresh` if commands aren't recognized after installation
3. **Check individual components** with `.\setupx.ps1 check [component]` for detailed version info
4. **Update components regularly** with `.\setupx.ps1 update [component]`
5. **Use the short alias** `wsx.ps1` for quicker commands

## Troubleshooting

### Command not found after installation
```powershell
.\setupx.ps1 refresh
# Or restart your PowerShell terminal
```

### Component check fails but it's installed
- Restart your terminal
- Run `.\setupx.ps1 refresh`
- Check PATH manually with `$env:PATH`

### Installation fails
- Check internet connection
- Run PowerShell as Administrator
- Check component website for specific requirements

## Support

- **Issues:** https://github.com/anshulyadav32/setupx-windows-setup/issues
- **Documentation:** https://github.com/anshulyadav32/setupx-windows-setup/wiki
- **Discussions:** https://github.com/anshulyadav32/setupx-windows-setup/discussions

## License

MIT License - See LICENSE file for details

---

**Made with ❤️ by anshulyadav32**



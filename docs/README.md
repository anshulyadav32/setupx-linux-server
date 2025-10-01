# SetupX Documentation

## Overview
SetupX is a modular Linux development environment setup tool with JSON-driven architecture.

## Features
- **Component Installation**: Install development tools and packages
- **Script Execution**: Run deployment and configuration scripts
- **Module Management**: Organize tools by categories
- **JSON Configuration**: All data stored in JSON format

## CLI Commands

### Main Commands
- `setupx install <component>` - Install a component
- `setupx check <component>` - Check if component is installed
- `setupx test <component>` - Test a component
- `setupx list` - List all components
- `setupx list-module <module>` - List components in a module
- `setupx status` - Show system status
- `setupx -sh <script> [args]` - Run a script with arguments

### Short Alias
- `slx` - Short alias for all setupx commands

## Available Scripts
- `final-ssh-root-login` - SSH root login configuration
- `install-postgres` - PostgreSQL installation
- `deploy-node-app` - Node.js app deployment
- `nginx-domain` - Nginx domain setup
- `pm2-deploy` - PM2 deployment
- `setcp` - Database password reset

## Installation
```bash
./install.sh
```

## Usage Examples
```bash
# Install components
setupx install curl
slx install nodejs

# Run scripts
setupx -sh final-ssh-root-login -p passwordroot
slx -sh deploy-node-app

# Check status
setupx status
```

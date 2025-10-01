# SetupX Directory Structure

## Clean Modular Architecture

```
setupx-linux-server/
├── setupx                    # Main CLI command
├── slx                       # Short alias
├── config.json              # Main configuration (JSON-driven)
├── README.md                 # Project documentation
├── scripts/                  # All executable scripts
│   ├── deploy-node-app.sh
│   ├── install-postgres.sh
│   └── install.sh
├── src/                      # Core system
│   ├── core/
│   │   ├── engine.sh         # Modular engine (no hardcoded values)
│   │   └── json-loader.sh    # JSON configuration loader
│   ├── utils/
│   │   ├── helpers.sh        # Helper utilities
│   │   └── logger.sh         # Logging system
│   └── config/
│       └── modules/          # JSON module definitions
│           ├── ai-development-tools.json
│           ├── cloud-development.json
│           ├── common-development.json
│           ├── devops.json
│           ├── package-managers.json
│           ├── scripts.json
│           ├── system-security.json
│           └── web-development.json
├── test/                     # Test suite
│   ├── test-all-components.sh
│   ├── test-component.sh
│   ├── test-script.sh
│   └── test-config.json
└── docs/                     # Documentation
    └── README.md
```

## Key Features

- **JSON-Driven**: All configuration in JSON format
- **Modular**: Clean separation of concerns
- **No Hardcoded Values**: Dynamic path detection
- **CLI Integration**: Script execution via `-sh` flag
- **Extensible**: Easy to add new components and scripts

## Usage

```bash
# Component management
setupx install curl
setupx check nodejs
setupx list-module web-development

# Script execution
setupx -sh install-postgres -d mydb -u dbuser -p dbpass123
setupx -sh deploy-node-app

# Short alias
slx install docker
slx -sh nginx-domain -d example.com -p 3000
```

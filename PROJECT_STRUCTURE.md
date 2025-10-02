# SetupX Project Structure

## 📁 Clean Modular Structure

```
setupx-linux-server/
├── 📄 README.md                    # Main project documentation
├── 📄 index.html                    # Website homepage
├── 📄 vercel.json                   # Vercel deployment config
├── 📄 package.json                  # Node.js dependencies
├── 📄 .gitignore                    # Git ignore rules
├── 📄 PROJECT_STRUCTURE.md          # This file
├── 📄 setupx.sh                     # Main CLI script
├── 📄 install.sh                    # Installation script
│
├── 📁 docs/                         # Documentation
│   ├── 📄 README.md                 # Comprehensive documentation
│   └── 📄 STRUCTURE.md              # Project structure guide
│
├── 📁 src/                          # Source code
│   ├── 📁 config/modules/           # JSON module definitions
│   │   ├── 📄 ai-development-tools.json
│   │   ├── 📄 cloud-development.json
│   │   ├── 📄 common-development.json
│   │   ├── 📄 database-management.json
│   │   ├── 📄 devops.json
│   │   ├── 📄 package-managers.json
│   │   ├── 📄 scripts.json
│   │   ├── 📄 server-setup.json
│   │   ├── 📄 system-security.json
│   │   └── 📄 web-development.json
│   ├── 📁 core/                     # Core engine
│   │   ├── 📄 engine.sh
│   │   └── 📄 json-loader.sh
│   └── 📁 utils/                    # Utility functions
│       ├── 📄 helpers.sh
│       └── 📄 logger.sh
│
└── 📁 scripts/                     # Utility scripts
    ├── 📄 apache-domain.sh          # Apache domain setup
    ├── 📄 database-manager.sh       # Database management
    ├── 📄 database-reset.sh         # Database reset
    ├── 📄 deploy-node-app.sh        # Node.js app deployment
    ├── 📄 deploy-node-git.sh        # Git-based deployment
    ├── 📄 final-ssh-root-login.sh   # SSH root login setup
    ├── 📄 install-postgres.sh       # PostgreSQL installer
    ├── 📄 install.sh                # Main installer
    ├── 📄 nginx-domain.sh           # Nginx domain setup
    ├── 📄 pm2-deploy.sh             # PM2 deployment
    ├── 📄 postgres-remote.sh        # PostgreSQL remote setup
    ├── 📄 reset-mariadb.sh          # MariaDB reset
    ├── 📄 reset-mongodb.sh           # MongoDB reset
    ├── 📄 reset-mysql.sh            # MySQL reset
    ├── 📄 reset-postgres.sh         # PostgreSQL reset
    ├── 📄 setcp.sh                  # Database password manager
    ├── 📄 ssl-setup.sh              # SSL certificate setup
    └── 📄 update-all.sh             # System update
```

## 🎯 Key Features

### 📦 **Modular Design**
- **JSON-driven configuration** for all modules
- **Separate scripts** for specific tasks
- **Clean separation** between core, config, and scripts

### 🔧 **Core Components**
- **setupx.sh**: Main CLI interface
- **src/core/**: Core engine and JSON loader
- **src/config/**: Module definitions
- **scripts/**: Utility scripts

### 📚 **Documentation**
- **README.md**: Quick start and overview
- **docs/README.md**: Comprehensive documentation
- **PROJECT_STRUCTURE.md**: This structure guide

### 🌐 **Website**
- **index.html**: Modern, responsive website
- **vercel.json**: Deployment configuration
- **Copy-to-clipboard** functionality

## 🚀 Usage

### Linux/Ubuntu:
```bash
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash
setupx help
```

### Windows WSL:
```bash
wsl bash setupx.sh help
wsl bash setupx.sh -sh nginx-domain -d example.com -p 3000
```

## 📊 Statistics
- **19 Utility Scripts**
- **10 JSON Modules**
- **80+ Components**
- **Cross-platform support** (Linux + Windows WSL)
- **Interactive menus**
- **Database management**
- **Web server setup**

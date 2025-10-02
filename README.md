# SetupX Linux Server

🚀 **Complete Linux Development Environment Setup Tool** - Automated server configuration with advanced database management, web deployment, and security scripts.

## 📚 Documentation

For complete documentation, please see: [docs/README.md](docs/README.md)

## 🚀 Quick Start

### Linux/Ubuntu/Debian:
```bash
# One-line installation
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash

# Launch interactive menu
setupx menu

# Launch scripts menu
setupx scripts-menu
```

### Windows with WSL (Windows Subsystem for Linux):
```bash
# Run directly with WSL
wsl bash setupx.sh help                    # Show help
wsl bash setupx.sh list                    # List modules
wsl bash setupx.sh scripts                 # List scripts
wsl bash setupx.sh menu                     # Interactive menu
wsl bash setupx.sh scripts-menu             # Scripts menu
wsl bash setupx.sh install-module web-development  # Install web dev tools
wsl bash setupx.sh -sh nginx-domain -d example.com -p 3000  # Setup domain
```

## 🌟 Key Features

- **One-Line Install**: Complete development environment in minutes
- **Database Management**: PostgreSQL, MySQL, MongoDB password reset and user creation
- **Web Deployment**: Nginx/Apache domain setup with SSL, PM2 process management
- **Security**: SSH configuration, UFW firewall, Fail2Ban intrusion prevention
- **Development Stack**: Node.js, Python, Git, GitHub CLI, NVM, PM2, Docker
- **Advanced Scripts**: SetCP, Nginx/Apache domain setup, PM2 deployment automation
- **Interactive Menus**: Guided setup with step-by-step prompts

## 📋 Available Commands

```bash
setupx help                    # Show help
setupx list                    # List all modules
setupx scripts                 # List all scripts
setupx menu                    # Interactive menu system
setupx scripts-menu            # Scripts-only menu
setupx install <component>     # Install specific component
setupx install-module <module> # Install complete module
setupx -sh <script> [args]     # Run script with arguments
```

## 🎯 Quick Examples

### Linux/Ubuntu/Debian:
```bash
# Install web development stack
setupx install-module web-development

# Setup Nginx domain with SSL
setupx -sh nginx-domain -d example.com -p 3000 -s

# Setup Apache domain with SSL
setupx -sh apache-domain -d example.com -p 3000 -s

# Deploy application with PM2
setupx -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp

# Reset database password
setupx -sh setcp -p postgresql newpass123
```

### Windows with WSL:
```bash
# Install web development stack
wsl bash setupx.sh install-module web-development

# Setup Nginx domain with SSL
wsl bash setupx.sh -sh nginx-domain -d example.com -p 3000 -s

# Setup Apache domain with SSL
wsl bash setupx.sh -sh apache-domain -d example.com -p 3000 -s

# Deploy application with PM2
wsl bash setupx.sh -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp

# Reset database password
wsl bash setupx.sh -sh setcp -p postgresql newpass123
```

## 📖 Complete Documentation

For detailed documentation, installation guides, and advanced usage examples, please visit:

**[📚 Complete Documentation](docs/README.md)**

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **GitHub Issues**: [Create an issue](https://github.com/anshulyadav32/setupx-linux-server/issues)
- **Documentation**: [View docs](docs/README.md)
- **Discussions**: [GitHub Discussions](https://github.com/anshulyadav32/setupx-linux-server/discussions)

---

**Made with ❤️ for the Linux community**

*SetupX - Simplifying Linux server setup, one command at a time.*

# SetupX Linux Server

🚀 **Complete Linux Development Environment Setup Tool** - Automated server configuration with advanced database management, web deployment, and security scripts.

## 🌟 Features

- **One-Line Install**: Complete development environment in minutes
- **Database Management**: PostgreSQL, MySQL, MongoDB password reset and user creation
- **Web Deployment**: Nginx domain setup with SSL, PM2 process management
- **Security**: SSH configuration, UFW firewall, Fail2Ban intrusion prevention
- **Development Stack**: Node.js, Python, Git, GitHub CLI, NVM, PM2, Docker
- **Advanced Scripts**: SetCP, Nginx domain setup, PM2 deployment automation
- **System Optimization**: Auto-update, upgrade, and essential tools installation

## 🚀 One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash
```

**What gets installed:**
- ✅ System update and upgrade
- ✅ Git, Python3, jq, curl, wget
- ✅ GitHub CLI (gh)
- ✅ NVM with Node.js LTS
- ✅ PM2 process manager
- ✅ Vim, nano, htop, tree
- ✅ Complete SetupX toolchain

## 📋 Quick Start

```bash
# Show help and available commands
setupx help

# List all available modules
setupx list

# Install package managers (APT, Snap, Flatpak)
setupx install-module package-managers

# Install complete web development stack
setupx install-module web-development

# Install security tools (SSH, UFW, Fail2Ban)
setupx install-module system-security
```

## 🔧 Advanced Scripts

### **Database Management (SetCP)**
```bash
# Reset PostgreSQL password
setupx -sh setcp -p postgresql newpass123

# Reset MySQL password
setupx -sh setcp -p mysql newpass123

# Reset MongoDB password
setupx -sh setcp -p mongodb newpass123

# Create new database and user
setupx -sh setcp create-db mydb myuser mypass

# Check database status
setupx -sh setcp status
```

### **Nginx Domain Setup**
```bash
# Setup domain without SSL
setupx -sh nginx-domain -d example.com -p 3000

# Setup domain with SSL (Let's Encrypt)
setupx -sh nginx-domain -d api.example.com -p 8080 -s

# Remove domain
setupx -sh nginx-domain remove example.com

# Check domain status
setupx -sh nginx-domain status
```

### **PM2 Application Deployment**
```bash
# Deploy development app
setupx -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp

# Deploy production app
setupx -sh pm2-deploy -n api -p 8080 -d /home/user/api -e production

# Remove application
setupx -sh pm2-deploy remove myapp

# Check PM2 status
setupx -sh pm2-deploy status
```

### **GCP VM Management**
```bash
# Enable root login for GCP VM
setupx -sh gcprootlogin -p rootpass ubuntupass

# System update
setupx -sh system-update

# Create system backup
setupx -sh backup-system
```

## 🎯 Available Modules

- **package-managers**: APT, Snap, Flatpak, NPM
- **web-development**: Node.js, PM2, PostgreSQL, MySQL, Nginx, SSL, Docker, React, Vue, Angular
- **common-development**: Git, Vim, Nano, cURL, Wget, Chrome Remote Desktop
- **system-security**: SSH, UFW Firewall, Fail2Ban, OpenSSH Server
- **ai-development-tools**: Python, Node.js, AI/ML tools
- **cloud-development**: AWS CLI, Azure CLI, Google Cloud CLI
- **devops**: Docker, Kubernetes, CI/CD tools
- **scripts**: Database management, Nginx setup, PM2 deployment

## 🚀 Complete Workflow Examples

### **Full-Stack Web Application Setup**
```bash
# 1. Install SetupX
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash

# 2. Install web development stack
setupx install-module web-development

# 3. Reset database password
setupx -sh setcp -p postgresql newpass123

# 4. Create database and user
setupx -sh setcp create-db myappdb myappuser myapppass

# 5. Deploy application with PM2
setupx -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp -e production

# 6. Setup Nginx domain with SSL
setupx -sh nginx-domain -d myapp.com -p 3000 -s
```

### **Development Environment Setup**
```bash
# 1. Install essential tools
setupx install-module package-managers
setupx install-module common-development

# 2. Setup security
setupx install-module system-security

# 3. Configure GCP VM (if needed)
setupx -sh gcprootlogin -p rootpass ubuntupass
```

## 🔧 Troubleshooting

### **Command Not Found**
```bash
# Refresh environment
source /etc/bash.bashrc

# Or manually add to PATH
export PATH="/usr/local/bin:$PATH"
```

### **Permission Issues**
```bash
# Ensure proper permissions
sudo chmod +x /usr/local/bin/setupx
sudo chmod +x /usr/local/bin/wsx
```

### **Database Connection Issues**
```bash
# Check database status
setupx -sh setcp status

# Restart database services
sudo systemctl restart postgresql
sudo systemctl restart mysql
```

## 📊 System Requirements

- **OS**: Ubuntu 18.04+ / Debian 10+ / CentOS 7+
- **Memory**: 2GB RAM minimum, 4GB recommended
- **Storage**: 10GB free space
- **Network**: Internet connection for downloads
- **Privileges**: Root access or sudo privileges

## 🎯 Use Cases

- **Web Development**: Complete LAMP/LEMP stack setup
- **API Development**: Node.js, Python, database management
- **DevOps**: Docker, Kubernetes, CI/CD pipeline setup
- **Cloud Development**: AWS, Azure, GCP tool configuration
- **Security**: SSH hardening, firewall setup, intrusion prevention
- **Database Management**: Multi-database password and user management

## 📖 Documentation

- [Main Documentation](https://github.com/anshulyadav32/setupx-linux-server)
- [GitHub Pages](https://anshulyadav32.github.io/setupx-linux-server/)
- [Project Structure](https://github.com/anshulyadav32/setupx-linux-server/blob/main/docs/STRUCTURE.md)
- [Configuration Guide](https://github.com/anshulyadav32/setupx-linux-server/blob/main/config.json)

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
- **Documentation**: [View docs](https://github.com/anshulyadav32/setupx-linux-server/tree/main/docs)
- **Discussions**: [GitHub Discussions](https://github.com/anshulyadav32/setupx-linux-server/discussions)

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=anshulyadav32/setupx-linux-server&type=Date)](https://star-history.com/#anshulyadav32/setupx-linux-server&Date)

---

**Made with ❤️ for the Linux community**

*SetupX - Simplifying Linux server setup, one command at a time.*

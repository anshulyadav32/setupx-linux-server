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

## 🎯 Interactive Menu System

### **Launch Interactive Menu**
```bash
# Start the interactive menu system
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx menu
```

### **Menu Features**
- **📦 Install Components** - Install by module or individual components
- **🔧 Run Scripts** - Execute scripts with interactive selection
- **📋 List Modules** - Browse and explore available modules
- **🔍 Search Components** - Find specific components
- **📊 System Status** - Check system and SetupX status
- **❓ Help** - Access help documentation
- **🚪 Exit** - Clean exit from menu

### **Menu Navigation**
- **Number Selection** - Choose options by entering numbers (1-7)
- **Back Navigation** - Return to previous menus with back options
- **Input Validation** - Invalid selections show error messages
- **Clear Screen** - Clean interface with screen clearing
- **Press Enter** - Continue prompts for better user experience

## 📋 All Available Scripts

### **View All Scripts**
```bash
# List all available scripts
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh list

# Show script help
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh help

# Interactive menu system
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx menu
```

### **Available Scripts Overview**
| Script Name | Description | Usage |
|-------------|-------------|-------|
| `final-ssh-root-login` | Enable SSH root login with password | `setupx -sh final-ssh-root-login -p <password>` |
| `install-postgres` | Install PostgreSQL with database setup | `setupx -sh install-postgres -d <db> -u <user> -p <pass>` |
| `deploy-node-app` | Deploy Node.js application with PM2 | `setupx -sh deploy-node-app -d <domain> -a <app> -g <repo> -p <port>` |
| `nginx-domain` | Configure Nginx domain with SSL | `setupx -sh nginx-domain -d <domain> -p <port> [-s]` |
| `pm2-deploy` | Deploy application with PM2 | `setupx -sh pm2-deploy -n <app> -p <port> -d <dir> [-e <env>]` |
| `setcp` | Reset database passwords | `setupx -sh setcp -p <database> <password>` |
| `update-all` | Update all system packages | `setupx -sh update-all [-y] [--no-cleanup]` |
| `reset-postgres` | Reset PostgreSQL database | `setupx -sh reset-postgres [-d <db>] [-u <user>] [-p <pass>]` |
| `reset-mariadb` | Reset MariaDB database | `setupx -sh reset-mariadb [-d <db>] [-u <user>] [-p <pass>]` |
| `reset-mysql` | Reset MySQL database | `setupx -sh reset-mysql [-d <db>] [-u <user>] [-p <pass>]` |
| `reset-mongodb` | Reset MongoDB database | `setupx -sh reset-mongodb [-d <db>] [-u <user>] [-p <pass>]` |
| `deploy-node-git` | Deploy Node.js app from Git | `setupx -sh deploy-node-git -w <web> -a <app> -g <git> [-p <port>]` |
| `ssl-setup` | Setup SSL certificates | `setupx -sh ssl-setup -d <domain> [--no-www]` |
| `postgres-remote` | Configure PostgreSQL for remote access | `setupx -sh postgres-remote [-p <port>] [-i <ips>]` |

## ⚡ One-Liner Component Installation

### **Package Managers**
```bash
# Install APT package manager
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install apt

# Install Snap package manager
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install snap

# Install Flatpak package manager
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install flatpak

# Install NPM package manager
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install npm
```

### **Web Development Tools**
```bash
# Install Node.js
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install nodejs

# Install PM2 process manager
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install pm2

# Install PostgreSQL database
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install postgresql

# Install MySQL database
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install mysql

# Install Nginx web server
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install nginx

# Install Docker containerization
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install docker
```

### **Development Tools**
```bash
# Install Git version control
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install git

# Install Python programming language
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install python

# Install cURL command-line tool
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install curl

# Install Wget download tool
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install wget

# Install Vim text editor
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install vim
```

### **Security Tools**
```bash
# Install UFW firewall
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install ufw

# Install Fail2Ban intrusion prevention
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install fail2ban

# Install OpenSSH server
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install openssh-server
```

### **Cloud & DevOps Tools**
```bash
# Install AWS CLI
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install aws-cli

# Install Azure CLI
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install azure-cli

# Install Google Cloud CLI
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install gcloud

# Install Kubernetes
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx install kubectl
```

### **Database Management Scripts**
```bash
# Reset PostgreSQL password
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh setcp -p postgresql newpass123

# Reset MySQL password
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh reset-mysql -p mysql123

# Reset MongoDB password
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh reset-mongodb -p mongodb123

# Reset MariaDB password
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh reset-mariadb -p mariadb123
```

### **Web Server & Domain Setup**
```bash
# Setup Nginx domain with SSL
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh nginx-domain -d example.com -p 3000 -s

# Deploy application with PM2
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp

# Deploy Node.js app from Git
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh deploy-node-git -w myapp -a myapp -g https://github.com/user/repo.git

# Setup SSL certificate
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh ssl-setup -d example.com
```

### **System Management Scripts**
```bash
# Enable SSH root login
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh final-ssh-root-login -p rootpass

# Update all system packages
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh update-all -y

# Setup PostgreSQL for remote access
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash && setupx -sh postgres-remote -p 5432
```

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

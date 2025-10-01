# SetupX Linux Server

🚀 **Modular Linux Development Environment Setup Tool** - Complete Linux server configuration with advanced scripts for database management, web deployment, and security.

## 🌟 Features

- **Quick Setup**: Get your development environment up and running in minutes
- **Database Management**: PostgreSQL, MySQL, MongoDB password reset and user creation
- **Web Deployment**: Nginx domain setup with SSL, PM2 process management
- **Security**: SSH configuration, UFW firewall, Fail2Ban intrusion prevention
- **Development Tools**: Complete web development stack with Node.js, Docker, and more
- **Advanced Scripts**: SetCP, Nginx domain setup, PM2 deployment automation

## 🚀 One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/anshulyadav32/setupx-linux-server/master/install.sh | bash
```

## 📋 Quick Start

```bash
# Show help
setupx help

# List all modules
setupx list

# Install package managers
setupx install-module package-managers

# Install web development stack
setupx install-module web-development

# Reset database password
setupx -sh setcp -p postgresql newpass123

# Setup Nginx domain with SSL
setupx -sh nginx-domain -d example.com -p 3000 -s

# Deploy application with PM2
setupx -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp
```

## 🔧 Available Scripts

- **SetCP**: Database password management (PostgreSQL, MySQL, MongoDB)
- **Nginx Domain**: Domain setup with SSL automation
- **PM2 Deploy**: Application deployment with process management
- **GCP Root Login**: Enable root access for GCP VMs
- **System Update**: Automated system updates
- **Backup System**: System backup creation

## 📖 Documentation

- [Main Documentation](https://github.com/anshulyadav32/setupx-linux-server)
- [Project Structure](https://github.com/anshulyadav32/setupx-linux-server/blob/main/docs/STRUCTURE.md)
- [Configuration Guide](https://github.com/anshulyadav32/setupx-linux-server/blob/main/config.json)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- GitHub Issues: [Create an issue](https://github.com/anshulyadav32/setupx-linux-server/issues)
- Documentation: [View docs](https://github.com/anshulyadav32/setupx-linux-server/tree/main/docs)
- Email: support@setupx-linux-server.com

---

**Made with ❤️ for the Linux community**

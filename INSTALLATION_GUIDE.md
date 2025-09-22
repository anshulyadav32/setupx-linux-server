# SMTP Web Application - Installation Guide

## 🚀 Quick Start

The SMTP Web Application provides a complete email server and web interface solution. Choose your installation method:

### Option 1: Automated Installation (Recommended)
```bash
python install.py
```

### Option 2: Manual Installation
Follow the detailed steps below for your operating system.

### Option 3: Docker Deployment
```bash
python deploy.py docker
cd deployments/[package_name]/docker
docker-compose up -d
```

---

## 📋 System Requirements

### Minimum Requirements
- **Python**: 3.8 or higher
- **RAM**: 512 MB
- **Storage**: 100 MB free space
- **Network**: Ports 5000 and 1025 available

### Recommended Requirements
- **Python**: 3.11 or higher
- **RAM**: 1 GB or more
- **Storage**: 1 GB free space
- **OS**: Linux (Ubuntu 20.04+), Windows 10+, macOS 10.15+

### Dependencies
- Flask 2.3.3+
- Werkzeug 2.3.7+
- Jinja2 3.1.2+
- Additional dependencies in `requirements.txt`

---

## 🐧 Linux Installation

### Ubuntu/Debian
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and pip
sudo apt install python3 python3-pip python3-venv -y

# Clone or download the application
cd /opt
sudo git clone [repository-url] smtp-webapp
cd smtp-webapp

# Run automated installer
sudo python3 install.py

# Start services
sudo systemctl start smtp-webapp
sudo systemctl enable smtp-webapp
```

### CentOS/RHEL/Fedora
```bash
# Install Python and pip
sudo dnf install python3 python3-pip -y  # Fedora
# OR
sudo yum install python3 python3-pip -y  # CentOS/RHEL

# Follow same steps as Ubuntu from cloning onwards
```

### Manual Linux Installation
```bash
# Create application user
sudo useradd -r -s /bin/false -d /opt/smtp-webapp smtp-webapp

# Create directories
sudo mkdir -p /opt/smtp-webapp /var/lib/smtp-webapp /var/log/smtp-webapp
sudo chown -R smtp-webapp:smtp-webapp /opt/smtp-webapp /var/lib/smtp-webapp /var/log/smtp-webapp

# Copy application files
sudo cp -r . /opt/smtp-webapp/
sudo chown -R smtp-webapp:smtp-webapp /opt/smtp-webapp

# Create virtual environment
sudo -u smtp-webapp python3 -m venv /opt/smtp-webapp/venv
sudo -u smtp-webapp /opt/smtp-webapp/venv/bin/pip install -r /opt/smtp-webapp/requirements.txt

# Install systemd service
sudo cp systemd/smtp-webapp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable smtp-webapp
sudo systemctl start smtp-webapp
```

---

## 🪟 Windows Installation

### Automated Installation
```cmd
# Open Command Prompt as Administrator
cd C:\
python install.py
```

### Manual Windows Installation
```cmd
# Create application directory
mkdir C:\smtp-webapp
cd C:\smtp-webapp

# Copy application files
xcopy /E /I /Y [source-path] C:\smtp-webapp

# Install dependencies
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

# Create Windows service (requires NSSM)
# Download NSSM from https://nssm.cc/
nssm install smtp-webapp python "C:\smtp-webapp\service_manager.py" start all

# Start service
nssm start smtp-webapp
```

### Windows Service Alternative
```cmd
# Create scheduled task to start on boot
schtasks /create /tn "SMTP WebApp" /tr "python \"C:\smtp-webapp\service_manager.py\" start all" /sc onstart /ru SYSTEM
```

---

## 🐳 Docker Installation

### Using Docker Compose (Recommended)
```bash
# Create production package
python deploy.py docker

# Navigate to Docker directory
cd deployments/[package_name]/docker

# Build and start
docker-compose up -d

# Check status
docker-compose ps
docker-compose logs -f
```

### Using Docker Only
```bash
# Build image
docker build -t smtp-webapp .

# Run container
docker run -d \
  --name smtp-webapp \
  -p 5000:5000 \
  -p 1025:1025 \
  -v smtp_emails:/app/emails \
  -v smtp_logs:/app/logs \
  smtp-webapp:latest
```

### Docker Environment Variables
```bash
# Production deployment
docker run -d \
  --name smtp-webapp \
  -p 5000:5000 \
  -p 1025:1025 \
  -e FLASK_ENV=production \
  -e FLASK_DEBUG=false \
  -e SECRET_KEY=your-secret-key \
  -e SMTP_HOST=0.0.0.0 \
  -e SMTP_PORT=1025 \
  -e WEB_HOST=0.0.0.0 \
  -e WEB_PORT=5000 \
  smtp-webapp:latest
```

---

## ⚙️ Configuration

### Environment Configuration
Create `.env` file in the application directory:
```env
# Flask Configuration
FLASK_ENV=production
FLASK_DEBUG=false
SECRET_KEY=change-this-in-production

# SMTP Server Settings
SMTP_HOST=0.0.0.0
SMTP_PORT=1025
SMTP_DEBUG=false

# Web Interface Settings
WEB_HOST=0.0.0.0
WEB_PORT=5000

# Email Storage
EMAIL_DIR=emails
MAX_EMAIL_SIZE_MB=1000

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/smtp_app.log

# Security
ALLOWED_HOSTS=localhost,127.0.0.1
RATE_LIMIT_ENABLED=true
MAX_REQUESTS_PER_MINUTE=100
```

### Configuration Management
```bash
# View current configuration
python config_manager.py show

# Update configuration
python config_manager.py set smtp.port 2525
python config_manager.py set web.debug false

# Validate configuration
python config_manager.py validate

# Reset to defaults
python config_manager.py reset
```

---

## 🔧 Service Management

### Using Service Manager
```bash
# Start all services
python service_manager.py start all

# Start individual services
python service_manager.py start smtp
python service_manager.py start web

# Stop services
python service_manager.py stop all

# Check status
python service_manager.py status

# Restart services
python service_manager.py restart all

# View logs
python service_manager.py logs
```

### Linux Systemd
```bash
# Service control
sudo systemctl start smtp-webapp
sudo systemctl stop smtp-webapp
sudo systemctl restart smtp-webapp
sudo systemctl status smtp-webapp

# Enable/disable auto-start
sudo systemctl enable smtp-webapp
sudo systemctl disable smtp-webapp

# View logs
sudo journalctl -u smtp-webapp -f
sudo journalctl -u smtp-webapp --since "1 hour ago"
```

### Windows Service
```cmd
# Using NSSM
nssm start smtp-webapp
nssm stop smtp-webapp
nssm restart smtp-webapp
nssm status smtp-webapp

# View service logs
nssm dump smtp-webapp
```

---

## 🔥 Firewall Configuration

### Linux (UFW)
```bash
# Allow web interface
sudo ufw allow 5000/tcp comment "SMTP Web Interface"

# Allow SMTP server
sudo ufw allow 1025/tcp comment "SMTP Server"

# Enable firewall
sudo ufw enable
```

### Linux (iptables)
```bash
# Allow web interface
sudo iptables -A INPUT -p tcp --dport 5000 -j ACCEPT

# Allow SMTP server
sudo iptables -A INPUT -p tcp --dport 1025 -j ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### Windows Firewall
```cmd
# Allow web interface
netsh advfirewall firewall add rule name="SMTP Web Interface" dir=in action=allow protocol=TCP localport=5000

# Allow SMTP server
netsh advfirewall firewall add rule name="SMTP Server" dir=in action=allow protocol=TCP localport=1025
```

---

## 🧪 Testing Installation

### Basic Functionality Test
```bash
# Test web interface
curl http://localhost:5000/

# Test SMTP server
telnet localhost 1025
```

### Comprehensive Testing
```bash
# Run test suite
python deploy.py test
cd deployments/testing
python run_tests.py
```

### Manual Testing
1. **Web Interface**: Open http://localhost:5000 in browser
2. **SMTP Server**: Use email client to connect to localhost:1025
3. **Email Storage**: Check emails directory for received messages
4. **Logs**: Check logs directory for application logs

---

## 🔍 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Check what's using the port
netstat -tulpn | grep :5000
netstat -tulpn | grep :1025

# Kill process using port
sudo kill -9 [PID]

# Or change port in configuration
python config_manager.py set web.port 5001
python config_manager.py set smtp.port 1026
```

#### Permission Denied
```bash
# Linux: Fix file permissions
sudo chown -R smtp-webapp:smtp-webapp /opt/smtp-webapp
sudo chmod +x /opt/smtp-webapp/service_manager.py

# Windows: Run as Administrator
# Right-click Command Prompt -> "Run as Administrator"
```

#### Python Module Not Found
```bash
# Reinstall dependencies
pip install -r requirements.txt

# Or use virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows
pip install -r requirements.txt
```

#### Service Won't Start
```bash
# Check logs
python service_manager.py logs

# Linux systemd logs
sudo journalctl -u smtp-webapp -f

# Check configuration
python config_manager.py validate

# Reset configuration
python config_manager.py reset
```

### Log Locations
- **Linux**: `/var/log/smtp-webapp/`
- **Windows**: `C:\smtp-webapp\logs\`
- **Docker**: Container logs via `docker-compose logs`

### Getting Help
1. Check application logs
2. Verify configuration with `python config_manager.py show`
3. Test network connectivity
4. Check system resources (RAM, disk space)
5. Verify Python version compatibility

---

## 🔄 Updating

### Update Application
```bash
# Backup current installation
cp -r /opt/smtp-webapp /opt/smtp-webapp.backup

# Stop services
sudo systemctl stop smtp-webapp

# Update files
# [Copy new files]

# Update dependencies
pip install -r requirements.txt

# Start services
sudo systemctl start smtp-webapp
```

### Update Configuration
```bash
# Backup configuration
cp config/app_config.json config/app_config.json.backup

# Update configuration
python config_manager.py update

# Restart services
python service_manager.py restart all
```

---

## 🗑️ Uninstallation

### Linux
```bash
# Stop and disable service
sudo systemctl stop smtp-webapp
sudo systemctl disable smtp-webapp

# Remove service file
sudo rm /etc/systemd/system/smtp-webapp.service
sudo systemctl daemon-reload

# Remove application files
sudo rm -rf /opt/smtp-webapp
sudo rm -rf /var/lib/smtp-webapp
sudo rm -rf /var/log/smtp-webapp

# Remove user
sudo userdel smtp-webapp
```

### Windows
```cmd
# Stop and remove service
nssm stop smtp-webapp
nssm remove smtp-webapp confirm

# Remove application directory
rmdir /s C:\smtp-webapp

# Remove scheduled tasks
schtasks /delete /tn "SMTP WebApp" /f
```

### Docker
```bash
# Stop and remove containers
docker-compose down -v

# Remove images
docker rmi smtp-webapp:latest

# Remove volumes (optional)
docker volume rm smtp_emails smtp_logs smtp_config
```

---

## 📞 Support

For additional support:
- Check the troubleshooting section above
- Review application logs
- Verify system requirements
- Test with minimal configuration

---

*Last updated: January 2025*
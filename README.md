# 📧 SMTP Web Application - Complete Email Server & Client Solution

A comprehensive SMTP server and web-based email client with modern features, automated installation, and production-ready deployment tools.

## 🚀 Quick Start

### One-Command Installation
```bash
python install.py
```

### Manual Start
```bash
# Start all services
python service_manager.py start all

# Access web interface
open http://localhost:5000
```

### Docker Deployment
```bash
python deploy.py docker
cd deployments/[package_name]/docker
docker-compose up -d
```

---

## ✨ Features

### 📧 Email Management
- **SMTP Server**: Full-featured SMTP server with configurable ports and settings
- **Email Storage**: Persistent email storage with automatic cleanup and backup
- **Web Interface**: Modern, responsive web UI for email management
- **Email Viewer**: Rich email viewing with HTML rendering and attachment support
- **Email Composer**: Advanced email composition with file attachments
- **Search & Filter**: Powerful search capabilities across all emails

### 🔧 Administration
- **Service Management**: Start, stop, restart, and monitor all services
- **Configuration Management**: Web-based and CLI configuration tools
- **Real-time Monitoring**: Live status monitoring and performance metrics
- **Log Management**: Centralized logging with rotation and cleanup
- **User Management**: Multi-user support with role-based access

### 🚀 Deployment & Operations
- **Automated Installation**: One-click installation for all platforms
- **Multi-Environment Support**: Development, testing, and production configurations
- **Docker Support**: Complete containerization with Docker Compose
- **Service Integration**: Systemd (Linux) and Windows Service support
- **Backup & Recovery**: Automated backup and restore functionality

### 🔒 Security & Performance
- **Rate Limiting**: Configurable rate limiting and DDoS protection
- **Input Validation**: Comprehensive input sanitization and validation
- **Secure Headers**: Security headers and CSRF protection
- **Performance Monitoring**: Real-time performance metrics and alerting
- **SSL/TLS Support**: Optional encryption for secure communications

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

---

## 🛠️ Installation Options

### Option 1: Automated Installation (Recommended)
```bash
# Download and run installer
python install.py

# Follow interactive prompts for configuration
# Services will start automatically
```

### Option 2: Manual Installation
```bash
# Install dependencies
pip install -r requirements.txt

# Configure application
python config_manager.py setup

# Start services
python service_manager.py start all
```

### Option 3: Docker Deployment
```bash
# Create production package
python deploy.py docker

# Deploy with Docker Compose
cd deployments/[package_name]/docker
docker-compose up -d
```

### Option 4: Production Deployment
```bash
# Create production package
python deploy.py package --environment production

# Deploy to server (Linux)
./scripts/deploy_linux.sh

# Deploy to server (Windows)
scripts\deploy_windows.bat
```

---

## 🎯 Usage Examples

### Web Interface
1. **Access Dashboard**: Open http://localhost:5000
2. **View Emails**: Browse received emails with search and filtering
3. **Compose Emails**: Create and send emails with attachments
4. **Manage Settings**: Configure server settings and preferences
5. **Monitor Status**: View real-time server status and metrics

### SMTP Server
```python
# Send email via SMTP (Python)
import smtplib
from email.mime.text import MIMEText

msg = MIMEText("Hello from SMTP!")
msg['Subject'] = 'Test Email'
msg['From'] = 'sender@example.com'
msg['To'] = 'recipient@example.com'

with smtplib.SMTP('localhost', 1025) as server:
    server.send_message(msg)
```

### REST API
```bash
# Get all emails
curl http://localhost:5000/api/emails

# Send email via API
curl -X POST http://localhost:5000/api/send \
  -H "Content-Type: application/json" \
  -d '{"to": ["test@example.com"], "subject": "API Test", "body": "Hello!"}'

# Get server status
curl http://localhost:5000/api/status
```

### Command Line Management
```bash
# Service management
python service_manager.py start all      # Start all services
python service_manager.py stop smtp      # Stop SMTP server
python service_manager.py restart web    # Restart web interface
python service_manager.py status         # Check service status

# Configuration management
python config_manager.py show            # Show current config
python config_manager.py set smtp.port 2525  # Update SMTP port
python config_manager.py validate        # Validate configuration
python config_manager.py reset           # Reset to defaults

# Deployment management
python deploy.py package                 # Create production package
python deploy.py deploy --environment production  # Deploy to production
python deploy.py test                    # Run test suite
```

---

## 📁 Project Structure

```
smtp-webapp/
├── 📄 Core Application
│   ├── smtp_server.py          # SMTP server implementation
│   ├── smtp_client.py          # SMTP client utilities
│   ├── web_interface.py        # Flask web application
│   ├── service_manager.py      # Service management system
│   └── config_manager.py       # Configuration management
│
├── 🎨 Web Interface
│   ├── templates/              # HTML templates
│   │   ├── base.html          # Base template
│   │   ├── index.html         # Dashboard
│   │   ├── emails.html        # Email list
│   │   ├── view_email.html    # Email viewer
│   │   └── compose.html       # Email composer
│   └── static/                # CSS, JS, images
│       ├── css/style.css      # Main stylesheet
│       ├── js/app.js          # JavaScript functionality
│       └── images/            # Application images
│
├── 🚀 Installation & Deployment
│   ├── install.py             # Automated installer
│   ├── deploy.py              # Deployment manager
│   ├── requirements.txt       # Python dependencies
│   └── deployments/           # Deployment packages
│       ├── production/        # Production configs
│       ├── development/       # Development configs
│       └── testing/           # Testing configs
│
├── 📚 Documentation
│   ├── README.md              # This file
│   ├── INSTALLATION_GUIDE.md  # Detailed installation guide
│   ├── API_REFERENCE.md       # Complete API documentation
│   └── examples/              # Usage examples
│
├── 📊 Data & Logs
│   ├── emails/                # Stored emails
│   ├── logs/                  # Application logs
│   ├── config/                # Configuration files
│   └── backups/               # Email backups
│
└── 🧪 Testing & Scripts
    ├── tests/                 # Test suite
    ├── scripts/               # Utility scripts
    └── examples/              # Example implementations
```

---

## 🔧 Configuration

### Environment Variables
```env
# Flask Configuration
FLASK_ENV=production
FLASK_DEBUG=false
SECRET_KEY=your-secret-key-here

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

# Security
ALLOWED_HOSTS=localhost,127.0.0.1
RATE_LIMIT_ENABLED=true
MAX_REQUESTS_PER_MINUTE=100
```

### Configuration Management
```bash
# Interactive configuration setup
python config_manager.py setup

# View current configuration
python config_manager.py show

# Update specific settings
python config_manager.py set smtp.port 2525
python config_manager.py set web.debug false

# Validate configuration
python config_manager.py validate

# Reset to defaults
python config_manager.py reset
```

---

## 📊 Monitoring & Maintenance

### Service Status
```bash
# Check all services
python service_manager.py status

# View detailed logs
python service_manager.py logs --follow

# Monitor performance
python service_manager.py monitor
```

### Web Dashboard
- **Real-time Metrics**: CPU, memory, disk usage
- **Email Statistics**: Daily/weekly/monthly email counts
- **Service Status**: SMTP server and web interface status
- **Storage Usage**: Email storage and cleanup status
- **Performance Graphs**: Response times and throughput

### Log Management
- **Automatic Rotation**: Configurable log rotation and cleanup
- **Centralized Logging**: All services log to centralized location
- **Log Levels**: Configurable logging levels (DEBUG, INFO, WARNING, ERROR)
- **Real-time Viewing**: Live log streaming in web interface

---

## 🔒 Security Features

### Built-in Security
- **Input Validation**: Comprehensive input sanitization
- **Rate Limiting**: Configurable request rate limiting
- **CSRF Protection**: Cross-site request forgery protection
- **Secure Headers**: Security headers for web interface
- **File Upload Security**: Safe file upload handling

### Network Security
- **Firewall Configuration**: Automated firewall rule setup
- **Port Management**: Configurable port bindings
- **Host Restrictions**: Allowed hosts configuration
- **SSL/TLS Support**: Optional encryption support

---

## 🧪 Testing

### Automated Testing
```bash
# Run full test suite
python deploy.py test

# Run specific tests
cd deployments/testing
python run_tests.py

# Performance testing
python scripts/performance_test.py
```

### Manual Testing
```bash
# Test SMTP server
telnet localhost 1025

# Test web interface
curl http://localhost:5000/api/status

# Test email sending
python examples/send_test_email.py
```

---

## 🚀 Production Deployment

### Linux Production Deployment
```bash
# Create production package
python deploy.py package --environment production

# Extract on production server
unzip smtp_webapp_production_[timestamp].zip
cd smtp_webapp_production_[timestamp]

# Run deployment script
sudo ./scripts/deploy_linux.sh

# Verify deployment
sudo systemctl status smtp-webapp
```

### Docker Production Deployment
```bash
# Build production image
python deploy.py docker
cd deployments/[package_name]/docker
./build.sh

# Deploy with Docker Compose
docker-compose up -d

# Monitor deployment
docker-compose logs -f
```

### Windows Production Deployment
```cmd
REM Create production package
python deploy.py package --environment production

REM Extract and deploy
scripts\deploy_windows.bat

REM Install as Windows service (requires NSSM)
nssm install smtp-webapp python "C:\smtp-webapp\service_manager.py" start all
```

---

## 📚 API Documentation

### REST API Endpoints
- `GET /api/emails` - List all emails
- `GET /api/emails/<id>` - Get specific email
- `POST /api/send` - Send email
- `DELETE /api/emails/<id>` - Delete email
- `GET /api/stats` - Get statistics
- `GET /api/status` - Get server status

### SMTP Protocol Support
- **Commands**: HELO, EHLO, MAIL FROM, RCPT TO, DATA, QUIT
- **Extensions**: SIZE, 8BITMIME, PIPELINING
- **Authentication**: Optional SMTP AUTH support
- **Security**: Optional STARTTLS support

For complete API documentation, see [API_REFERENCE.md](API_REFERENCE.md).

---

## 🤝 Contributing

### Development Setup
```bash
# Clone repository
git clone [repository-url]
cd smtp-webapp

# Create development environment
python deploy.py deploy --environment development

# Start development server
cd deployments/development
./start_dev.sh
```

### Code Style
- **Python**: Follow PEP 8 guidelines
- **JavaScript**: Use ES6+ features
- **HTML/CSS**: Follow modern web standards
- **Documentation**: Use clear, concise documentation

### Testing Requirements
- All new features must include tests
- Maintain minimum 80% code coverage
- Test on multiple Python versions (3.8+)
- Test on multiple operating systems

---

## 📞 Support & Documentation

### Documentation
- **Installation Guide**: [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)
- **API Reference**: [API_REFERENCE.md](API_REFERENCE.md)
- **Examples**: [examples/](examples/) directory
- **Configuration**: Built-in help via `python config_manager.py --help`

### Troubleshooting
1. **Check Service Status**: `python service_manager.py status`
2. **View Logs**: `python service_manager.py logs`
3. **Validate Configuration**: `python config_manager.py validate`
4. **Test Connectivity**: `curl http://localhost:5000/api/status`
5. **Reset Configuration**: `python config_manager.py reset`

### Getting Help
- Check the troubleshooting section in documentation
- Review application logs for error messages
- Verify system requirements and dependencies
- Test with minimal configuration

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🎯 Roadmap

### Version 2.0 (Planned)
- [ ] Multi-tenant support
- [ ] Advanced email filtering and rules
- [ ] Email templates and automation
- [ ] Mobile-responsive design improvements
- [ ] Advanced analytics and reporting

### Version 2.1 (Future)
- [ ] IMAP server support
- [ ] Email synchronization
- [ ] Calendar integration
- [ ] Contact management
- [ ] Advanced security features

---

*Last updated: January 2025*

**Made with ❤️ for the email management community**

## Quick Start

### Starting the SMTP Server

```bash
# Start server on default port (1025)
python smtp_server.py

# Start server on custom host and port
python smtp_server.py --host 0.0.0.0 --port 2525

# Specify custom directory for saving emails
python smtp_server.py --mail-dir /path/to/emails
```

### Sending Emails with the Client

```bash
# Send a simple email to your local server
python smtp_client.py --server localhost --port 1025 --from sender@example.com --to recipient@example.com --subject "Test Email" --body "Hello, World!"

# Send email with authentication
python smtp_client.py --server smtp.gmail.com --port 587 --from your@gmail.com --to recipient@example.com --subject "Test" --username your@gmail.com

# Send email with attachments
python smtp_client.py --server localhost --port 1025 --from sender@example.com --to recipient@example.com --subject "With Attachment" --attachments file1.txt file2.pdf
```

## Usage Examples

### Example 1: Local Testing

1. Start the SMTP server:
   ```bash
   python smtp_server.py
   ```

2. In another terminal, send a test email:
   ```bash
   python smtp_client.py --server localhost --port 1025 --from test@example.com --to user@example.com --subject "Local Test" --body "This is a test email"
   ```

3. Check the `received_emails` directory for the saved email file.

### Example 2: Sending via Gmail

```bash
python smtp_client.py --server smtp.gmail.com --port 587 --from your@gmail.com --to recipient@example.com --subject "Gmail Test" --username your@gmail.com
```

*Note: For Gmail, you'll need to use an App Password instead of your regular password.*

### Example 3: HTML Email with Attachments

```bash
python smtp_client.py --server localhost --port 1025 --from sender@example.com --to recipient@example.com --subject "Rich Email" --html-body "<h1>Hello</h1><p>This is <b>HTML</b> content!</p>" --attachments document.pdf image.jpg
```

## Command-Line Options

### SMTP Server (`smtp_server.py`)

- `--host`: Host to bind to (default: localhost)
- `--port`: Port to bind to (default: 1025)
- `--mail-dir`: Directory to save emails (default: received_emails)

### SMTP Client (`smtp_client.py`)

- `--server`: SMTP server address (required)
- `--port`: SMTP server port (default: 587)
- `--from`: Sender email address (required)
- `--to`: Recipient email address (required)
- `--subject`: Email subject (required)
- `--body`: Email body text
- `--html-body`: Email body in HTML format
- `--username`: SMTP username for authentication
- `--password`: SMTP password for authentication
- `--attachments`: File paths to attach (space-separated)
- `--no-tls`: Disable TLS encryption
- `--ssl`: Use SSL instead of TLS

## Configuration

### Server Configuration

The server can be configured via command-line arguments:

```bash
# Production-like setup
python smtp_server.py --host 0.0.0.0 --port 25 --mail-dir /var/mail/received
```

### Client Configuration

For repeated use, you can create shell scripts or batch files:

**send_email.sh** (Linux/Mac):
```bash
#!/bin/bash
python smtp_client.py --server localhost --port 1025 --from "$1" --to "$2" --subject "$3" --body "$4"
```

**send_email.bat** (Windows):
```batch
@echo off
python smtp_client.py --server localhost --port 1025 --from %1 --to %2 --subject %3 --body %4
```

## Security Considerations

1. **Default Port**: The server uses port 1025 by default (non-privileged port). Use port 25 for production.
2. **Authentication**: The server doesn't implement authentication by default. Consider adding authentication for production use.
3. **Encryption**: The client supports TLS/SSL. Always use encryption for production email sending.
4. **Firewall**: Ensure appropriate firewall rules are in place when running the server.

## Troubleshooting

### Common Issues

1. **Permission Denied (Port < 1024)**:
   - Run with sudo/administrator privileges, or use a port > 1024

2. **Connection Refused**:
   - Ensure the server is running
   - Check firewall settings
   - Verify host/port configuration

3. **Authentication Failed**:
   - Verify username/password
   - For Gmail, use App Passwords
   - Check if 2FA is enabled

4. **TLS/SSL Errors**:
   - Try using `--no-tls` for local testing
   - Verify server supports the encryption method

### Logging

Both server and client provide detailed logging. Check the console output for error messages and debugging information.

## File Structure

```
.
├── smtp_server.py          # SMTP server implementation
├── smtp_client.py          # SMTP client implementation
├── README.md              # This documentation
├── requirements.txt       # Python dependencies
├── examples/              # Example scripts
│   ├── test_local.py     # Local testing example
│   └── send_bulk.py      # Bulk email sending example
└── received_emails/       # Default directory for received emails (created automatically)
```

## License

This project is provided as-is for educational and testing purposes. Use responsibly and in accordance with your local laws and regulations regarding email transmission.#   s m t p - w e b - a p p  
 
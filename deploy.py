#!/usr/bin/env python3
"""
Deployment Tools for SMTP Web Application
Handles deployment to different environments (development, production, docker).
"""

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path
from typing import Dict, List, Optional
import platform
import tempfile
import zipfile
from datetime import datetime

class DeploymentManager:
    """Deployment management for SMTP Web Application"""
    
    def __init__(self, base_dir: Optional[Path] = None):
        self.base_dir = Path(base_dir) if base_dir else Path.cwd()
        self.system = platform.system().lower()
        self.deployments_dir = self.base_dir / 'deployments'
        self.deployments_dir.mkdir(exist_ok=True)
        
    def create_production_package(self) -> Path:
        """Create production deployment package"""
        print("📦 Creating production deployment package...")
        
        # Create package directory
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        package_name = f"smtp_webapp_production_{timestamp}"
        package_dir = self.deployments_dir / package_name
        package_dir.mkdir(exist_ok=True)
        
        # Files to include in production package
        production_files = [
            'smtp_server.py',
            'smtp_client.py',
            'web_interface.py',
            'config_manager.py',
            'service_manager.py',
            'install.py',
            'requirements.txt',
            'web_requirements.txt',
            'templates/',
            'static/',
            'README.md'
        ]
        
        # Copy files
        for file_path in production_files:
            src = self.base_dir / file_path
            if src.exists():
                if src.is_dir():
                    shutil.copytree(src, package_dir / file_path, dirs_exist_ok=True)
                else:
                    shutil.copy2(src, package_dir / file_path)
                print(f"  ✅ {file_path}")
            else:
                print(f"  ⚠️  {file_path} (not found)")
                
        # Create production configuration
        self._create_production_config(package_dir)
        
        # Create deployment scripts
        self._create_deployment_scripts(package_dir)
        
        # Create Docker files
        self._create_docker_files(package_dir)
        
        # Create systemd service files (Linux)
        self._create_systemd_files(package_dir)
        
        # Create archive
        archive_path = self.deployments_dir / f"{package_name}.zip"
        with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(package_dir):
                for file in files:
                    file_path = Path(root) / file
                    arcname = file_path.relative_to(package_dir)
                    zipf.write(file_path, arcname)
                    
        print(f"✅ Production package created: {archive_path}")
        return archive_path
        
    def _create_production_config(self, package_dir: Path):
        """Create production configuration files"""
        config_dir = package_dir / 'config'
        config_dir.mkdir(exist_ok=True)
        
        # Production app config
        prod_config = {
            'smtp_server': {
                'host': '0.0.0.0',
                'port': 1025,
                'debug': False,
                'max_message_size': 10485760,
                'timeout': 30,
                'auth_required': False,
                'tls_enabled': False
            },
            'web_interface': {
                'host': '0.0.0.0',
                'port': 5000,
                'debug': False,
                'secret_key': '',
                'session_timeout': 3600,
                'max_content_length': 16777216
            },
            'email_storage': {
                'directory': '/var/lib/smtp-webapp/emails',
                'max_size_mb': 1000,
                'auto_cleanup': True,
                'cleanup_days': 30,
                'backup_enabled': True,
                'backup_directory': '/var/lib/smtp-webapp/backups'
            },
            'logging': {
                'level': 'INFO',
                'file': '/var/log/smtp-webapp/app.log',
                'max_size_mb': 50,
                'backup_count': 10,
                'format': '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
            },
            'security': {
                'allowed_hosts': ['localhost', '127.0.0.1'],
                'rate_limit_enabled': True,
                'max_requests_per_minute': 100,
                'csrf_protection': True,
                'secure_headers': True
            }
        }
        
        with open(config_dir / 'production.json', 'w') as f:
            json.dump(prod_config, f, indent=2)
            
        # Production environment file
        prod_env = """# Production Environment Configuration
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=CHANGE_THIS_IN_PRODUCTION

# SMTP Server Settings
SMTP_HOST=0.0.0.0
SMTP_PORT=1025
SMTP_DEBUG=False

# Web Interface Settings
WEB_HOST=0.0.0.0
WEB_PORT=5000

# Email Storage
EMAIL_DIR=/var/lib/smtp-webapp/emails
MAX_EMAIL_SIZE_MB=1000

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/smtp-webapp/app.log

# Security
ALLOWED_HOSTS=localhost,127.0.0.1
RATE_LIMIT_ENABLED=True
MAX_REQUESTS_PER_MINUTE=100
"""
        
        with open(package_dir / '.env.production', 'w') as f:
            f.write(prod_env)
            
        print("  ✅ Production configuration files")
        
    def _create_deployment_scripts(self, package_dir: Path):
        """Create deployment scripts"""
        scripts_dir = package_dir / 'scripts'
        scripts_dir.mkdir(exist_ok=True)
        
        # Linux deployment script
        linux_deploy = """#!/bin/bash
set -e

echo "🚀 SMTP Web Application - Production Deployment"
echo "=============================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root for security reasons"
   echo "   Please run as a regular user with sudo privileges"
   exit 1
fi

# Configuration
APP_USER="smtp-webapp"
APP_DIR="/opt/smtp-webapp"
DATA_DIR="/var/lib/smtp-webapp"
LOG_DIR="/var/log/smtp-webapp"
SERVICE_NAME="smtp-webapp"

echo "📋 Deployment Configuration:"
echo "   Application User: $APP_USER"
echo "   Application Directory: $APP_DIR"
echo "   Data Directory: $DATA_DIR"
echo "   Log Directory: $LOG_DIR"
echo

# Create application user
echo "👤 Creating application user..."
if ! id "$APP_USER" &>/dev/null; then
    sudo useradd -r -s /bin/false -d "$APP_DIR" "$APP_USER"
    echo "   ✅ User $APP_USER created"
else
    echo "   ✅ User $APP_USER already exists"
fi

# Create directories
echo "📁 Creating directories..."
sudo mkdir -p "$APP_DIR" "$DATA_DIR" "$LOG_DIR"
sudo mkdir -p "$DATA_DIR/emails" "$DATA_DIR/backups"
sudo chown -R "$APP_USER:$APP_USER" "$APP_DIR" "$DATA_DIR" "$LOG_DIR"
echo "   ✅ Directories created"

# Install Python dependencies
echo "📦 Installing Python dependencies..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv
echo "   ✅ Python installed"

# Copy application files
echo "📋 Copying application files..."
sudo cp -r . "$APP_DIR/"
sudo chown -R "$APP_USER:$APP_USER" "$APP_DIR"
echo "   ✅ Application files copied"

# Create virtual environment
echo "🐍 Creating Python virtual environment..."
sudo -u "$APP_USER" python3 -m venv "$APP_DIR/venv"
sudo -u "$APP_USER" "$APP_DIR/venv/bin/pip" install -r "$APP_DIR/requirements.txt"
echo "   ✅ Virtual environment created"

# Install systemd service
echo "🔧 Installing systemd service..."
sudo cp systemd/smtp-webapp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable smtp-webapp
echo "   ✅ Systemd service installed"

# Setup log rotation
echo "📝 Setting up log rotation..."
sudo cp logrotate/smtp-webapp /etc/logrotate.d/
echo "   ✅ Log rotation configured"

# Setup firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    echo "🔥 Configuring firewall..."
    sudo ufw allow 5000/tcp comment "SMTP Web App"
    sudo ufw allow 1025/tcp comment "SMTP Server"
    echo "   ✅ Firewall configured"
fi

# Start services
echo "🚀 Starting services..."
sudo systemctl start smtp-webapp
sudo systemctl status smtp-webapp --no-pager
echo "   ✅ Services started"

echo
echo "🎉 Deployment completed successfully!"
echo
echo "📋 Service Information:"
echo "   Web Interface: http://localhost:5000"
echo "   SMTP Server: localhost:1025"
echo "   Status: sudo systemctl status smtp-webapp"
echo "   Logs: sudo journalctl -u smtp-webapp -f"
echo "   Stop: sudo systemctl stop smtp-webapp"
echo "   Start: sudo systemctl start smtp-webapp"
echo
"""
        
        with open(scripts_dir / 'deploy_linux.sh', 'w') as f:
            f.write(linux_deploy)
        os.chmod(scripts_dir / 'deploy_linux.sh', 0o755)
        
        # Windows deployment script
        windows_deploy = """@echo off
echo 🚀 SMTP Web Application - Production Deployment
echo ==============================================
echo.

REM Configuration
set APP_DIR=C:\\smtp-webapp
set DATA_DIR=C:\\smtp-webapp\\data
set LOG_DIR=C:\\smtp-webapp\\logs

echo 📋 Deployment Configuration:
echo    Application Directory: %APP_DIR%
echo    Data Directory: %DATA_DIR%
echo    Log Directory: %LOG_DIR%
echo.

REM Create directories
echo 📁 Creating directories...
mkdir "%APP_DIR%" 2>nul
mkdir "%DATA_DIR%" 2>nul
mkdir "%DATA_DIR%\\emails" 2>nul
mkdir "%DATA_DIR%\\backups" 2>nul
mkdir "%LOG_DIR%" 2>nul
echo    ✅ Directories created

REM Copy application files
echo 📋 Copying application files...
xcopy /E /I /Y . "%APP_DIR%"
echo    ✅ Application files copied

REM Install Python dependencies
echo 📦 Installing Python dependencies...
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
echo    ✅ Dependencies installed

REM Create Windows service (requires NSSM)
echo 🔧 Service installation...
echo    To install as Windows service, download NSSM from https://nssm.cc/
echo    Then run: nssm install smtp-webapp python "%APP_DIR%\\service_manager.py" start all
echo    ✅ Service instructions provided

REM Setup scheduled task for log cleanup
echo 📝 Setting up log cleanup...
schtasks /create /tn "SMTP WebApp Log Cleanup" /tr "python \"%APP_DIR%\\service_manager.py\" cleanup" /sc daily /st 02:00 /f
echo    ✅ Log cleanup scheduled

echo.
echo 🎉 Deployment completed successfully!
echo.
echo 📋 Service Information:
echo    Web Interface: http://localhost:5000
echo    SMTP Server: localhost:1025
echo    Start: python "%APP_DIR%\\service_manager.py" start all
echo    Stop: python "%APP_DIR%\\service_manager.py" stop all
echo    Status: python "%APP_DIR%\\service_manager.py" status
echo.
pause
"""
        
        with open(scripts_dir / 'deploy_windows.bat', 'w') as f:
            f.write(windows_deploy)
            
        print("  ✅ Deployment scripts")
        
    def _create_docker_files(self, package_dir: Path):
        """Create Docker deployment files"""
        docker_dir = package_dir / 'docker'
        docker_dir.mkdir(exist_ok=True)
        
        # Dockerfile
        dockerfile = """FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    gcc \\
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt web_requirements.txt ./

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt && \\
    pip install --no-cache-dir -r web_requirements.txt

# Copy application code
COPY . .

# Create directories
RUN mkdir -p /app/emails /app/logs /app/config

# Create non-root user
RUN useradd -r -s /bin/false -d /app smtp-webapp && \\
    chown -R smtp-webapp:smtp-webapp /app

# Switch to non-root user
USER smtp-webapp

# Expose ports
EXPOSE 5000 1025

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \\
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Start services
CMD ["python", "service_manager.py", "start", "--service", "all", "--background", "false"]
"""
        
        with open(docker_dir / 'Dockerfile', 'w') as f:
            f.write(dockerfile)
            
        # Docker Compose
        docker_compose = """version: '3.8'

services:
  smtp-webapp:
    build: .
    container_name: smtp-webapp
    ports:
      - "5000:5000"
      - "1025:1025"
    volumes:
      - smtp_emails:/app/emails
      - smtp_logs:/app/logs
      - smtp_config:/app/config
    environment:
      - FLASK_ENV=production
      - FLASK_DEBUG=false
      - SMTP_HOST=0.0.0.0
      - SMTP_PORT=1025
      - WEB_HOST=0.0.0.0
      - WEB_PORT=5000
      - EMAIL_DIR=/app/emails
      - LOG_FILE=/app/logs/smtp_app.log
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:5000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  smtp_emails:
    driver: local
  smtp_logs:
    driver: local
  smtp_config:
    driver: local

networks:
  default:
    name: smtp-webapp-network
"""
        
        with open(docker_dir / 'docker-compose.yml', 'w') as f:
            f.write(docker_compose)
            
        # Docker build script
        docker_build = """#!/bin/bash
set -e

echo "🐳 Building SMTP Web Application Docker Image"
echo "============================================="

# Build image
echo "📦 Building Docker image..."
docker build -t smtp-webapp:latest .

# Tag with version
VERSION=$(date +%Y%m%d-%H%M%S)
docker tag smtp-webapp:latest smtp-webapp:$VERSION

echo "✅ Docker image built successfully!"
echo "   Image: smtp-webapp:latest"
echo "   Tagged: smtp-webapp:$VERSION"
echo
echo "🚀 To run with Docker Compose:"
echo "   docker-compose up -d"
echo
echo "🚀 To run with Docker:"
echo "   docker run -d -p 5000:5000 -p 1025:1025 --name smtp-webapp smtp-webapp:latest"
"""
        
        with open(docker_dir / 'build.sh', 'w') as f:
            f.write(docker_build)
        os.chmod(docker_dir / 'build.sh', 0o755)
        
        print("  ✅ Docker files")
        
    def _create_systemd_files(self, package_dir: Path):
        """Create systemd service files for Linux"""
        systemd_dir = package_dir / 'systemd'
        systemd_dir.mkdir(exist_ok=True)
        
        # Main service file
        service_file = """[Unit]
Description=SMTP Web Application
After=network.target
Wants=network.target

[Service]
Type=forking
User=smtp-webapp
Group=smtp-webapp
WorkingDirectory=/opt/smtp-webapp
Environment=PATH=/opt/smtp-webapp/venv/bin
Environment=FLASK_ENV=production
Environment=FLASK_DEBUG=false
ExecStart=/opt/smtp-webapp/venv/bin/python service_manager.py start all
ExecStop=/opt/smtp-webapp/venv/bin/python service_manager.py stop all
ExecReload=/opt/smtp-webapp/venv/bin/python service_manager.py restart all
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=smtp-webapp

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/smtp-webapp /var/lib/smtp-webapp /var/log/smtp-webapp

[Install]
WantedBy=multi-user.target
"""
        
        with open(systemd_dir / 'smtp-webapp.service', 'w') as f:
            f.write(service_file)
            
        # Log rotation configuration
        logrotate_dir = package_dir / 'logrotate'
        logrotate_dir.mkdir(exist_ok=True)
        
        logrotate_config = """/var/log/smtp-webapp/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 smtp-webapp smtp-webapp
    postrotate
        systemctl reload smtp-webapp > /dev/null 2>&1 || true
    endscript
}
"""
        
        with open(logrotate_dir / 'smtp-webapp', 'w') as f:
            f.write(logrotate_config)
            
        print("  ✅ Systemd service files")
        
    def create_development_setup(self) -> Path:
        """Create development environment setup"""
        print("🛠️  Creating development setup...")
        
        dev_dir = self.deployments_dir / 'development'
        dev_dir.mkdir(exist_ok=True)
        
        # Development configuration
        dev_config = {
            'smtp_server': {
                'host': 'localhost',
                'port': 1025,
                'debug': True,
                'max_message_size': 10485760,
                'timeout': 30
            },
            'web_interface': {
                'host': '127.0.0.1',
                'port': 5000,
                'debug': True,
                'secret_key': 'dev-secret-key-change-in-production'
            },
            'email_storage': {
                'directory': 'emails',
                'max_size_mb': 50,
                'auto_cleanup': False
            },
            'logging': {
                'level': 'DEBUG',
                'file': 'logs/smtp_app_dev.log'
            }
        }
        
        with open(dev_dir / 'development.json', 'w') as f:
            json.dump(dev_config, f, indent=2)
            
        # Development environment file
        dev_env = """# Development Environment Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=dev-secret-key-change-in-production

# SMTP Server Settings
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_DEBUG=True

# Web Interface Settings
WEB_HOST=127.0.0.1
WEB_PORT=5000

# Email Storage
EMAIL_DIR=emails
MAX_EMAIL_SIZE_MB=50

# Logging
LOG_LEVEL=DEBUG
LOG_FILE=logs/smtp_app_dev.log
"""
        
        with open(dev_dir / '.env.development', 'w') as f:
            f.write(dev_env)
            
        # Development startup script
        dev_start = """#!/bin/bash
echo "🛠️  Starting SMTP Web Application - Development Mode"
echo "=================================================="

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "🐍 Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    echo "   ✅ Virtual environment created"
else
    source venv/bin/activate
    echo "   ✅ Virtual environment activated"
fi

# Copy development configuration
cp deployments/development/.env.development .env
cp deployments/development/development.json config/app_config.json

echo "🚀 Starting development server..."
echo "   Web Interface: http://localhost:5000"
echo "   SMTP Server: localhost:1025"
echo "   Press Ctrl+C to stop"
echo

python service_manager.py start all
"""
        
        with open(dev_dir / 'start_dev.sh', 'w') as f:
            f.write(dev_start)
        os.chmod(dev_dir / 'start_dev.sh', 0o755)
        
        print(f"✅ Development setup created: {dev_dir}")
        return dev_dir
        
    def create_testing_environment(self) -> Path:
        """Create testing environment setup"""
        print("🧪 Creating testing environment...")
        
        test_dir = self.deployments_dir / 'testing'
        test_dir.mkdir(exist_ok=True)
        
        # Test configuration
        test_config = {
            'smtp_server': {
                'host': 'localhost',
                'port': 1026,  # Different port for testing
                'debug': True
            },
            'web_interface': {
                'host': '127.0.0.1',
                'port': 5001,  # Different port for testing
                'debug': False,
                'secret_key': 'test-secret-key'
            },
            'email_storage': {
                'directory': 'test_emails',
                'max_size_mb': 10,
                'auto_cleanup': True,
                'cleanup_days': 1
            },
            'logging': {
                'level': 'INFO',
                'file': 'logs/smtp_app_test.log'
            }
        }
        
        with open(test_dir / 'testing.json', 'w') as f:
            json.dump(test_config, f, indent=2)
            
        # Test runner script
        test_runner = """#!/usr/bin/env python3
import unittest
import sys
import os
import time
import requests
import subprocess
from pathlib import Path

class SMTPWebAppTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        \"\"\"Start services for testing\"\"\"
        print("🚀 Starting test services...")
        
        # Copy test configuration
        os.system("cp deployments/testing/.env.testing .env")
        os.system("cp deployments/testing/testing.json config/app_config.json")
        
        # Start services
        cls.service_process = subprocess.Popen([
            sys.executable, "service_manager.py", "start", "all"
        ])
        
        # Wait for services to start
        time.sleep(5)
        
    @classmethod
    def tearDownClass(cls):
        \"\"\"Stop services after testing\"\"\"
        print("🛑 Stopping test services...")
        os.system(f"{sys.executable} service_manager.py stop all")
        
    def test_web_interface_health(self):
        \"\"\"Test web interface is responding\"\"\"
        response = requests.get("http://localhost:5001/")
        self.assertEqual(response.status_code, 200)
        
    def test_smtp_server_port(self):
        \"\"\"Test SMTP server port is listening\"\"\"
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex(('localhost', 1026))
        sock.close()
        self.assertEqual(result, 0, "SMTP server port should be listening")
        
    def test_email_storage_directory(self):
        \"\"\"Test email storage directory exists\"\"\"
        self.assertTrue(Path("test_emails").exists())
        
    def test_configuration_loading(self):
        \"\"\"Test configuration is loaded correctly\"\"\"
        from config_manager import get_config
        config = get_config()
        self.assertEqual(config.smtp.port, 1026)
        self.assertEqual(config.web.port, 5001)

if __name__ == "__main__":
    unittest.main(verbosity=2)
"""
        
        with open(test_dir / 'run_tests.py', 'w') as f:
            f.write(test_runner)
        os.chmod(test_dir / 'run_tests.py', 0o755)
        
        # Test environment file
        test_env = """# Testing Environment Configuration
FLASK_ENV=testing
FLASK_DEBUG=False
SECRET_KEY=test-secret-key

# SMTP Server Settings
SMTP_HOST=localhost
SMTP_PORT=1026
SMTP_DEBUG=True

# Web Interface Settings
WEB_HOST=127.0.0.1
WEB_PORT=5001

# Email Storage
EMAIL_DIR=test_emails
MAX_EMAIL_SIZE_MB=10

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/smtp_app_test.log
"""
        
        with open(test_dir / '.env.testing', 'w') as f:
            f.write(test_env)
            
        print(f"✅ Testing environment created: {test_dir}")
        return test_dir
        
    def deploy_to_environment(self, environment: str) -> bool:
        """Deploy to specific environment"""
        print(f"🚀 Deploying to {environment} environment...")
        
        if environment == 'production':
            package_path = self.create_production_package()
            print(f"📦 Production package ready: {package_path}")
            print("📋 Next steps:")
            print("   1. Extract the package on your production server")
            print("   2. Run the appropriate deployment script:")
            print("      - Linux: ./scripts/deploy_linux.sh")
            print("      - Windows: scripts\\deploy_windows.bat")
            print("      - Docker: cd docker && docker-compose up -d")
            return True
            
        elif environment == 'development':
            dev_dir = self.create_development_setup()
            print("📋 To start development environment:")
            print(f"   cd {dev_dir}")
            print("   ./start_dev.sh")
            return True
            
        elif environment == 'testing':
            test_dir = self.create_testing_environment()
            print("📋 To run tests:")
            print(f"   cd {test_dir}")
            print("   python run_tests.py")
            return True
            
        else:
            print(f"❌ Unknown environment: {environment}")
            return False

def main():
    """CLI interface for deployment management"""
    import argparse
    
    parser = argparse.ArgumentParser(description='SMTP Web App Deployment Manager')
    parser.add_argument('action', choices=['package', 'deploy', 'docker', 'test'],
                       help='Deployment action')
    parser.add_argument('--environment', choices=['development', 'testing', 'production'],
                       default='production', help='Target environment')
    parser.add_argument('--output', type=str, help='Output directory for packages')
    
    args = parser.parse_args()
    
    manager = DeploymentManager()
    
    if args.action == 'package':
        if args.environment == 'production':
            package_path = manager.create_production_package()
            print(f"📦 Package created: {package_path}")
        else:
            print(f"❌ Packaging only available for production environment")
            
    elif args.action == 'deploy':
        success = manager.deploy_to_environment(args.environment)
        sys.exit(0 if success else 1)
        
    elif args.action == 'docker':
        package_path = manager.create_production_package()
        print("🐳 Docker deployment package created")
        print("📋 To build and run with Docker:")
        print("   cd deployments/[package_name]/docker")
        print("   ./build.sh")
        print("   docker-compose up -d")
        
    elif args.action == 'test':
        test_dir = manager.create_testing_environment()
        print("🧪 Test environment created")
        print(f"📋 Run tests with: cd {test_dir} && python run_tests.py")

if __name__ == "__main__":
    main()
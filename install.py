#!/usr/bin/env python3
"""
SMTP Web Application Installer
Automated installation and setup script for the complete SMTP server and client web application.
"""

import os
import sys
import subprocess
import json
import shutil
import platform
from pathlib import Path
import urllib.request
import zipfile
import tempfile

class SMTPWebAppInstaller:
    def __init__(self):
        self.system = platform.system().lower()
        self.python_exe = sys.executable
        self.install_dir = Path.cwd()
        self.config = {
            'smtp_server': {
                'host': 'localhost',
                'port': 1025,
                'debug': True
            },
            'web_interface': {
                'host': '0.0.0.0',
                'port': 5000,
                'debug': False
            },
            'email_storage': {
                'directory': 'emails',
                'max_size_mb': 100
            }
        }
        
    def print_banner(self):
        """Print installation banner"""
        banner = """
╔══════════════════════════════════════════════════════════════╗
║                    SMTP Web Application                      ║
║                    Installation Wizard                      ║
╠══════════════════════════════════════════════════════════════╣
║  Complete SMTP Server & Client with Web Interface           ║
║  • Email Server Management                                   ║
║  • Web-based Email Client                                    ║
║  • Modern Bootstrap UI                                       ║
║  • Real-time Email Monitoring                               ║
╚══════════════════════════════════════════════════════════════╝
        """
        print(banner)
        
    def check_python_version(self):
        """Check if Python version is compatible"""
        print("🐍 Checking Python version...")
        version = sys.version_info
        if version.major < 3 or (version.major == 3 and version.minor < 7):
            print("❌ Error: Python 3.7 or higher is required")
            print(f"   Current version: {version.major}.{version.minor}.{version.micro}")
            return False
        print(f"✅ Python {version.major}.{version.minor}.{version.micro} - Compatible")
        return True
        
    def install_dependencies(self):
        """Install required Python packages"""
        print("\n📦 Installing dependencies...")
        
        # Core dependencies
        dependencies = [
            'Flask>=2.3.0',
            'Werkzeug>=2.3.0',
            'Jinja2>=3.1.0',
            'MarkupSafe>=2.1.0',
            'itsdangerous>=2.1.0',
            'click>=8.1.0',
            'blinker>=1.6.0'
        ]
        
        # Optional dependencies
        optional_deps = [
            'dnspython>=2.3.0',
            'cryptography>=3.4.8',
            'email-validator>=1.3.0'
        ]
        
        try:
            # Install core dependencies
            for dep in dependencies:
                print(f"  Installing {dep}...")
                result = subprocess.run([
                    self.python_exe, '-m', 'pip', 'install', dep
                ], capture_output=True, text=True)
                
                if result.returncode != 0:
                    print(f"❌ Failed to install {dep}")
                    print(f"   Error: {result.stderr}")
                    return False
                    
            # Install optional dependencies (non-critical)
            print("  Installing optional dependencies...")
            for dep in optional_deps:
                try:
                    subprocess.run([
                        self.python_exe, '-m', 'pip', 'install', dep
                    ], capture_output=True, text=True, check=True)
                    print(f"  ✅ {dep}")
                except subprocess.CalledProcessError:
                    print(f"  ⚠️  {dep} (optional - skipped)")
                    
            print("✅ All dependencies installed successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error installing dependencies: {e}")
            return False
            
    def create_directories(self):
        """Create necessary directories"""
        print("\n📁 Creating directory structure...")
        
        directories = [
            'emails',
            'logs',
            'config',
            'static/css',
            'static/js',
            'static/images',
            'templates',
            'backups'
        ]
        
        try:
            for directory in directories:
                dir_path = self.install_dir / directory
                dir_path.mkdir(parents=True, exist_ok=True)
                print(f"  ✅ {directory}/")
                
            print("✅ Directory structure created")
            return True
            
        except Exception as e:
            print(f"❌ Error creating directories: {e}")
            return False
            
    def create_config_files(self):
        """Create configuration files"""
        print("\n⚙️  Creating configuration files...")
        
        try:
            # Main configuration
            config_file = self.install_dir / 'config' / 'app_config.json'
            with open(config_file, 'w') as f:
                json.dump(self.config, f, indent=4)
            print("  ✅ app_config.json")
            
            # Environment configuration
            env_file = self.install_dir / '.env'
            env_content = f"""# SMTP Web Application Environment Configuration
FLASK_APP=web_interface.py
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY={os.urandom(24).hex()}

# SMTP Server Settings
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_DEBUG=True

# Web Interface Settings
WEB_HOST=0.0.0.0
WEB_PORT=5000

# Email Storage
EMAIL_DIR=emails
MAX_EMAIL_SIZE_MB=100

# Logging
LOG_LEVEL=INFO
LOG_FILE=logs/smtp_app.log
"""
            with open(env_file, 'w') as f:
                f.write(env_content)
            print("  ✅ .env")
            
            # Logging configuration
            log_config = {
                "version": 1,
                "disable_existing_loggers": False,
                "formatters": {
                    "standard": {
                        "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
                    }
                },
                "handlers": {
                    "default": {
                        "level": "INFO",
                        "formatter": "standard",
                        "class": "logging.StreamHandler"
                    },
                    "file": {
                        "level": "INFO",
                        "formatter": "standard",
                        "class": "logging.FileHandler",
                        "filename": "logs/smtp_app.log",
                        "mode": "a"
                    }
                },
                "loggers": {
                    "": {
                        "handlers": ["default", "file"],
                        "level": "INFO",
                        "propagate": False
                    }
                }
            }
            
            log_config_file = self.install_dir / 'config' / 'logging.json'
            with open(log_config_file, 'w') as f:
                json.dump(log_config, f, indent=4)
            print("  ✅ logging.json")
            
            print("✅ Configuration files created")
            return True
            
        except Exception as e:
            print(f"❌ Error creating configuration files: {e}")
            return False
            
    def create_service_scripts(self):
        """Create service management scripts"""
        print("\n🔧 Creating service scripts...")
        
        try:
            # Windows batch scripts
            if self.system == 'windows':
                # Start script
                start_script = self.install_dir / 'start_smtp_app.bat'
                start_content = f"""@echo off
title SMTP Web Application
echo Starting SMTP Web Application...
echo.

REM Start SMTP Server in background
echo Starting SMTP Server on port 1025...
start "SMTP Server" /MIN "{self.python_exe}" smtp_server.py --port 1025 --host localhost

REM Wait a moment for server to start
timeout /t 3 /nobreak >nul

REM Start Web Interface
echo Starting Web Interface on http://localhost:5000...
echo.
echo Web Interface will be available at: http://localhost:5000
echo SMTP Server is running on: localhost:1025
echo.
echo Press Ctrl+C to stop the web interface
echo Use Task Manager to stop the SMTP server if needed
echo.
"{self.python_exe}" web_interface.py

pause
"""
                with open(start_script, 'w') as f:
                    f.write(start_content)
                print("  ✅ start_smtp_app.bat")
                
                # Stop script
                stop_script = self.install_dir / 'stop_smtp_app.bat'
                stop_content = """@echo off
echo Stopping SMTP Web Application...

REM Kill Python processes related to SMTP
taskkill /F /IM python.exe /FI "WINDOWTITLE eq SMTP Server*" 2>nul
taskkill /F /IM python.exe /FI "COMMANDLINE eq *smtp_server.py*" 2>nul
taskkill /F /IM python.exe /FI "COMMANDLINE eq *web_interface.py*" 2>nul

echo SMTP Web Application stopped.
pause
"""
                with open(stop_script, 'w') as f:
                    f.write(stop_content)
                print("  ✅ stop_smtp_app.bat")
                
            # Unix shell scripts
            else:
                # Start script
                start_script = self.install_dir / 'start_smtp_app.sh'
                start_content = f"""#!/bin/bash
echo "Starting SMTP Web Application..."
echo

# Start SMTP Server in background
echo "Starting SMTP Server on port 1025..."
nohup "{self.python_exe}" smtp_server.py --port 1025 --host localhost > logs/smtp_server.log 2>&1 &
SMTP_PID=$!
echo $SMTP_PID > logs/smtp_server.pid

# Wait for server to start
sleep 3

# Start Web Interface
echo "Starting Web Interface on http://localhost:5000..."
echo
echo "Web Interface: http://localhost:5000"
echo "SMTP Server: localhost:1025"
echo "SMTP Server PID: $SMTP_PID"
echo
echo "Press Ctrl+C to stop"
echo

# Trap to cleanup on exit
trap 'kill $SMTP_PID 2>/dev/null; exit' INT TERM

"{self.python_exe}" web_interface.py
"""
                with open(start_script, 'w') as f:
                    f.write(start_content)
                os.chmod(start_script, 0o755)
                print("  ✅ start_smtp_app.sh")
                
                # Stop script
                stop_script = self.install_dir / 'stop_smtp_app.sh'
                stop_content = """#!/bin/bash
echo "Stopping SMTP Web Application..."

# Stop SMTP Server
if [ -f logs/smtp_server.pid ]; then
    PID=$(cat logs/smtp_server.pid)
    kill $PID 2>/dev/null
    rm logs/smtp_server.pid
    echo "SMTP Server stopped (PID: $PID)"
else
    # Fallback: kill by process name
    pkill -f "smtp_server.py"
    pkill -f "web_interface.py"
    echo "SMTP processes terminated"
fi

echo "SMTP Web Application stopped."
"""
                with open(stop_script, 'w') as f:
                    f.write(stop_content)
                os.chmod(stop_script, 0o755)
                print("  ✅ stop_smtp_app.sh")
                
            print("✅ Service scripts created")
            return True
            
        except Exception as e:
            print(f"❌ Error creating service scripts: {e}")
            return False
            
    def create_desktop_shortcut(self):
        """Create desktop shortcut (Windows only)"""
        if self.system != 'windows':
            return True
            
        print("\n🖥️  Creating desktop shortcut...")
        
        try:
            import winshell
            from win32com.client import Dispatch
            
            desktop = winshell.desktop()
            shortcut_path = os.path.join(desktop, "SMTP Web App.lnk")
            
            shell = Dispatch('WScript.Shell')
            shortcut = shell.CreateShortCut(shortcut_path)
            shortcut.Targetpath = str(self.install_dir / 'start_smtp_app.bat')
            shortcut.WorkingDirectory = str(self.install_dir)
            shortcut.IconLocation = str(self.install_dir / 'start_smtp_app.bat')
            shortcut.save()
            
            print("  ✅ Desktop shortcut created")
            return True
            
        except ImportError:
            print("  ⚠️  Desktop shortcut skipped (winshell not available)")
            return True
        except Exception as e:
            print(f"  ⚠️  Desktop shortcut failed: {e}")
            return True
            
    def run_tests(self):
        """Run basic functionality tests"""
        print("\n🧪 Running installation tests...")
        
        try:
            # Test imports
            print("  Testing imports...")
            test_imports = [
                'flask',
                'werkzeug',
                'jinja2',
                'smtplib',
                'email',
                'json',
                'os',
                'sys'
            ]
            
            for module in test_imports:
                try:
                    __import__(module)
                    print(f"    ✅ {module}")
                except ImportError as e:
                    print(f"    ❌ {module}: {e}")
                    return False
                    
            # Test file structure
            print("  Testing file structure...")
            required_files = [
                'smtp_server.py',
                'smtp_client.py',
                'web_interface.py',
                'templates/base.html',
                'templates/index.html',
                'config/app_config.json'
            ]
            
            for file_path in required_files:
                if (self.install_dir / file_path).exists():
                    print(f"    ✅ {file_path}")
                else:
                    print(f"    ❌ {file_path} - Missing")
                    return False
                    
            print("✅ All tests passed")
            return True
            
        except Exception as e:
            print(f"❌ Test failed: {e}")
            return False
            
    def print_completion_message(self):
        """Print installation completion message"""
        message = f"""
╔══════════════════════════════════════════════════════════════╗
║                    Installation Complete!                    ║
╚══════════════════════════════════════════════════════════════╝

🎉 SMTP Web Application has been successfully installed!

📁 Installation Directory: {self.install_dir}

🚀 Quick Start:
   Windows: Double-click 'start_smtp_app.bat'
   Linux/Mac: Run './start_smtp_app.sh'

🌐 Access Points:
   • Web Interface: http://localhost:5000
   • SMTP Server: localhost:1025

📋 What's Included:
   ✅ SMTP Server with email storage
   ✅ Web-based email client
   ✅ Modern Bootstrap UI
   ✅ Email composition and viewing
   ✅ Real-time monitoring
   ✅ Configuration management

📖 Documentation:
   • README.md - Complete usage guide
   • config/app_config.json - Application settings
   • .env - Environment variables

🛠️  Management:
   • Start: start_smtp_app.{('bat' if self.system == 'windows' else 'sh')}
   • Stop: stop_smtp_app.{('bat' if self.system == 'windows' else 'sh')}
   • Logs: logs/ directory

Need help? Check the README.md file for detailed instructions.
        """
        print(message)
        
    def install(self):
        """Run the complete installation process"""
        self.print_banner()
        
        steps = [
            ("Checking Python version", self.check_python_version),
            ("Installing dependencies", self.install_dependencies),
            ("Creating directories", self.create_directories),
            ("Creating configuration", self.create_config_files),
            ("Creating service scripts", self.create_service_scripts),
            ("Creating desktop shortcut", self.create_desktop_shortcut),
            ("Running tests", self.run_tests)
        ]
        
        for step_name, step_func in steps:
            if not step_func():
                print(f"\n❌ Installation failed at: {step_name}")
                print("Please check the error messages above and try again.")
                return False
                
        self.print_completion_message()
        return True

def main():
    """Main installation function"""
    installer = SMTPWebAppInstaller()
    
    try:
        success = installer.install()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Installation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error during installation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
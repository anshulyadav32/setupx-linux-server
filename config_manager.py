#!/usr/bin/env python3
"""
Configuration Management System
Handles all configuration loading, validation, and management for the SMTP Web Application.
"""

import os
import json
import logging
from pathlib import Path
from typing import Dict, Any, Optional, Union
from dataclasses import dataclass, asdict
from datetime import datetime

@dataclass
class SMTPConfig:
    """SMTP Server configuration"""
    host: str = 'localhost'
    port: int = 1025
    debug: bool = True
    max_message_size: int = 10485760  # 10MB
    timeout: int = 30
    auth_required: bool = False
    tls_enabled: bool = False
    
@dataclass
class WebConfig:
    """Web Interface configuration"""
    host: str = '0.0.0.0'
    port: int = 5000
    debug: bool = False
    secret_key: str = ''
    session_timeout: int = 3600
    max_content_length: int = 16777216  # 16MB
    
@dataclass
class EmailStorageConfig:
    """Email storage configuration"""
    directory: str = 'emails'
    max_size_mb: int = 100
    auto_cleanup: bool = True
    cleanup_days: int = 30
    backup_enabled: bool = True
    backup_directory: str = 'backups'
    
@dataclass
class LoggingConfig:
    """Logging configuration"""
    level: str = 'INFO'
    file: str = 'logs/smtp_app.log'
    max_size_mb: int = 10
    backup_count: int = 5
    format: str = '%(asctime)s [%(levelname)s] %(name)s: %(message)s'
    
@dataclass
class SecurityConfig:
    """Security configuration"""
    allowed_hosts: list = None
    rate_limit_enabled: bool = True
    max_requests_per_minute: int = 60
    csrf_protection: bool = True
    secure_headers: bool = True
    
    def __post_init__(self):
        if self.allowed_hosts is None:
            self.allowed_hosts = ['localhost', '127.0.0.1']

class ConfigManager:
    """Configuration management system"""
    
    def __init__(self, config_dir: Optional[Union[str, Path]] = None):
        self.config_dir = Path(config_dir) if config_dir else Path.cwd() / 'config'
        self.config_file = self.config_dir / 'app_config.json'
        self.env_file = Path.cwd() / '.env'
        
        # Configuration objects
        self.smtp = SMTPConfig()
        self.web = WebConfig()
        self.email_storage = EmailStorageConfig()
        self.logging = LoggingConfig()
        self.security = SecurityConfig()
        
        # Ensure config directory exists
        self.config_dir.mkdir(parents=True, exist_ok=True)
        
        # Load configurations
        self._load_environment()
        self._load_config_file()
        self._validate_config()
        
    def _load_environment(self):
        """Load configuration from environment variables and .env file"""
        # Load .env file if it exists
        if self.env_file.exists():
            with open(self.env_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        os.environ[key.strip()] = value.strip()
        
        # SMTP Configuration
        self.smtp.host = os.getenv('SMTP_HOST', self.smtp.host)
        self.smtp.port = int(os.getenv('SMTP_PORT', self.smtp.port))
        self.smtp.debug = os.getenv('SMTP_DEBUG', str(self.smtp.debug)).lower() == 'true'
        self.smtp.max_message_size = int(os.getenv('SMTP_MAX_MESSAGE_SIZE', self.smtp.max_message_size))
        self.smtp.timeout = int(os.getenv('SMTP_TIMEOUT', self.smtp.timeout))
        self.smtp.auth_required = os.getenv('SMTP_AUTH_REQUIRED', str(self.smtp.auth_required)).lower() == 'true'
        self.smtp.tls_enabled = os.getenv('SMTP_TLS_ENABLED', str(self.smtp.tls_enabled)).lower() == 'true'
        
        # Web Configuration
        self.web.host = os.getenv('WEB_HOST', self.web.host)
        self.web.port = int(os.getenv('WEB_PORT', self.web.port))
        self.web.debug = os.getenv('FLASK_DEBUG', str(self.web.debug)).lower() == 'true'
        self.web.secret_key = os.getenv('SECRET_KEY', self.web.secret_key)
        self.web.session_timeout = int(os.getenv('SESSION_TIMEOUT', self.web.session_timeout))
        self.web.max_content_length = int(os.getenv('MAX_CONTENT_LENGTH', self.web.max_content_length))
        
        # Email Storage Configuration
        self.email_storage.directory = os.getenv('EMAIL_DIR', self.email_storage.directory)
        self.email_storage.max_size_mb = int(os.getenv('MAX_EMAIL_SIZE_MB', self.email_storage.max_size_mb))
        self.email_storage.auto_cleanup = os.getenv('EMAIL_AUTO_CLEANUP', str(self.email_storage.auto_cleanup)).lower() == 'true'
        self.email_storage.cleanup_days = int(os.getenv('EMAIL_CLEANUP_DAYS', self.email_storage.cleanup_days))
        self.email_storage.backup_enabled = os.getenv('EMAIL_BACKUP_ENABLED', str(self.email_storage.backup_enabled)).lower() == 'true'
        self.email_storage.backup_directory = os.getenv('EMAIL_BACKUP_DIR', self.email_storage.backup_directory)
        
        # Logging Configuration
        self.logging.level = os.getenv('LOG_LEVEL', self.logging.level)
        self.logging.file = os.getenv('LOG_FILE', self.logging.file)
        self.logging.max_size_mb = int(os.getenv('LOG_MAX_SIZE_MB', self.logging.max_size_mb))
        self.logging.backup_count = int(os.getenv('LOG_BACKUP_COUNT', self.logging.backup_count))
        
        # Security Configuration
        allowed_hosts = os.getenv('ALLOWED_HOSTS')
        if allowed_hosts:
            self.security.allowed_hosts = [host.strip() for host in allowed_hosts.split(',')]
        self.security.rate_limit_enabled = os.getenv('RATE_LIMIT_ENABLED', str(self.security.rate_limit_enabled)).lower() == 'true'
        self.security.max_requests_per_minute = int(os.getenv('MAX_REQUESTS_PER_MINUTE', self.security.max_requests_per_minute))
        self.security.csrf_protection = os.getenv('CSRF_PROTECTION', str(self.security.csrf_protection)).lower() == 'true'
        self.security.secure_headers = os.getenv('SECURE_HEADERS', str(self.security.secure_headers)).lower() == 'true'
        
    def _load_config_file(self):
        """Load configuration from JSON file"""
        if not self.config_file.exists():
            self._create_default_config()
            return
            
        try:
            with open(self.config_file, 'r') as f:
                config_data = json.load(f)
                
            # Update configurations with file data
            if 'smtp_server' in config_data:
                smtp_data = config_data['smtp_server']
                for key, value in smtp_data.items():
                    if hasattr(self.smtp, key):
                        setattr(self.smtp, key, value)
                        
            if 'web_interface' in config_data:
                web_data = config_data['web_interface']
                for key, value in web_data.items():
                    if hasattr(self.web, key):
                        setattr(self.web, key, value)
                        
            if 'email_storage' in config_data:
                storage_data = config_data['email_storage']
                for key, value in storage_data.items():
                    if hasattr(self.email_storage, key):
                        setattr(self.email_storage, key, value)
                        
            if 'logging' in config_data:
                logging_data = config_data['logging']
                for key, value in logging_data.items():
                    if hasattr(self.logging, key):
                        setattr(self.logging, key, value)
                        
            if 'security' in config_data:
                security_data = config_data['security']
                for key, value in security_data.items():
                    if hasattr(self.security, key):
                        setattr(self.security, key, value)
                        
        except (json.JSONDecodeError, FileNotFoundError) as e:
            logging.warning(f"Could not load config file: {e}")
            self._create_default_config()
            
    def _create_default_config(self):
        """Create default configuration file"""
        default_config = {
            'smtp_server': asdict(self.smtp),
            'web_interface': asdict(self.web),
            'email_storage': asdict(self.email_storage),
            'logging': asdict(self.logging),
            'security': asdict(self.security),
            'metadata': {
                'created_at': datetime.now().isoformat(),
                'version': '1.0.0',
                'description': 'SMTP Web Application Configuration'
            }
        }
        
        with open(self.config_file, 'w') as f:
            json.dump(default_config, f, indent=4)
            
    def _validate_config(self):
        """Validate configuration values"""
        # Generate secret key if not provided
        if not self.web.secret_key:
            import secrets
            self.web.secret_key = secrets.token_hex(32)
            
        # Validate ports
        if not (1 <= self.smtp.port <= 65535):
            raise ValueError(f"Invalid SMTP port: {self.smtp.port}")
        if not (1 <= self.web.port <= 65535):
            raise ValueError(f"Invalid web port: {self.web.port}")
            
        # Validate directories
        email_dir = Path(self.email_storage.directory)
        email_dir.mkdir(parents=True, exist_ok=True)
        
        if self.email_storage.backup_enabled:
            backup_dir = Path(self.email_storage.backup_directory)
            backup_dir.mkdir(parents=True, exist_ok=True)
            
        # Validate logging
        log_dir = Path(self.logging.file).parent
        log_dir.mkdir(parents=True, exist_ok=True)
        
    def save_config(self):
        """Save current configuration to file"""
        config_data = {
            'smtp_server': asdict(self.smtp),
            'web_interface': asdict(self.web),
            'email_storage': asdict(self.email_storage),
            'logging': asdict(self.logging),
            'security': asdict(self.security),
            'metadata': {
                'updated_at': datetime.now().isoformat(),
                'version': '1.0.0',
                'description': 'SMTP Web Application Configuration'
            }
        }
        
        with open(self.config_file, 'w') as f:
            json.dump(config_data, f, indent=4)
            
    def get_flask_config(self) -> Dict[str, Any]:
        """Get Flask-specific configuration"""
        return {
            'SECRET_KEY': self.web.secret_key,
            'DEBUG': self.web.debug,
            'HOST': self.web.host,
            'PORT': self.web.port,
            'MAX_CONTENT_LENGTH': self.web.max_content_length,
            'PERMANENT_SESSION_LIFETIME': self.web.session_timeout,
            'SEND_FILE_MAX_AGE_DEFAULT': 31536000,  # 1 year
        }
        
    def get_smtp_config(self) -> Dict[str, Any]:
        """Get SMTP server configuration"""
        return asdict(self.smtp)
        
    def get_logging_config(self) -> Dict[str, Any]:
        """Get logging configuration"""
        return {
            'version': 1,
            'disable_existing_loggers': False,
            'formatters': {
                'standard': {
                    'format': self.logging.format
                }
            },
            'handlers': {
                'default': {
                    'level': self.logging.level,
                    'formatter': 'standard',
                    'class': 'logging.StreamHandler'
                },
                'file': {
                    'level': self.logging.level,
                    'formatter': 'standard',
                    'class': 'logging.handlers.RotatingFileHandler',
                    'filename': self.logging.file,
                    'maxBytes': self.logging.max_size_mb * 1024 * 1024,
                    'backupCount': self.logging.backup_count
                }
            },
            'loggers': {
                '': {
                    'handlers': ['default', 'file'],
                    'level': self.logging.level,
                    'propagate': False
                }
            }
        }
        
    def update_config(self, section: str, **kwargs):
        """Update configuration section"""
        if section == 'smtp':
            config_obj = self.smtp
        elif section == 'web':
            config_obj = self.web
        elif section == 'email_storage':
            config_obj = self.email_storage
        elif section == 'logging':
            config_obj = self.logging
        elif section == 'security':
            config_obj = self.security
        else:
            raise ValueError(f"Unknown configuration section: {section}")
            
        for key, value in kwargs.items():
            if hasattr(config_obj, key):
                setattr(config_obj, key, value)
            else:
                raise ValueError(f"Unknown configuration key: {key}")
                
        self._validate_config()
        self.save_config()
        
    def reset_to_defaults(self):
        """Reset configuration to defaults"""
        self.smtp = SMTPConfig()
        self.web = WebConfig()
        self.email_storage = EmailStorageConfig()
        self.logging = LoggingConfig()
        self.security = SecurityConfig()
        
        self._validate_config()
        self.save_config()
        
    def export_config(self, file_path: Union[str, Path]):
        """Export configuration to file"""
        config_data = {
            'smtp_server': asdict(self.smtp),
            'web_interface': asdict(self.web),
            'email_storage': asdict(self.email_storage),
            'logging': asdict(self.logging),
            'security': asdict(self.security),
            'metadata': {
                'exported_at': datetime.now().isoformat(),
                'version': '1.0.0',
                'description': 'SMTP Web Application Configuration Export'
            }
        }
        
        with open(file_path, 'w') as f:
            json.dump(config_data, f, indent=4)
            
    def import_config(self, file_path: Union[str, Path]):
        """Import configuration from file"""
        with open(file_path, 'r') as f:
            config_data = json.load(f)
            
        # Backup current config
        backup_path = self.config_dir / f'app_config_backup_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        self.export_config(backup_path)
        
        # Import new config
        if 'smtp_server' in config_data:
            self.smtp = SMTPConfig(**config_data['smtp_server'])
        if 'web_interface' in config_data:
            self.web = WebConfig(**config_data['web_interface'])
        if 'email_storage' in config_data:
            self.email_storage = EmailStorageConfig(**config_data['email_storage'])
        if 'logging' in config_data:
            self.logging = LoggingConfig(**config_data['logging'])
        if 'security' in config_data:
            self.security = SecurityConfig(**config_data['security'])
            
        self._validate_config()
        self.save_config()
        
    def get_status(self) -> Dict[str, Any]:
        """Get configuration status and summary"""
        return {
            'config_file': str(self.config_file),
            'config_exists': self.config_file.exists(),
            'env_file': str(self.env_file),
            'env_exists': self.env_file.exists(),
            'smtp_port': self.smtp.port,
            'web_port': self.web.port,
            'email_directory': self.email_storage.directory,
            'log_file': self.logging.file,
            'debug_mode': self.web.debug,
            'last_modified': datetime.fromtimestamp(self.config_file.stat().st_mtime).isoformat() if self.config_file.exists() else None
        }

# Global configuration instance
config = None

def get_config() -> ConfigManager:
    """Get global configuration instance"""
    global config
    if config is None:
        config = ConfigManager()
    return config

def init_config(config_dir: Optional[Union[str, Path]] = None) -> ConfigManager:
    """Initialize global configuration"""
    global config
    config = ConfigManager(config_dir)
    return config

if __name__ == "__main__":
    # CLI for configuration management
    import argparse
    
    parser = argparse.ArgumentParser(description='SMTP Web App Configuration Manager')
    parser.add_argument('--show', action='store_true', help='Show current configuration')
    parser.add_argument('--reset', action='store_true', help='Reset to default configuration')
    parser.add_argument('--export', type=str, help='Export configuration to file')
    parser.add_argument('--import', type=str, dest='import_file', help='Import configuration from file')
    parser.add_argument('--status', action='store_true', help='Show configuration status')
    
    args = parser.parse_args()
    
    config_manager = ConfigManager()
    
    if args.show:
        print(json.dumps({
            'smtp_server': asdict(config_manager.smtp),
            'web_interface': asdict(config_manager.web),
            'email_storage': asdict(config_manager.email_storage),
            'logging': asdict(config_manager.logging),
            'security': asdict(config_manager.security)
        }, indent=2))
        
    elif args.reset:
        config_manager.reset_to_defaults()
        print("Configuration reset to defaults")
        
    elif args.export:
        config_manager.export_config(args.export)
        print(f"Configuration exported to {args.export}")
        
    elif args.import_file:
        config_manager.import_config(args.import_file)
        print(f"Configuration imported from {args.import_file}")
        
    elif args.status:
        status = config_manager.get_status()
        print(json.dumps(status, indent=2))
        
    else:
        parser.print_help()
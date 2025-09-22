#!/usr/bin/env python3
"""
Domain Management System
Handles domain configuration, validation, and management for the SMTP Web Application.
"""

import sqlite3
import json
import logging
import re
import socket
import subprocess
from pathlib import Path
from typing import List, Dict, Any, Tuple, Optional
from datetime import datetime
import dns.resolver
import dns.exception

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DomainManager:
    """Domain management system for SMTP server"""
    
    def __init__(self, db_path: str = "data/domains.db", config_path: str = "config/app_config.json"):
        self.db_path = db_path
        self.config_path = config_path
        self.config = self._load_config()
        
        # Ensure data directory exists
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)
        
        # Initialize database
        self._init_database()
        
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from file"""
        try:
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                return config.get('domains', {})
        except Exception as e:
            logger.error(f"Error loading config: {e}")
            return {}
    
    def _init_database(self):
        """Initialize the domains database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Create domains table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS domains (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    domain_name TEXT UNIQUE NOT NULL,
                    description TEXT,
                    is_active BOOLEAN DEFAULT 1,
                    is_local BOOLEAN DEFAULT 1,
                    relay_host TEXT,
                    relay_port INTEGER,
                    relay_username TEXT,
                    relay_password TEXT,
                    use_tls BOOLEAN DEFAULT 0,
                    use_ssl BOOLEAN DEFAULT 0,
                    max_message_size INTEGER DEFAULT 10485760,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Create domain aliases table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS domain_aliases (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    domain_id INTEGER,
                    alias_domain TEXT UNIQUE NOT NULL,
                    is_active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (domain_id) REFERENCES domains (id) ON DELETE CASCADE
                )
            ''')
            
            # Create domain statistics table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS domain_stats (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    domain_id INTEGER,
                    emails_received INTEGER DEFAULT 0,
                    emails_sent INTEGER DEFAULT 0,
                    last_activity TIMESTAMP,
                    total_size_bytes INTEGER DEFAULT 0,
                    FOREIGN KEY (domain_id) REFERENCES domains (id) ON DELETE CASCADE
                )
            ''')
            
            conn.commit()
            
            # Add default domains if none exist
            cursor.execute('SELECT COUNT(*) FROM domains')
            if cursor.fetchone()[0] == 0:
                self._add_default_domains(cursor)
                conn.commit()
            
            conn.close()
            logger.info("Domain database initialized successfully")
            
        except Exception as e:
            logger.error(f"Error initializing domain database: {e}")
            raise
    
    def _add_default_domains(self, cursor):
        """Add default domains from configuration"""
        default_domains = self.config.get('allowed_domains', ['localhost'])
        default_domain = self.config.get('default_domain', 'localhost')
        
        for domain in default_domains:
            is_default = domain == default_domain
            cursor.execute('''
                INSERT INTO domains (domain_name, description, is_active, is_local)
                VALUES (?, ?, 1, 1)
            ''', (domain, f"Default domain - {domain}" if is_default else f"Allowed domain - {domain}"))
            
            # Add stats entry
            domain_id = cursor.lastrowid
            cursor.execute('''
                INSERT INTO domain_stats (domain_id, emails_received, emails_sent, last_activity)
                VALUES (?, 0, 0, CURRENT_TIMESTAMP)
            ''', (domain_id,))
    
    def add_domain(self, domain_name: str, description: str = "", is_local: bool = True, 
                   relay_config: Optional[Dict[str, Any]] = None) -> Tuple[bool, str]:
        """Add a new domain"""
        try:
            # Validate domain name
            if not self._validate_domain_name(domain_name):
                return False, "Invalid domain name format"
            
            # Check if domain already exists
            if self.domain_exists(domain_name):
                return False, "Domain already exists"
            
            # Validate domain if enabled
            if self.config.get('domain_validation', {}).get('check_dns', False):
                if not self._validate_domain_dns(domain_name):
                    return False, "Domain DNS validation failed"
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Prepare relay configuration
            relay_host = ""
            relay_port = 587
            relay_username = ""
            relay_password = ""
            use_tls = False
            use_ssl = False
            
            if relay_config and not is_local:
                relay_host = relay_config.get('host', '')
                relay_port = relay_config.get('port', 587)
                relay_username = relay_config.get('username', '')
                relay_password = relay_config.get('password', '')
                use_tls = relay_config.get('use_tls', False)
                use_ssl = relay_config.get('use_ssl', False)
            
            # Insert domain
            cursor.execute('''
                INSERT INTO domains (
                    domain_name, description, is_active, is_local,
                    relay_host, relay_port, relay_username, relay_password,
                    use_tls, use_ssl
                ) VALUES (?, ?, 1, ?, ?, ?, ?, ?, ?, ?)
            ''', (domain_name, description, is_local, relay_host, relay_port,
                  relay_username, relay_password, use_tls, use_ssl))
            
            domain_id = cursor.lastrowid
            
            # Add stats entry
            cursor.execute('''
                INSERT INTO domain_stats (domain_id, emails_received, emails_sent, last_activity)
                VALUES (?, 0, 0, CURRENT_TIMESTAMP)
            ''', (domain_id,))
            
            conn.commit()
            conn.close()
            
            logger.info(f"Domain '{domain_name}' added successfully")
            return True, "Domain added successfully"
            
        except Exception as e:
            logger.error(f"Error adding domain: {e}")
            return False, f"Error adding domain: {str(e)}"
    
    def update_domain(self, domain_id: int, domain_name: str, description: str = "",
                     is_active: bool = True, is_local: bool = True,
                     relay_config: Optional[Dict[str, Any]] = None) -> Tuple[bool, str]:
        """Update an existing domain"""
        try:
            # Validate domain name
            if not self._validate_domain_name(domain_name):
                return False, "Invalid domain name format"
            
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Check if domain exists
            cursor.execute('SELECT domain_name FROM domains WHERE id = ?', (domain_id,))
            result = cursor.fetchone()
            if not result:
                conn.close()
                return False, "Domain not found"
            
            # Check if new domain name conflicts with existing domains
            cursor.execute('SELECT id FROM domains WHERE domain_name = ? AND id != ?', 
                          (domain_name, domain_id))
            if cursor.fetchone():
                conn.close()
                return False, "Domain name already exists"
            
            # Prepare relay configuration
            relay_host = ""
            relay_port = 587
            relay_username = ""
            relay_password = ""
            use_tls = False
            use_ssl = False
            
            if relay_config and not is_local:
                relay_host = relay_config.get('host', '')
                relay_port = relay_config.get('port', 587)
                relay_username = relay_config.get('username', '')
                relay_password = relay_config.get('password', '')
                use_tls = relay_config.get('use_tls', False)
                use_ssl = relay_config.get('use_ssl', False)
            
            # Update domain
            cursor.execute('''
                UPDATE domains SET
                    domain_name = ?, description = ?, is_active = ?, is_local = ?,
                    relay_host = ?, relay_port = ?, relay_username = ?, relay_password = ?,
                    use_tls = ?, use_ssl = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            ''', (domain_name, description, is_active, is_local, relay_host, relay_port,
                  relay_username, relay_password, use_tls, use_ssl, domain_id))
            
            conn.commit()
            conn.close()
            
            logger.info(f"Domain '{domain_name}' updated successfully")
            return True, "Domain updated successfully"
            
        except Exception as e:
            logger.error(f"Error updating domain: {e}")
            return False, f"Error updating domain: {str(e)}"
    
    def delete_domain(self, domain_id: int) -> Tuple[bool, str]:
        """Delete a domain"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get domain name for logging
            cursor.execute('SELECT domain_name FROM domains WHERE id = ?', (domain_id,))
            result = cursor.fetchone()
            if not result:
                conn.close()
                return False, "Domain not found"
            
            domain_name = result[0]
            
            # Delete domain (cascades to aliases and stats)
            cursor.execute('DELETE FROM domains WHERE id = ?', (domain_id,))
            
            conn.commit()
            conn.close()
            
            logger.info(f"Domain '{domain_name}' deleted successfully")
            return True, "Domain deleted successfully"
            
        except Exception as e:
            logger.error(f"Error deleting domain: {e}")
            return False, f"Error deleting domain: {str(e)}"
    
    def get_domains(self) -> List[Dict[str, Any]]:
        """Get all domains"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT d.*, ds.emails_received, ds.emails_sent, ds.last_activity, ds.total_size_bytes
                FROM domains d
                LEFT JOIN domain_stats ds ON d.id = ds.domain_id
                ORDER BY d.domain_name
            ''')
            
            domains = []
            for row in cursor.fetchall():
                # Convert timestamp strings to datetime objects
                created_at = None
                updated_at = None
                last_activity = None
                
                if row[12]:  # created_at
                    try:
                        created_at = datetime.fromisoformat(row[12].replace('Z', '+00:00'))
                    except (ValueError, AttributeError):
                        try:
                            created_at = datetime.strptime(row[12], '%Y-%m-%d %H:%M:%S')
                        except (ValueError, TypeError):
                            created_at = None
                
                if row[13]:  # updated_at
                    try:
                        updated_at = datetime.fromisoformat(row[13].replace('Z', '+00:00'))
                    except (ValueError, AttributeError):
                        try:
                            updated_at = datetime.strptime(row[13], '%Y-%m-%d %H:%M:%S')
                        except (ValueError, TypeError):
                            updated_at = None
                
                if row[16]:  # last_activity
                    try:
                        last_activity = datetime.fromisoformat(row[16].replace('Z', '+00:00'))
                    except (ValueError, AttributeError):
                        try:
                            last_activity = datetime.strptime(row[16], '%Y-%m-%d %H:%M:%S')
                        except (ValueError, TypeError):
                            last_activity = None
                
                domains.append({
                    'id': row[0],
                    'domain_name': row[1],
                    'description': row[2],
                    'is_active': bool(row[3]),
                    'is_local': bool(row[4]),
                    'relay_host': row[5],
                    'relay_port': row[6],
                    'relay_username': row[7],
                    'relay_password': row[8],
                    'use_tls': bool(row[9]),
                    'use_ssl': bool(row[10]),
                    'max_message_size': row[11],
                    'created_at': created_at,
                    'updated_at': updated_at,
                    'emails_received': row[14] or 0,
                    'emails_sent': row[15] or 0,
                    'last_activity': last_activity,
                    'total_size_bytes': row[17] or 0
                })
            
            conn.close()
            return domains
            
        except Exception as e:
            logger.error(f"Error getting domains: {e}")
            return []
    
    def get_domain(self, domain_id: int) -> Optional[Dict[str, Any]]:
        """Get a specific domain by ID"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT d.*, ds.emails_received, ds.emails_sent, ds.last_activity, ds.total_size_bytes
                FROM domains d
                LEFT JOIN domain_stats ds ON d.id = ds.domain_id
                WHERE d.id = ?
            ''', (domain_id,))
            
            row = cursor.fetchone()
            if not row:
                conn.close()
                return None
            
            domain = {
                'id': row[0],
                'domain_name': row[1],
                'description': row[2],
                'is_active': bool(row[3]),
                'is_local': bool(row[4]),
                'relay_host': row[5],
                'relay_port': row[6],
                'relay_username': row[7],
                'relay_password': row[8],
                'use_tls': bool(row[9]),
                'use_ssl': bool(row[10]),
                'max_message_size': row[11],
                'created_at': row[12],
                'updated_at': row[13],
                'emails_received': row[14] or 0,
                'emails_sent': row[15] or 0,
                'last_activity': row[16],
                'total_size_bytes': row[17] or 0
            }
            
            conn.close()
            return domain
            
        except Exception as e:
            logger.error(f"Error getting domain: {e}")
            return None
    
    def domain_exists(self, domain_name: str) -> bool:
        """Check if a domain exists"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('SELECT id FROM domains WHERE domain_name = ?', (domain_name,))
            result = cursor.fetchone()
            
            conn.close()
            return result is not None
            
        except Exception as e:
            logger.error(f"Error checking domain existence: {e}")
            return False
    
    def is_domain_allowed(self, domain_name: str) -> bool:
        """Check if a domain is allowed to receive emails"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('SELECT is_active FROM domains WHERE domain_name = ?', (domain_name,))
            result = cursor.fetchone()
            
            conn.close()
            return result is not None and bool(result[0])
            
        except Exception as e:
            logger.error(f"Error checking domain allowance: {e}")
            return False
    
    def update_domain_stats(self, domain_name: str, emails_received: int = 0, 
                           emails_sent: int = 0, size_bytes: int = 0):
        """Update domain statistics"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get domain ID
            cursor.execute('SELECT id FROM domains WHERE domain_name = ?', (domain_name,))
            result = cursor.fetchone()
            if not result:
                conn.close()
                return
            
            domain_id = result[0]
            
            # Update stats
            cursor.execute('''
                UPDATE domain_stats SET
                    emails_received = emails_received + ?,
                    emails_sent = emails_sent + ?,
                    total_size_bytes = total_size_bytes + ?,
                    last_activity = CURRENT_TIMESTAMP
                WHERE domain_id = ?
            ''', (emails_received, emails_sent, size_bytes, domain_id))
            
            conn.commit()
            conn.close()
            
        except Exception as e:
            logger.error(f"Error updating domain stats: {e}")
    
    def _validate_domain_name(self, domain_name: str) -> bool:
        """Validate domain name format"""
        if not domain_name or len(domain_name) > 255:
            return False
        
        # Basic domain name regex
        domain_pattern = re.compile(
            r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$'
        )
        
        return bool(domain_pattern.match(domain_name))
    
    def _validate_domain_dns(self, domain_name: str) -> bool:
        """Validate domain DNS records"""
        try:
            # Check if domain has MX records
            if self.config.get('domain_validation', {}).get('check_mx_records', False):
                try:
                    # Use nslookup command for MX record checking on Windows
                    result = subprocess.run(['nslookup', '-type=MX', domain_name], 
                                          capture_output=True, text=True, timeout=10)
                    if result.returncode != 0 or 'mail exchanger' not in result.stdout.lower():
                        return False
                except (subprocess.TimeoutExpired, subprocess.SubprocessError):
                    return False
            
            # Check if domain resolves
            try:
                socket.gethostbyname(domain_name)
                return True
            except socket.gaierror:
                return False
                
        except Exception as e:
            logger.error(f"Error validating domain DNS: {e}")
            return False
    
    def check_domain_dns_status(self, domain_name: str) -> Dict[str, Any]:
        """Check comprehensive DNS status for a domain"""
        status = {
            'domain': domain_name,
            'timestamp': datetime.now().isoformat(),
            'overall_status': 'unknown',
            'checks': {
                'a_record': {'status': 'unknown', 'value': None, 'error': None},
                'mx_record': {'status': 'unknown', 'value': [], 'error': None},
                'txt_record': {'status': 'unknown', 'value': [], 'error': None},
                'ns_record': {'status': 'unknown', 'value': [], 'error': None}
            }
        }
        
        try:
            # Check A record (domain resolution)
            try:
                ip_address = socket.gethostbyname(domain_name)
                status['checks']['a_record'] = {
                    'status': 'success',
                    'value': ip_address,
                    'error': None
                }
            except socket.gaierror as e:
                status['checks']['a_record'] = {
                    'status': 'failed',
                    'value': None,
                    'error': str(e)
                }
            
            # Check MX records
            try:
                result = subprocess.run(['nslookup', '-type=MX', domain_name], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0 and 'mail exchanger' in result.stdout.lower():
                    mx_records = []
                    for line in result.stdout.split('\n'):
                        if 'mail exchanger' in line.lower():
                            mx_records.append(line.strip())
                    status['checks']['mx_record'] = {
                        'status': 'success',
                        'value': mx_records,
                        'error': None
                    }
                else:
                    status['checks']['mx_record'] = {
                        'status': 'failed',
                        'value': [],
                        'error': 'No MX records found'
                    }
            except (subprocess.TimeoutExpired, subprocess.SubprocessError) as e:
                status['checks']['mx_record'] = {
                    'status': 'failed',
                    'value': [],
                    'error': str(e)
                }
            
            # Check TXT records
            try:
                result = subprocess.run(['nslookup', '-type=TXT', domain_name], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    txt_records = []
                    for line in result.stdout.split('\n'):
                        if 'text =' in line.lower():
                            txt_records.append(line.strip())
                    status['checks']['txt_record'] = {
                        'status': 'success',
                        'value': txt_records,
                        'error': None
                    }
                else:
                    status['checks']['txt_record'] = {
                        'status': 'failed',
                        'value': [],
                        'error': 'No TXT records found'
                    }
            except (subprocess.TimeoutExpired, subprocess.SubprocessError) as e:
                status['checks']['txt_record'] = {
                    'status': 'failed',
                    'value': [],
                    'error': str(e)
                }
            
            # Check NS records
            try:
                result = subprocess.run(['nslookup', '-type=NS', domain_name], 
                                      capture_output=True, text=True, timeout=10)
                if result.returncode == 0:
                    ns_records = []
                    for line in result.stdout.split('\n'):
                        if 'nameserver' in line.lower():
                            ns_records.append(line.strip())
                    status['checks']['ns_record'] = {
                        'status': 'success',
                        'value': ns_records,
                        'error': None
                    }
                else:
                    status['checks']['ns_record'] = {
                        'status': 'failed',
                        'value': [],
                        'error': 'No NS records found'
                    }
            except (subprocess.TimeoutExpired, subprocess.SubprocessError) as e:
                status['checks']['ns_record'] = {
                    'status': 'failed',
                    'value': [],
                    'error': str(e)
                }
            
            # Determine overall status
            success_count = sum(1 for check in status['checks'].values() if check['status'] == 'success')
            total_checks = len(status['checks'])
            
            if success_count == total_checks:
                status['overall_status'] = 'healthy'
            elif success_count >= total_checks // 2:
                status['overall_status'] = 'warning'
            else:
                status['overall_status'] = 'error'
                
        except Exception as e:
            logger.error(f"Error checking DNS status for {domain_name}: {e}")
            status['overall_status'] = 'error'
            status['error'] = str(e)
        
        return status

if __name__ == '__main__':
    # Test the domain manager
    dm = DomainManager()
    print("Domain Manager initialized successfully")
    
    # List current domains
    domains = dm.get_domains()
    print(f"Current domains: {len(domains)}")
    for domain in domains:
        print(f"  - {domain['domain_name']} ({'active' if domain['is_active'] else 'inactive'})")
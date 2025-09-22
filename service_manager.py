#!/usr/bin/env python3
"""
Service Management System
Handles starting, stopping, and monitoring of SMTP server and web interface services.
"""

import os
import sys
import time
import signal
import psutil
import subprocess
import threading
import json
import logging
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime
import platform

@dataclass
class ServiceInfo:
    """Service information structure"""
    name: str
    pid: Optional[int] = None
    status: str = 'stopped'  # stopped, starting, running, stopping, error
    port: Optional[int] = None
    start_time: Optional[datetime] = None
    cpu_percent: float = 0.0
    memory_mb: float = 0.0
    command: str = ''
    log_file: str = ''
    
class ServiceManager:
    """Service management system for SMTP Web Application"""
    
    def __init__(self, base_dir: Optional[Path] = None):
        self.base_dir = Path(base_dir) if base_dir else Path.cwd()
        self.logs_dir = self.base_dir / 'logs'
        self.pids_dir = self.logs_dir / 'pids'
        self.system = platform.system().lower()
        
        # Ensure directories exist
        self.logs_dir.mkdir(exist_ok=True)
        self.pids_dir.mkdir(exist_ok=True)
        
        # Service definitions
        self.services = {
            'smtp_server': ServiceInfo(
                name='smtp_server',
                port=1025,
                command=f'{sys.executable} smtp_server.py',
                log_file=str(self.logs_dir / 'smtp_server.log')
            ),
            'web_interface': ServiceInfo(
                name='web_interface',
                port=5000,
                command=f'{sys.executable} web_interface.py',
                log_file=str(self.logs_dir / 'web_interface.log')
            )
        }
        
        # Setup logging
        self.logger = self._setup_logging()
        
        # Load existing PIDs
        self._load_pids()
        
    def _setup_logging(self) -> logging.Logger:
        """Setup service manager logging"""
        logger = logging.getLogger('service_manager')
        logger.setLevel(logging.INFO)
        
        # File handler
        log_file = self.logs_dir / 'service_manager.log'
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(logging.INFO)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # Formatter
        formatter = logging.Formatter('%(asctime)s [%(levelname)s] %(name)s: %(message)s')
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
        
    def _load_pids(self):
        """Load existing PIDs from files"""
        for service_name in self.services:
            pid_file = self.pids_dir / f'{service_name}.pid'
            if pid_file.exists():
                try:
                    with open(pid_file, 'r') as f:
                        pid = int(f.read().strip())
                    
                    # Check if process is still running
                    if psutil.pid_exists(pid):
                        process = psutil.Process(pid)
                        if self._is_our_process(process, service_name):
                            self.services[service_name].pid = pid
                            self.services[service_name].status = 'running'
                            self.services[service_name].start_time = datetime.fromtimestamp(process.create_time())
                        else:
                            # PID exists but not our process
                            pid_file.unlink()
                    else:
                        # PID doesn't exist
                        pid_file.unlink()
                        
                except (ValueError, psutil.NoSuchProcess, psutil.AccessDenied):
                    # Invalid PID file or process access denied
                    if pid_file.exists():
                        pid_file.unlink()
                        
    def _is_our_process(self, process: psutil.Process, service_name: str) -> bool:
        """Check if process belongs to our service"""
        try:
            cmdline = ' '.join(process.cmdline())
            return service_name.replace('_', '') in cmdline.lower()
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            return False
            
    def _save_pid(self, service_name: str, pid: int):
        """Save PID to file"""
        pid_file = self.pids_dir / f'{service_name}.pid'
        with open(pid_file, 'w') as f:
            f.write(str(pid))
            
    def _remove_pid(self, service_name: str):
        """Remove PID file"""
        pid_file = self.pids_dir / f'{service_name}.pid'
        if pid_file.exists():
            pid_file.unlink()
            
    def _update_service_stats(self, service_name: str):
        """Update service statistics"""
        service = self.services[service_name]
        if service.pid and psutil.pid_exists(service.pid):
            try:
                process = psutil.Process(service.pid)
                service.cpu_percent = process.cpu_percent()
                service.memory_mb = process.memory_info().rss / 1024 / 1024
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                service.cpu_percent = 0.0
                service.memory_mb = 0.0
                
    def start_service(self, service_name: str, background: bool = True) -> bool:
        """Start a service"""
        if service_name not in self.services:
            self.logger.error(f"Unknown service: {service_name}")
            return False
            
        service = self.services[service_name]
        
        # Check if already running
        if service.status == 'running' and service.pid and psutil.pid_exists(service.pid):
            self.logger.info(f"Service {service_name} is already running (PID: {service.pid})")
            return True
            
        self.logger.info(f"Starting service: {service_name}")
        service.status = 'starting'
        
        try:
            # Prepare environment
            env = os.environ.copy()
            env['PYTHONPATH'] = str(self.base_dir)
            
            # Start process
            if background:
                # Start in background
                with open(service.log_file, 'a') as log_file:
                    process = subprocess.Popen(
                        service.command.split(),
                        cwd=self.base_dir,
                        env=env,
                        stdout=log_file,
                        stderr=subprocess.STDOUT,
                        start_new_session=True
                    )
            else:
                # Start in foreground
                process = subprocess.Popen(
                    service.command.split(),
                    cwd=self.base_dir,
                    env=env
                )
                
            service.pid = process.pid
            service.start_time = datetime.now()
            service.status = 'running'
            
            # Save PID
            self._save_pid(service_name, service.pid)
            
            # Wait a moment to ensure it started properly
            time.sleep(2)
            
            if not psutil.pid_exists(service.pid):
                service.status = 'error'
                self.logger.error(f"Service {service_name} failed to start")
                return False
                
            self.logger.info(f"Service {service_name} started successfully (PID: {service.pid})")
            return True
            
        except Exception as e:
            service.status = 'error'
            self.logger.error(f"Failed to start service {service_name}: {e}")
            return False
            
    def stop_service(self, service_name: str, force: bool = False) -> bool:
        """Stop a service"""
        if service_name not in self.services:
            self.logger.error(f"Unknown service: {service_name}")
            return False
            
        service = self.services[service_name]
        
        if service.status == 'stopped' or not service.pid:
            self.logger.info(f"Service {service_name} is already stopped")
            return True
            
        self.logger.info(f"Stopping service: {service_name}")
        service.status = 'stopping'
        
        try:
            if not psutil.pid_exists(service.pid):
                service.status = 'stopped'
                service.pid = None
                self._remove_pid(service_name)
                return True
                
            process = psutil.Process(service.pid)
            
            if force:
                # Force kill
                process.kill()
                self.logger.info(f"Force killed service {service_name}")
            else:
                # Graceful shutdown
                if self.system == 'windows':
                    process.terminate()
                else:
                    process.send_signal(signal.SIGTERM)
                    
                # Wait for graceful shutdown
                try:
                    process.wait(timeout=10)
                except psutil.TimeoutExpired:
                    self.logger.warning(f"Service {service_name} didn't stop gracefully, force killing")
                    process.kill()
                    
            service.status = 'stopped'
            service.pid = None
            service.start_time = None
            service.cpu_percent = 0.0
            service.memory_mb = 0.0
            
            self._remove_pid(service_name)
            self.logger.info(f"Service {service_name} stopped successfully")
            return True
            
        except (psutil.NoSuchProcess, psutil.AccessDenied) as e:
            service.status = 'stopped'
            service.pid = None
            self._remove_pid(service_name)
            self.logger.warning(f"Service {service_name} was already stopped or access denied: {e}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to stop service {service_name}: {e}")
            return False
            
    def restart_service(self, service_name: str) -> bool:
        """Restart a service"""
        self.logger.info(f"Restarting service: {service_name}")
        
        # Stop first
        if not self.stop_service(service_name):
            return False
            
        # Wait a moment
        time.sleep(2)
        
        # Start again
        return self.start_service(service_name)
        
    def get_service_status(self, service_name: str) -> Optional[ServiceInfo]:
        """Get service status"""
        if service_name not in self.services:
            return None
            
        service = self.services[service_name]
        
        # Update status if we think it's running
        if service.status == 'running' and service.pid:
            if not psutil.pid_exists(service.pid):
                service.status = 'stopped'
                service.pid = None
                service.start_time = None
                self._remove_pid(service_name)
            else:
                self._update_service_stats(service_name)
                
        return service
        
    def get_all_status(self) -> Dict[str, ServiceInfo]:
        """Get status of all services"""
        status = {}
        for service_name in self.services:
            status[service_name] = self.get_service_status(service_name)
        return status
        
    def start_all(self) -> bool:
        """Start all services"""
        self.logger.info("Starting all services")
        success = True
        
        # Start SMTP server first
        if not self.start_service('smtp_server'):
            success = False
            
        # Wait a moment for SMTP server to initialize
        time.sleep(3)
        
        # Start web interface
        if not self.start_service('web_interface'):
            success = False
            
        return success
        
    def stop_all(self, force: bool = False) -> bool:
        """Stop all services"""
        self.logger.info("Stopping all services")
        success = True
        
        # Stop web interface first
        if not self.stop_service('web_interface', force):
            success = False
            
        # Stop SMTP server
        if not self.stop_service('smtp_server', force):
            success = False
            
        return success
        
    def restart_all(self) -> bool:
        """Restart all services"""
        self.logger.info("Restarting all services")
        
        if not self.stop_all():
            return False
            
        time.sleep(3)
        
        return self.start_all()
        
    def is_port_in_use(self, port: int) -> bool:
        """Check if port is in use"""
        for conn in psutil.net_connections():
            if conn.laddr.port == port and conn.status == psutil.CONN_LISTEN:
                return True
        return False
        
    def get_port_conflicts(self) -> List[Tuple[str, int]]:
        """Get list of services with port conflicts"""
        conflicts = []
        for service_name, service in self.services.items():
            if service.port and self.is_port_in_use(service.port):
                # Check if it's our own service
                if service.status != 'running':
                    conflicts.append((service_name, service.port))
        return conflicts
        
    def monitor_services(self, interval: int = 30) -> None:
        """Monitor services and restart if they crash"""
        self.logger.info(f"Starting service monitor (interval: {interval}s)")
        
        while True:
            try:
                for service_name in self.services:
                    service = self.get_service_status(service_name)
                    
                    # If service should be running but isn't, restart it
                    if service and service.status == 'stopped' and hasattr(service, 'auto_restart'):
                        if getattr(service, 'auto_restart', False):
                            self.logger.warning(f"Service {service_name} crashed, restarting...")
                            self.start_service(service_name)
                            
                time.sleep(interval)
                
            except KeyboardInterrupt:
                self.logger.info("Service monitor stopped by user")
                break
            except Exception as e:
                self.logger.error(f"Service monitor error: {e}")
                time.sleep(interval)
                
    def export_status(self, file_path: Path) -> None:
        """Export service status to JSON file"""
        status = {}
        for service_name, service in self.get_all_status().items():
            status[service_name] = {
                'name': service.name,
                'pid': service.pid,
                'status': service.status,
                'port': service.port,
                'start_time': service.start_time.isoformat() if service.start_time else None,
                'cpu_percent': service.cpu_percent,
                'memory_mb': service.memory_mb,
                'command': service.command,
                'log_file': service.log_file
            }
            
        status['timestamp'] = datetime.now().isoformat()
        
        with open(file_path, 'w') as f:
            json.dump(status, f, indent=2)
            
    def cleanup_old_logs(self, days: int = 7) -> None:
        """Clean up old log files"""
        cutoff_time = time.time() - (days * 24 * 60 * 60)
        
        for log_file in self.logs_dir.glob('*.log*'):
            if log_file.stat().st_mtime < cutoff_time:
                try:
                    log_file.unlink()
                    self.logger.info(f"Cleaned up old log file: {log_file}")
                except Exception as e:
                    self.logger.warning(f"Failed to clean up log file {log_file}: {e}")

def main():
    """CLI interface for service management"""
    import argparse
    
    parser = argparse.ArgumentParser(description='SMTP Web App Service Manager')
    parser.add_argument('action', choices=['start', 'stop', 'restart', 'status', 'monitor', 'cleanup'],
                       help='Action to perform')
    parser.add_argument('--service', choices=['smtp_server', 'web_interface', 'all'],
                       default='all', help='Service to manage')
    parser.add_argument('--force', action='store_true', help='Force stop services')
    parser.add_argument('--background', action='store_true', default=True,
                       help='Run services in background')
    parser.add_argument('--monitor-interval', type=int, default=30,
                       help='Monitor interval in seconds')
    parser.add_argument('--cleanup-days', type=int, default=7,
                       help='Days to keep log files')
    
    args = parser.parse_args()
    
    manager = ServiceManager()
    
    if args.action == 'start':
        if args.service == 'all':
            success = manager.start_all()
        else:
            success = manager.start_service(args.service, args.background)
        sys.exit(0 if success else 1)
        
    elif args.action == 'stop':
        if args.service == 'all':
            success = manager.stop_all(args.force)
        else:
            success = manager.stop_service(args.service, args.force)
        sys.exit(0 if success else 1)
        
    elif args.action == 'restart':
        if args.service == 'all':
            success = manager.restart_all()
        else:
            success = manager.restart_service(args.service)
        sys.exit(0 if success else 1)
        
    elif args.action == 'status':
        if args.service == 'all':
            status = manager.get_all_status()
            for service_name, service in status.items():
                print(f"\n{service_name.upper()}:")
                print(f"  Status: {service.status}")
                print(f"  PID: {service.pid or 'N/A'}")
                print(f"  Port: {service.port or 'N/A'}")
                print(f"  CPU: {service.cpu_percent:.1f}%")
                print(f"  Memory: {service.memory_mb:.1f} MB")
                if service.start_time:
                    print(f"  Started: {service.start_time}")
        else:
            service = manager.get_service_status(args.service)
            if service:
                print(f"Service: {service.name}")
                print(f"Status: {service.status}")
                print(f"PID: {service.pid or 'N/A'}")
                print(f"Port: {service.port or 'N/A'}")
                print(f"CPU: {service.cpu_percent:.1f}%")
                print(f"Memory: {service.memory_mb:.1f} MB")
                if service.start_time:
                    print(f"Started: {service.start_time}")
                    
    elif args.action == 'monitor':
        try:
            manager.monitor_services(args.monitor_interval)
        except KeyboardInterrupt:
            print("\nMonitoring stopped")
            
    elif args.action == 'cleanup':
        manager.cleanup_old_logs(args.cleanup_days)
        print(f"Cleaned up log files older than {args.cleanup_days} days")

if __name__ == "__main__":
    main()
#!/bin/bash

# SLX - SetupX Linux eXecutor
# Quick command executor and system management tool

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

highlight() {
    echo -e "${PURPLE}[SLX]${NC} $1"
}

# System information
show_system_info() {
    highlight "System Information"
    echo "Hostname: $(hostname)"
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
    echo ""
}

# Quick system status
show_status() {
    highlight "System Status"
    
    # Check services
    echo "Services Status:"
    systemctl is-active --quiet ssh && echo "  SSH: Running" || echo "  SSH: Not running"
    systemctl is-active --quiet docker && echo "  Docker: Running" || echo "  Docker: Not running"
    systemctl is-active --quiet nginx && echo "  Nginx: Running" || echo "  Nginx: Not running"
    systemctl is-active --quiet apache2 && echo "  Apache: Running" || echo "  Apache: Not running"
    echo ""
    
    # Check ports
    echo "Open Ports:"
    ss -tuln | grep LISTEN | head -10
    echo ""
    
    # Check processes
    echo "Top Processes:"
    ps aux --sort=-%cpu | head -6
    echo ""
}

# Quick updates
quick_update() {
    highlight "Quick System Update"
    log "Updating package lists..."
    sudo apt update
    log "Upgrading packages..."
    sudo apt upgrade -y
    log "Cleaning up..."
    sudo apt autoremove -y
    sudo apt autoclean
    success "System updated successfully"
}

# Docker management
docker_status() {
    highlight "Docker Status"
    if command -v docker &> /dev/null; then
        echo "Docker Version: $(docker --version)"
        echo "Docker Compose Version: $(docker-compose --version 2>/dev/null || echo 'Not installed')"
        echo ""
        echo "Running Containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo "Docker Images:"
        docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
    else
        warning "Docker is not installed"
    fi
}

# Network tools
network_info() {
    highlight "Network Information"
    echo "Public IP: $(curl -s https://ipinfo.io/ip)"
    echo "Local IP: $(hostname -I | awk '{print $1}')"
    echo "Gateway: $(ip route | grep default | awk '{print $3}')"
    echo "DNS: $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | head -1)"
    echo ""
    echo "Network Interfaces:"
    ip addr show | grep -E "inet |UP" | grep -v "127.0.0.1"
    echo ""
}

# Security check
security_check() {
    highlight "Security Check"
    
    # Check firewall
    if command -v ufw &> /dev/null; then
        echo "UFW Status: $(sudo ufw status | head -1)"
    fi
    
    # Check fail2ban
    if command -v fail2ban-client &> /dev/null; then
        echo "Fail2ban Status: $(sudo fail2ban-client status | head -1)"
    fi
    
    # Check for root login
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
        warning "Root login is enabled in SSH"
    else
        info "Root login is disabled in SSH"
    fi
    
    # Check for password authentication
    if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config 2>/dev/null; then
        warning "Password authentication is enabled in SSH"
    else
        info "Password authentication is disabled in SSH"
    fi
    echo ""
}

# Disk usage analysis
disk_analysis() {
    highlight "Disk Usage Analysis"
    echo "Disk Usage by Directory:"
    du -h --max-depth=1 / 2>/dev/null | sort -hr | head -10
    echo ""
    echo "Largest Files:"
    find / -type f -size +100M 2>/dev/null | head -10
    echo ""
}

# Process management
process_management() {
    highlight "Process Management"
    echo "Memory Usage:"
    ps aux --sort=-%mem | head -10
    echo ""
    echo "CPU Usage:"
    ps aux --sort=-%cpu | head -10
    echo ""
}

# Log analysis
log_analysis() {
    highlight "Recent System Logs"
    echo "Recent Auth Logs:"
    sudo tail -10 /var/log/auth.log 2>/dev/null || echo "No auth logs found"
    echo ""
    echo "Recent Syslog:"
    sudo tail -10 /var/log/syslog 2>/dev/null || echo "No syslog found"
    echo ""
}

# Backup utilities
backup_system() {
    highlight "System Backup"
    local backup_dir="/tmp/slx_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    log "Creating system backup in $backup_dir"
    
    # Backup important configs
    sudo cp -r /etc/ssh "$backup_dir/" 2>/dev/null || true
    sudo cp /etc/hosts "$backup_dir/" 2>/dev/null || true
    sudo cp /etc/crontab "$backup_dir/" 2>/dev/null || true
    
    # Backup user data
    cp -r ~/.ssh "$backup_dir/" 2>/dev/null || true
    cp ~/.bashrc "$backup_dir/" 2>/dev/null || true
    cp ~/.profile "$backup_dir/" 2>/dev/null || true
    
    # Create archive
    tar -czf "${backup_dir}.tar.gz" -C /tmp "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    success "Backup created: ${backup_dir}.tar.gz"
}

# Show help
show_help() {
    echo "SLX - SetupX Linux eXecutor"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  info        Show system information"
    echo "  status      Show system status"
    echo "  update      Quick system update"
    echo "  docker      Show Docker status"
    echo "  network     Show network information"
    echo "  security    Run security check"
    echo "  disk        Analyze disk usage"
    echo "  processes   Show process information"
    echo "  logs        Show recent logs"
    echo "  backup      Create system backup"
    echo "  all         Run all checks"
    echo "  help        Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 info"
    echo "  $0 status"
    echo "  $0 all"
}

# Main execution
main() {
    case "${1:-help}" in
        info)
            show_system_info
            ;;
        status)
            show_status
            ;;
        update)
            quick_update
            ;;
        docker)
            docker_status
            ;;
        network)
            network_info
            ;;
        security)
            security_check
            ;;
        disk)
            disk_analysis
            ;;
        processes)
            process_management
            ;;
        logs)
            log_analysis
            ;;
        backup)
            backup_system
            ;;
        all)
            show_system_info
            show_status
            docker_status
            network_info
            security_check
            disk_analysis
            process_management
            log_analysis
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
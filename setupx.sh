#!/bin/bash

# SetupX - Linux Server Setup Script
# This script sets up a Linux server with common tools and configurations

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        warning "This script is running as root. This is not recommended for security reasons."
        read -p "Do you want to continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
}

# Install essential packages
install_essentials() {
    log "Installing essential packages..."
    sudo apt install -y \
        curl \
        wget \
        git \
        vim \
        nano \
        htop \
        tree \
        unzip \
        zip \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
}

# Install Docker
install_docker() {
    log "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        log "Docker installed successfully"
    else
        info "Docker is already installed"
    fi
}

# Install Docker Compose
install_docker_compose() {
    log "Installing Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        log "Docker Compose installed successfully"
    else
        info "Docker Compose is already installed"
    fi
}

# Install Node.js
install_nodejs() {
    log "Installing Node.js..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        log "Node.js installed successfully"
    else
        info "Node.js is already installed"
    fi
}

# Install Python and pip
install_python() {
    log "Installing Python and pip..."
    sudo apt install -y python3 python3-pip python3-venv
    log "Python installed successfully"
}

# Configure firewall
configure_firewall() {
    log "Configuring UFW firewall..."
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 80
    sudo ufw allow 443
    log "Firewall configured successfully"
}

# Create useful aliases
create_aliases() {
    log "Creating useful aliases..."
    cat >> ~/.bashrc << 'EOF'

# SetupX aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias h='history'
alias j='jobs -l'
alias which='type -a'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowtime=now
alias nowdate='date +"%d-%m-%Y"'
alias ports='netstat -tulanp'
alias myip='curl -s https://ipinfo.io/ip'
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3'
EOF
    log "Aliases added to ~/.bashrc"
}

# Main execution
main() {
    log "Starting SetupX Linux Server Setup..."
    
    check_root
    update_system
    install_essentials
    install_docker
    install_docker_compose
    install_nodejs
    install_python
    configure_firewall
    create_aliases
    
    log "SetupX setup completed successfully!"
    log "Please log out and log back in to apply Docker group changes"
    log "Run 'source ~/.bashrc' to apply aliases"
}

# Run main function
main "$@"
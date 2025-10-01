#!/bin/bash

# Instal - Package Installation Script
# This script provides a convenient way to install various packages and tools

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# Check if package is installed
is_installed() {
    command -v "$1" &> /dev/null
}

# Install development tools
install_dev_tools() {
    log "Installing development tools..."
    sudo apt update
    sudo apt install -y \
        build-essential \
        cmake \
        make \
        gcc \
        g++ \
        gdb \
        valgrind \
        cppcheck \
        clang \
        clang-format \
        clang-tidy
    success "Development tools installed"
}

# Install web development tools
install_web_tools() {
    log "Installing web development tools..."
    
    # Install Node.js LTS
    if ! is_installed node; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
        success "Node.js installed"
    else
        info "Node.js already installed"
    fi
    
    # Install npm packages globally
    if is_installed npm; then
        log "Installing global npm packages..."
        sudo npm install -g \
            yarn \
            pnpm \
            typescript \
            ts-node \
            nodemon \
            pm2 \
            eslint \
            prettier \
            @vue/cli \
            @angular/cli \
            create-react-app
        success "Global npm packages installed"
    fi
}

# Install Python tools
install_python_tools() {
    log "Installing Python development tools..."
    sudo apt install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-setuptools \
        python3-wheel
    
    # Install pip packages
    if is_installed pip3; then
        log "Installing Python packages..."
        pip3 install --user \
            pipenv \
            virtualenv \
            black \
            flake8 \
            pylint \
            pytest \
            jupyter \
            numpy \
            pandas \
            requests \
            flask \
            django
        success "Python tools installed"
    fi
}

# Install database tools
install_database_tools() {
    log "Installing database tools..."
    sudo apt install -y \
        mysql-client \
        postgresql-client \
        redis-tools \
        sqlite3
    
    # Install MongoDB tools
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
    sudo apt update
    sudo apt install -y mongodb-mongosh
    success "Database tools installed"
}

# Install container tools
install_container_tools() {
    log "Installing container tools..."
    
    # Install Docker
    if ! is_installed docker; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        success "Docker installed"
    else
        info "Docker already installed"
    fi
    
    # Install Docker Compose
    if ! is_installed docker-compose; then
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        success "Docker Compose installed"
    else
        info "Docker Compose already installed"
    fi
    
    # Install Kubernetes tools
    if ! is_installed kubectl; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
        success "kubectl installed"
    else
        info "kubectl already installed"
    fi
}

# Install cloud tools
install_cloud_tools() {
    log "Installing cloud tools..."
    
    # Install AWS CLI
    if ! is_installed aws; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
        success "AWS CLI installed"
    else
        info "AWS CLI already installed"
    fi
    
    # Install Azure CLI
    if ! is_installed az; then
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        success "Azure CLI installed"
    else
        info "Azure CLI already installed"
    fi
    
    # Install Google Cloud SDK
    if ! is_installed gcloud; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        sudo apt update
        sudo apt install -y google-cloud-cli
        success "Google Cloud SDK installed"
    else
        info "Google Cloud SDK already installed"
    fi
}

# Install monitoring tools
install_monitoring_tools() {
    log "Installing monitoring tools..."
    sudo apt install -y \
        htop \
        iotop \
        nethogs \
        iftop \
        nload \
        ncdu \
        tree \
        jq \
        curl \
        wget \
        git \
        vim \
        nano \
        tmux \
        screen
    success "Monitoring tools installed"
}

# Install security tools
install_security_tools() {
    log "Installing security tools..."
    sudo apt install -y \
        ufw \
        fail2ban \
        rkhunter \
        chkrootkit \
        lynis \
        nmap \
        wireshark \
        tcpdump
    success "Security tools installed"
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dev          Install development tools"
    echo "  --web          Install web development tools"
    echo "  --python       Install Python tools"
    echo "  --database     Install database tools"
    echo "  --container    Install container tools"
    echo "  --cloud        Install cloud tools"
    echo "  --monitoring   Install monitoring tools"
    echo "  --security     Install security tools"
    echo "  --all          Install all tools (default)"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --dev --web"
    echo "  $0 --python --database"
    echo "  $0 --all"
}

# Main execution
main() {
    if [[ $# -eq 0 ]]; then
        # Default: install all tools
        log "Installing all tools..."
        install_dev_tools
        install_web_tools
        install_python_tools
        install_database_tools
        install_container_tools
        install_cloud_tools
        install_monitoring_tools
        install_security_tools
        success "All tools installed successfully!"
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --dev)
                    install_dev_tools
                    shift
                    ;;
                --web)
                    install_web_tools
                    shift
                    ;;
                --python)
                    install_python_tools
                    shift
                    ;;
                --database)
                    install_database_tools
                    shift
                    ;;
                --container)
                    install_container_tools
                    shift
                    ;;
                --cloud)
                    install_cloud_tools
                    shift
                    ;;
                --monitoring)
                    install_monitoring_tools
                    shift
                    ;;
                --security)
                    install_security_tools
                    shift
                    ;;
                --all)
                    install_dev_tools
                    install_web_tools
                    install_python_tools
                    install_database_tools
                    install_container_tools
                    install_cloud_tools
                    install_monitoring_tools
                    install_security_tools
                    success "All tools installed successfully!"
                    shift
                    ;;
                --help)
                    show_usage
                    exit 0
                    ;;
                *)
                    error "Unknown option: $1"
                    show_usage
                    exit 1
                    ;;
            esac
        done
    fi
    
    warning "Please log out and log back in for Docker group changes to take effect"
    info "Run 'source ~/.bashrc' to load any new configurations"
}

# Run main function
main "$@"
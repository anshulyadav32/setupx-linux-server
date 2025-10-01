#!/bin/bash
# GCP Root Login Script
# Enables root login for GCP VM with password authentication
# Usage: setupx -sh gcprootlogin -p passwordroot passwordubuntu

# Function to show usage
show_usage() {
    echo "GCP Root Login Script"
    echo "===================="
    echo ""
    echo "Usage: setupx -sh gcprootlogin -p <root_password> <ubuntu_password>"
    echo ""
    echo "Parameters:"
    echo "  -p, --password    Set root password and ubuntu user password"
    echo "  <root_password>   Password for root user"
    echo "  <ubuntu_password> Password for ubuntu user"
    echo ""
    echo "Examples:"
    echo "  setupx -sh gcprootlogin -p myrootpass myubuntupass"
    echo "  setupx -sh gcprootlogin --password secretroot secretubuntu"
    echo ""
}

# Function to enable root login
enable_root_login() {
    local root_password="$1"
    local ubuntu_password="$2"
    
    echo "🔧 Configuring GCP VM for root login..."
    echo ""
    
    # Check if running on GCP
    if ! curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/id >/dev/null 2>&1; then
        echo "⚠️  Warning: This script is designed for GCP VMs"
        echo "   Continuing anyway..."
        echo ""
    fi
    
    # Set root password
    echo "🔑 Setting root password..."
    echo "root:$root_password" | sudo chpasswd
    
    # Set ubuntu user password
    echo "🔑 Setting ubuntu user password..."
    echo "ubuntu:$ubuntu_password" | sudo chpasswd
    
    # Enable root login in SSH
    echo "🔧 Configuring SSH for root login..."
    
    # Backup original SSH config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
    
    # Configure SSH for root login
    sudo sed -i 's/#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    # Ensure these settings exist
    if ! grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config
    fi
    
    if ! grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo "PasswordAuthentication yes" | sudo tee -a /etc/ssh/sshd_config
    fi
    
    # Test SSH configuration
    echo "🔍 Testing SSH configuration..."
    if sudo sshd -t; then
        echo "✅ SSH configuration is valid"
    else
        echo "❌ SSH configuration has errors"
        echo "   Restoring backup..."
        sudo cp /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S) /etc/ssh/sshd_config
        exit 1
    fi
    
    # Restart SSH service
    echo "🔄 Restarting SSH service..."
    sudo systemctl restart ssh
    
    # Wait for SSH to restart
    sleep 3
    
    # Test SSH connection
    echo "🔍 Testing SSH connection..."
    if systemctl is-active ssh >/dev/null 2>&1; then
        echo "✅ SSH service is running"
    else
        echo "❌ SSH service failed to start"
        exit 1
    fi
    
    # Show connection information
    echo ""
    echo "🎉 GCP Root Login Configuration Complete!"
    echo "========================================"
    echo ""
    echo "📋 Connection Information:"
    echo "  Host: $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null || echo 'External IP not available')"
    echo "  Port: 22"
    echo "  Root Password: $root_password"
    echo "  Ubuntu Password: $ubuntu_password"
    echo ""
    echo "🔗 SSH Commands:"
    echo "  Root login: ssh root@<external-ip>"
    echo "  Ubuntu login: ssh ubuntu@<external-ip>"
    echo ""
    echo "⚠️  Security Notes:"
    echo "  - Root login is now enabled"
    echo "  - Password authentication is enabled"
    echo "  - Consider using SSH keys for better security"
    echo "  - Monitor access logs: sudo tail -f /var/log/auth.log"
    echo ""
    echo "📁 Configuration Files:"
    echo "  SSH Config: /etc/ssh/sshd_config"
    echo "  Backup: /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
    echo ""
}

# Function to show status
show_status() {
    echo "🔍 GCP Root Login Status"
    echo "======================="
    echo ""
    
    # Check SSH service
    if systemctl is-active ssh >/dev/null 2>&1; then
        echo "✅ SSH Service: Active"
    else
        echo "❌ SSH Service: Inactive"
    fi
    
    # Check root login setting
    if grep -q "PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "✅ Root Login: Enabled"
    else
        echo "❌ Root Login: Disabled"
    fi
    
    # Check password authentication
    if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo "✅ Password Auth: Enabled"
    else
        echo "❌ Password Auth: Disabled"
    fi
    
    # Show external IP
    external_ip=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip 2>/dev/null)
    if [ -n "$external_ip" ]; then
        echo "🌐 External IP: $external_ip"
    else
        echo "🌐 External IP: Not available"
    fi
    
    echo ""
}

# Main script logic
case "$1" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
    -p|--password)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "❌ Error: Both root password and ubuntu password are required"
            echo ""
            show_usage
            exit 1
        fi
        enable_root_login "$2" "$3"
        ;;
    status)
        show_status
        ;;
    *)
        echo "❌ Error: Invalid parameter"
        echo ""
        show_usage
        exit 1
        ;;
esac

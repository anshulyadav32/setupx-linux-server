#!/bin/bash
# SetupX Security Configuration Script
# Configures SSH, UFW firewall, and system security

echo "SetupX Security Configuration"
echo "============================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    echo "The script will use sudo when needed"
    exit 1
fi

# Function to configure SSH
configure_ssh() {
    echo "🔧 Configuring SSH..."
    
    # Enable SSH service
    sudo systemctl enable ssh
    sudo systemctl start ssh
    
    # Backup original SSH config
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Configure SSH for security
    sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    sudo sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
    
    # Restart SSH service
    sudo systemctl restart ssh
    
    echo "✅ SSH configured successfully"
    echo "   - Root login disabled"
    echo "   - Password authentication disabled"
    echo "   - Public key authentication enabled"
}

# Function to configure UFW firewall
configure_ufw() {
    echo "🔧 Configuring UFW Firewall..."
    
    # Install UFW if not present
    sudo apt update
    sudo apt install -y ufw
    
    # Reset UFW to defaults
    sudo ufw --force reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow ssh
    sudo ufw allow 22/tcp
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Enable UFW
    sudo ufw --force enable
    
    echo "✅ UFW firewall configured successfully"
    echo "   - Default deny incoming"
    echo "   - Default allow outgoing"
    echo "   - SSH (port 22) allowed"
    echo "   - HTTP (port 80) allowed"
    echo "   - HTTPS (port 443) allowed"
}

# Function to configure Fail2Ban
configure_fail2ban() {
    echo "🔧 Configuring Fail2Ban..."
    
    # Install Fail2Ban
    sudo apt install -y fail2ban
    
    # Create local configuration
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    
    # Configure Fail2Ban for SSH
    sudo tee /etc/fail2ban/jail.d/ssh.conf > /dev/null <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF
    
    # Start and enable Fail2Ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    
    echo "✅ Fail2Ban configured successfully"
    echo "   - SSH protection enabled"
    echo "   - Max 3 attempts before ban"
    echo "   - Ban time: 1 hour"
}

# Function to setup Chrome Remote Desktop
setup_chrome_remote() {
    echo "🔧 Setting up Chrome Remote Desktop..."
    
    # Add Google Chrome repository
    wget -qO - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list
    
    # Update package list and install Chrome
    sudo apt update
    sudo apt install -y google-chrome-stable
    
    echo "✅ Chrome Remote Desktop setup completed"
    echo "   - Google Chrome installed"
    echo "   - Visit https://remotedesktop.google.com/ to configure"
}

# Function to show security status
show_security_status() {
    echo ""
    echo "🔍 Security Status Check"
    echo "========================"
    
    # SSH Status
    if systemctl is-active ssh >/dev/null 2>&1; then
        echo "✅ SSH: Active"
    else
        echo "❌ SSH: Inactive"
    fi
    
    # UFW Status
    if command -v ufw >/dev/null 2>&1; then
        echo "✅ UFW: Installed"
        echo "   Status: $(sudo ufw status | head -1)"
    else
        echo "❌ UFW: Not installed"
    fi
    
    # Fail2Ban Status
    if systemctl is-active fail2ban >/dev/null 2>&1; then
        echo "✅ Fail2Ban: Active"
    else
        echo "❌ Fail2Ban: Inactive"
    fi
    
    # Chrome Status
    if command -v google-chrome >/dev/null 2>&1; then
        echo "✅ Chrome: Installed"
    else
        echo "❌ Chrome: Not installed"
    fi
}

# Main execution
echo "Starting security configuration..."
echo ""

# Configure all components
configure_ssh
echo ""
configure_ufw
echo ""
configure_fail2ban
echo ""
setup_chrome_remote
echo ""

# Show final status
show_security_status

echo ""
echo "🎉 Security configuration completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Configure SSH keys for your user account"
echo "2. Test SSH connection from another machine"
echo "3. Visit https://remotedesktop.google.com/ to setup remote access"
echo "4. Review UFW rules: sudo ufw status verbose"
echo "5. Monitor Fail2Ban: sudo fail2ban-client status"
echo ""
echo "⚠️  Important: Make sure you have SSH keys configured before disconnecting!"

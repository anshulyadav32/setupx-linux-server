#!/bin/bash

# Apache Domain Setup Script
# Usage: apache-domain.sh -d <domain> -p <port> [-s]

set -e

# Default values
DOMAIN=""
PORT=""
SSL=false
DOCUMENT_ROOT="/var/www/html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 -d <domain> -p <port> [-s]"
    echo ""
    echo "Options:"
    echo "  -d <domain>    Domain name (required)"
    echo "  -p <port>      Backend application port (required)"
    echo "  -s             Enable SSL with Let's Encrypt (optional)"
    echo ""
    echo "Examples:"
    echo "  $0 -d example.com -p 3000"
    echo "  $0 -d api.example.com -p 8080 -s"
}

# Parse command line arguments
while getopts "d:p:sh" opt; do
    case $opt in
        d)
            DOMAIN="$OPTARG"
            ;;
        p)
            PORT="$OPTARG"
            ;;
        s)
            SSL=true
            ;;
        h)
            show_usage
            exit 0
            ;;
        \?)
            print_error "Invalid option: -$OPTARG"
            show_usage
            exit 1
            ;;
    esac
done

# Check if required parameters are provided
if [ -z "$DOMAIN" ] || [ -z "$PORT" ]; then
    print_error "Domain and port are required"
    show_usage
    exit 1
fi

print_status "Setting up Apache domain: $DOMAIN"
print_status "Backend port: $PORT"
print_status "SSL enabled: $SSL"

# Update system packages
print_status "Updating system packages..."
apt update -y

# Install Apache if not already installed
if ! command -v apache2 &> /dev/null; then
    print_status "Installing Apache..."
    apt install -y apache2
    systemctl enable apache2
    systemctl start apache2
else
    print_status "Apache is already installed"
fi

# Enable required Apache modules
print_status "Enabling Apache modules..."
a2enmod rewrite
a2enmod proxy
a2enmod proxy_http
a2enmod headers
a2enmod ssl

# Create document root directory
print_status "Creating document root directory..."
mkdir -p "/var/www/$DOMAIN"
chown -R www-data:www-data "/var/www/$DOMAIN"
chmod -R 755 "/var/www/$DOMAIN"

# Create a simple index.html
cat > "/var/www/$DOMAIN/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to $DOMAIN</title>
</head>
<body>
    <h1>Welcome to $DOMAIN</h1>
    <p>Apache is working correctly!</p>
</body>
</html>
EOF

# Create Apache virtual host configuration
print_status "Creating Apache virtual host configuration..."
cat > "/etc/apache2/sites-available/$DOMAIN.conf" << EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot /var/www/$DOMAIN
    
    # Proxy configuration for backend
    ProxyPreserveHost On
    ProxyPass /api/ http://localhost:$PORT/
    ProxyPassReverse /api/ http://localhost:$PORT/
    
    # Logging
    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN_error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN_access.log combined
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>
EOF

# Enable the site
print_status "Enabling Apache site..."
a2ensite "$DOMAIN.conf"

# Configure SSL if requested
if [ "$SSL" = true ]; then
    print_status "Configuring SSL with Let's Encrypt..."
    
    # Install Certbot if not already installed
    if ! command -v certbot &> /dev/null; then
        print_status "Installing Certbot..."
        apt install -y certbot python3-certbot-apache
    fi
    
    # Get SSL certificate
    print_status "Obtaining SSL certificate for $DOMAIN..."
    certbot --apache -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email admin@$DOMAIN
    
    # Auto-renewal setup
    print_status "Setting up SSL certificate auto-renewal..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
fi

# Test Apache configuration
print_status "Testing Apache configuration..."
apache2ctl configtest

# Restart Apache
print_status "Restarting Apache..."
systemctl restart apache2

# Check Apache status
if systemctl is-active --quiet apache2; then
    print_success "Apache is running successfully"
else
    print_error "Apache failed to start"
    exit 1
fi

# Display configuration summary
print_success "Apache domain setup completed!"
echo ""
echo "Configuration Summary:"
echo "======================"
echo "Domain: $DOMAIN"
echo "Backend Port: $PORT"
echo "Document Root: /var/www/$DOMAIN"
echo "SSL Enabled: $SSL"
echo "Apache Status: $(systemctl is-active apache2)"
echo ""
echo "Next Steps:"
echo "1. Point your domain DNS to this server's IP address"
echo "2. Your application should be running on port $PORT"
echo "3. Access your site at: http://$DOMAIN"
if [ "$SSL" = true ]; then
    echo "4. SSL certificate is configured for: https://$DOMAIN"
fi
echo ""
echo "Apache configuration files:"
echo "- Virtual Host: /etc/apache2/sites-available/$DOMAIN.conf"
echo "- Logs: /var/log/apache2/$DOMAIN_*.log"
echo ""
echo "Useful commands:"
echo "- Check Apache status: systemctl status apache2"
echo "- View Apache logs: tail -f /var/log/apache2/$DOMAIN_error.log"
echo "- Test configuration: apache2ctl configtest"
echo "- Reload Apache: systemctl reload apache2"

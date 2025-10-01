#!/usr/bin/env bash
# SSL Certificate Setup Script
# Setup SSL certificates with Let's Encrypt for domain and www

set -euo pipefail

# Parse command line arguments
INCLUDE_WWW=true
while getopts ":d:-:h" opt; do
    case $opt in
        d) DOMAIN="$OPTARG" ;;
        -) 
            case "${OPTARG}" in
                no-www) INCLUDE_WWW=false ;;
                *) echo "Invalid option: --$OPTARG" >&2; exit 1 ;;
            esac
            ;;
        h) echo "Usage: $0 -d <domain> [--no-www]"; exit 0 ;;
        *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Check required parameters
if [[ -z "${DOMAIN:-}" ]]; then
    echo "❌ Missing required parameter: domain"
    echo "Usage: $0 -d <domain> [--no-www]"
    exit 1
fi

echo "🔒 SSL Certificate Setup"
echo "========================"
echo "Domain: $DOMAIN"
echo "Include www: $INCLUDE_WWW"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run with sudo"
    exit 1
fi

# Install Certbot
echo "📦 Installing Certbot..."
apt update
apt install -y certbot python3-certbot-nginx

# Check if Nginx is running
if ! systemctl is-active nginx >/dev/null 2>&1; then
    echo "❌ Nginx is not running"
    echo "Start Nginx first: systemctl start nginx"
    exit 1
fi

# Create basic Nginx configuration if it doesn't exist
NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN"
if [[ ! -f "$NGINX_CONFIG" ]]; then
    echo "🌐 Creating basic Nginx configuration..."
    cat > "$NGINX_CONFIG" <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location / {
        return 200 'Hello from $DOMAIN';
        add_header Content-Type text/plain;
    }
}
EOF
    
    # Enable site
    ln -sf "$NGINX_CONFIG" "/etc/nginx/sites-enabled/"
    nginx -t
    systemctl reload nginx
fi

# Generate SSL certificate
echo "🔐 Generating SSL certificate..."
if [[ "$INCLUDE_WWW" == true ]]; then
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --email admin@"$DOMAIN" --redirect
else
    certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email admin@"$DOMAIN" --redirect
fi

# Test SSL configuration
echo "🧪 Testing SSL configuration..."
if nginx -t; then
    echo "✅ SSL setup successful!"
    echo ""
    echo "📊 SSL Details:"
    echo "  Domain: $DOMAIN"
    if [[ "$INCLUDE_WWW" == true ]]; then
        echo "  www.$DOMAIN: Enabled"
    else
        echo "  www.$DOMAIN: Disabled"
    fi
    echo "  Certificate: Let's Encrypt"
    echo "  Auto-renewal: Enabled"
    echo ""
    echo "🔗 Access your site:"
    echo "  https://$DOMAIN"
    if [[ "$INCLUDE_WWW" == true ]]; then
        echo "  https://www.$DOMAIN"
    fi
    echo ""
    echo "📋 Certificate management:"
    echo "  certbot certificates"
    echo "  certbot renew"
    echo "  certbot delete -d $DOMAIN"
else
    echo "❌ SSL setup failed"
    exit 1
fi


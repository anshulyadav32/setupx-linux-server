#!/bin/bash
# Nginx Domain Setup Script
# Configure new domain in Nginx with SSL
# Usage: setupx -sh nginx-domain -d <domain> -p <port> [-s]

# Function to show usage
show_usage() {
    echo "Nginx Domain Setup Script"
    echo "========================"
    echo ""
    echo "Usage: setupx -sh nginx-domain -d <domain> -p <port> [-s]"
    echo ""
    echo "Parameters:"
    echo "  -d, --domain     Domain name (e.g., example.com)"
    echo "  -p, --port      Application port (e.g., 3000)"
    echo "  -s, --ssl       Enable SSL with Let's Encrypt"
    echo ""
    echo "Examples:"
    echo "  setupx -sh nginx-domain -d example.com -p 3000"
    echo "  setupx -sh nginx-domain -d api.example.com -p 8080 -s"
    echo "  setupx -sh nginx-domain --domain app.example.com --port 5000 --ssl"
    echo ""
}

# Function to create Nginx configuration
create_nginx_config() {
    local domain="$1"
    local port="$2"
    local enable_ssl="$3"
    
    echo "🌐 Creating Nginx configuration for $domain..."
    echo ""
    
    # Create domain directory
    local domain_dir="/var/www/$domain"
    sudo mkdir -p "$domain_dir"
    sudo chown -R www-data:www-data "$domain_dir"
    
    # Create index.html
    sudo tee "$domain_dir/index.html" > /dev/null <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$domain</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 600px; margin: 0 auto; }
        h1 { color: #333; }
        .info { background: #f4f4f4; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to $domain</h1>
        <div class="info">
            <p><strong>Domain:</strong> $domain</p>
            <p><strong>Backend Port:</strong> $port</p>
            <p><strong>SSL:</strong> $([ "$enable_ssl" = "true" ] && echo "Enabled" || echo "Disabled")</p>
            <p><strong>Status:</strong> Nginx is working correctly!</p>
        </div>
    </div>
</body>
</html>
EOF
    
    # Create Nginx configuration
    local nginx_config="/etc/nginx/sites-available/$domain"
    sudo tee "$nginx_config" > /dev/null <<EOF
server {
    listen 80;
    server_name $domain www.$domain;
    
    root /var/www/$domain;
    index index.html index.htm;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Proxy to backend application
    location /api {
        proxy_pass http://localhost:$port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 86400;
    }
    
    # Static files
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss;
}
EOF
    
    # Enable the site
    echo "🔗 Enabling Nginx site..."
    sudo ln -sf "$nginx_config" "/etc/nginx/sites-enabled/"
    
    # Test Nginx configuration
    echo "🔍 Testing Nginx configuration..."
    if sudo nginx -t; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration has errors"
        return 1
    fi
    
    # Restart Nginx
    echo "🔄 Restarting Nginx..."
    sudo systemctl restart nginx
    
    # Setup SSL if requested
    if [ "$enable_ssl" = "true" ]; then
        setup_ssl "$domain"
    fi
    
    echo ""
    echo "🎉 Nginx domain configuration completed!"
    echo "======================================"
    echo ""
    echo "📋 Configuration Details:"
    echo "  Domain: $domain"
    echo "  Backend Port: $port"
    echo "  Document Root: $domain_dir"
    echo "  Config File: $nginx_config"
    echo "  SSL: $([ "$enable_ssl" = "true" ] && echo "Enabled" || echo "Disabled")"
    echo ""
    echo "🔗 Access URLs:"
    echo "  HTTP: http://$domain"
    echo "  API: http://$domain/api"
    if [ "$enable_ssl" = "true" ]; then
        echo "  HTTPS: https://$domain"
    fi
    echo ""
    echo "📁 Files:"
    echo "  Index: $domain_dir/index.html"
    echo "  Config: $nginx_config"
    echo "  Enabled: /etc/nginx/sites-enabled/$domain"
    echo ""
}

# Function to setup SSL with Let's Encrypt
setup_ssl() {
    local domain="$1"
    
    echo "🔒 Setting up SSL for $domain..."
    echo ""
    
    # Check if Certbot is installed
    if ! command -v certbot >/dev/null 2>&1; then
        echo "📦 Installing Certbot..."
        sudo apt update
        sudo apt install -y certbot python3-certbot-nginx
    fi
    
    # Get SSL certificate
    echo "🔐 Obtaining SSL certificate..."
    sudo certbot --nginx -d "$domain" -d "www.$domain" --non-interactive --agree-tos --email admin@"$domain"
    
    # Test certificate renewal
    echo "🔄 Testing certificate renewal..."
    sudo certbot renew --dry-run
    
    echo "✅ SSL setup completed for $domain"
    echo "   Certificate: /etc/letsencrypt/live/$domain/"
    echo "   Auto-renewal: Enabled"
}

# Function to show domain status
show_domain_status() {
    echo "🔍 Nginx Domain Status"
    echo "====================="
    echo ""
    
    # Check Nginx status
    if systemctl is-active nginx >/dev/null 2>&1; then
        echo "✅ Nginx: Active"
    else
        echo "❌ Nginx: Inactive"
    fi
    
    # List enabled sites
    echo ""
    echo "📁 Enabled Sites:"
    if [ -d "/etc/nginx/sites-enabled" ]; then
        for site in /etc/nginx/sites-enabled/*; do
            if [ -f "$site" ]; then
                local site_name=$(basename "$site")
                echo "  - $site_name"
            fi
        done
    else
        echo "  No sites enabled"
    fi
    
    # Check SSL certificates
    echo ""
    echo "🔒 SSL Certificates:"
    if [ -d "/etc/letsencrypt/live" ]; then
        for cert in /etc/letsencrypt/live/*; do
            if [ -d "$cert" ]; then
                local cert_name=$(basename "$cert")
                echo "  - $cert_name"
            fi
        done
    else
        echo "  No SSL certificates found"
    fi
    
    echo ""
}

# Function to remove domain
remove_domain() {
    local domain="$1"
    
    echo "🗑️ Removing domain: $domain"
    echo ""
    
    # Disable site
    if [ -L "/etc/nginx/sites-enabled/$domain" ]; then
        echo "🔗 Disabling Nginx site..."
        sudo rm "/etc/nginx/sites-enabled/$domain"
    fi
    
    # Remove configuration
    if [ -f "/etc/nginx/sites-available/$domain" ]; then
        echo "📁 Removing configuration file..."
        sudo rm "/etc/nginx/sites-available/$domain"
    fi
    
    # Remove domain directory
    if [ -d "/var/www/$domain" ]; then
        echo "📁 Removing domain directory..."
        sudo rm -rf "/var/www/$domain"
    fi
    
    # Test and restart Nginx
    echo "🔍 Testing Nginx configuration..."
    if sudo nginx -t; then
        echo "🔄 Restarting Nginx..."
        sudo systemctl restart nginx
        echo "✅ Domain $domain removed successfully"
    else
        echo "❌ Nginx configuration has errors"
        return 1
    fi
}

# Main script logic
case "$1" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
    -d|--domain)
        domain="$2"
        port="$4"
        enable_ssl="false"
        
        # Check for SSL flag
        for arg in "$@"; do
            if [ "$arg" = "-s" ] || [ "$arg" = "--ssl" ]; then
                enable_ssl="true"
                break
            fi
        done
        
        if [ -z "$domain" ] || [ -z "$port" ]; then
            echo "❌ Error: Domain and port are required"
            echo ""
            show_usage
            exit 1
        fi
        
        create_nginx_config "$domain" "$port" "$enable_ssl"
        ;;
    remove)
        if [ -z "$2" ]; then
            echo "❌ Error: Domain name is required"
            echo "Usage: setupx -sh nginx-domain remove <domain>"
            exit 1
        fi
        
        remove_domain "$2"
        ;;
    status)
        show_domain_status
        ;;
    *)
        echo "❌ Error: Invalid parameter"
        echo ""
        show_usage
        exit 1
        ;;
esac

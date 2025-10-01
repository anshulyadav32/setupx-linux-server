#!/usr/bin/env bash
# Deploy Node.js App from Git Script
# Deploys Node.js application from Git repository with Nginx and PM2

set -euo pipefail

# Parse command line arguments
while getopts ":w:a:g:p:h" opt; do
    case $opt in
        w) WEB_NAME="$OPTARG" ;;
        a) APP_NAME="$OPTARG" ;;
        g) GIT_URL="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        h) echo "Usage: $0 -w <web_name> -a <app_name> -g <git_url> [-p <port>]"; exit 0 ;;
        *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

# Check required parameters
if [[ -z "${WEB_NAME:-}" || -z "${APP_NAME:-}" || -z "${GIT_URL:-}" ]]; then
    echo "❌ Missing required parameters"
    echo "Usage: $0 -w <web_name> -a <app_name> -g <git_url> [-p <port>]"
    exit 1
fi

# Default port
PORT=${PORT:-3000}

echo "🚀 Deploying Node.js App from Git"
echo "=================================="
echo "Web Name: $WEB_NAME"
echo "App Name: $APP_NAME"
echo "Git URL: $GIT_URL"
echo "Port: $PORT"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run with sudo"
    exit 1
fi

# Install dependencies
echo "📦 Installing dependencies..."
apt update
apt install -y nginx git nodejs npm

# Install PM2 globally
echo "📦 Installing PM2..."
npm install -g pm2

# Create application directory
APP_DIR="/var/www/$WEB_NAME"
echo "📁 Creating application directory: $APP_DIR"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Clone repository
echo "📥 Cloning repository..."
rm -rf ./*
git clone "$GIT_URL" .

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install --production

# Stop existing PM2 process
echo "🛑 Stopping existing PM2 process..."
pm2 stop "$APP_NAME" || true
pm2 delete "$APP_NAME" || true

# Start application with PM2
echo "🚀 Starting application with PM2..."
pm2 start npm --name "$APP_NAME" -- run start
pm2 startup systemd -u root --hp /root
pm2 save

# Create Nginx configuration
echo "🌐 Creating Nginx configuration..."
cat > "/etc/nginx/sites-available/$WEB_NAME" <<EOF
server {
    listen 80;
    server_name $WEB_NAME www.$WEB_NAME;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable site
echo "🔗 Enabling Nginx site..."
ln -sf "/etc/nginx/sites-available/$WEB_NAME" "/etc/nginx/sites-enabled/"
nginx -t
systemctl reload nginx

# Test deployment
echo "🧪 Testing deployment..."
sleep 5
if pm2 list | grep -q "$APP_NAME"; then
    echo "✅ Deployment successful!"
    echo ""
    echo "📊 Deployment Details:"
    echo "  Web Name: $WEB_NAME"
    echo "  App Name: $APP_NAME"
    echo "  Port: $PORT"
    echo "  Directory: $APP_DIR"
    echo "  Nginx Config: /etc/nginx/sites-available/$WEB_NAME"
    echo ""
    echo "🔗 Access your app:"
    echo "  http://$WEB_NAME"
    echo "  http://www.$WEB_NAME"
    echo ""
    echo "📋 PM2 Commands:"
    echo "  pm2 status $APP_NAME"
    echo "  pm2 logs $APP_NAME"
    echo "  pm2 restart $APP_NAME"
else
    echo "❌ Deployment failed"
    exit 1
fi


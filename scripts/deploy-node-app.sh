#!/usr/bin/env bash
set -euo pipefail

# --- Ask inputs ---
read -rp "Enter your domain (e.g. example.com): " DOMAIN
read -rp "Enter your app name (for PM2, e.g. myapp): " APP_NAME
read -rp "Enter your GitHub repo URL: " REPO_URL
read -rp "Enter your app port (default 3000): " APP_PORT
APP_PORT=${APP_PORT:-3000}

APP_DIR="/var/www/$DOMAIN"

# --- Install dependencies ---
apt-get update -y
apt-get install -y git nginx certbot python3-certbot-nginx

# --- GitHub auth if repo is private ---
if [[ "$REPO_URL" == *"github.com"* ]]; then
  if ! gh auth status &>/dev/null; then
    echo "⚠️ Repo may be private. Logging into GitHub CLI..."
    gh auth login
  fi
fi

# --- Clone repo ---
rm -rf "$APP_DIR"
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

# --- Install Node.js if missing ---
if ! command -v node &>/dev/null; then
  export NVM_DIR="/usr/local/nvm"
  mkdir -p $NVM_DIR
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  source $NVM_DIR/nvm.sh
  nvm install --lts
  nvm alias default lts/*
fi

# --- Install dependencies ---
npm install --production

# --- Setup PM2 with app name ---
npm install -g pm2
pm2 stop "$APP_NAME" || true
pm2 delete "$APP_NAME" || true
pm2 start npm --name "$APP_NAME" -- run start
pm2 startup systemd -u $USER --hp $HOME
pm2 save

# --- Setup Nginx reverse proxy ---
cat > /etc/nginx/sites-available/$DOMAIN <<NGX
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGX

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# --- Setup SSL if DNS is ready ---
if host "$DOMAIN" &>/dev/null && host "www.$DOMAIN" &>/dev/null; then
  certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || true
else
  echo "⚠️ DNS not ready for SSL (skipping certbot)."
fi

echo "✅ Deployment finished!"
echo "───────────────────────────────"
echo " Domain: https://$DOMAIN"
echo " PM2 App Name: $APP_NAME"
echo " App Directory: $APP_DIR"
echo " Logs: pm2 logs $APP_NAME"
echo "───────────────────────────────"

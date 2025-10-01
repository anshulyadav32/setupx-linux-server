#!/bin/bash
# SetupX Web Development Environment Script
# Sets up complete web development stack with databases, PM2, Nginx, SSL, and Docker

echo "SetupX Web Development Environment"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    echo "The script will use sudo when needed"
    exit 1
fi

# Function to setup PostgreSQL
setup_postgresql() {
    echo "🐘 Setting up PostgreSQL..."
    
    # Install PostgreSQL
    sudo apt update
    sudo apt install -y postgresql postgresql-contrib
    
    # Start and enable PostgreSQL
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    
    # Set up a development database
    sudo -u postgres psql -c "CREATE DATABASE devdb;"
    sudo -u postgres psql -c "CREATE USER devuser WITH ENCRYPTED PASSWORD 'devpass';"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE devdb TO devuser;"
    
    echo "✅ PostgreSQL configured successfully"
    echo "   - Database: devdb"
    echo "   - User: devuser"
    echo "   - Password: devpass"
    echo "   - Connection: psql -h localhost -U devuser -d devdb"
}

# Function to setup MySQL
setup_mysql() {
    echo "🐬 Setting up MySQL..."
    
    # Install MySQL
    sudo apt update
    sudo apt install -y mysql-server
    
    # Start and enable MySQL
    sudo systemctl start mysql
    sudo systemctl enable mysql
    
    # Secure MySQL installation
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpass';"
    sudo mysql -e "CREATE DATABASE devdb;"
    sudo mysql -e "CREATE USER 'devuser'@'localhost' IDENTIFIED BY 'devpass';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON devdb.* TO 'devuser'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    echo "✅ MySQL configured successfully"
    echo "   - Database: devdb"
    echo "   - User: devuser"
    echo "   - Password: devpass"
    echo "   - Connection: mysql -u devuser -p devdb"
}

# Function to setup Nginx
setup_nginx() {
    echo "🌐 Setting up Nginx..."
    
    # Install Nginx
    sudo apt update
    sudo apt install -y nginx
    
    # Start and enable Nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    # Create a basic configuration
    sudo tee /etc/nginx/sites-available/default > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # Proxy to Node.js app (uncomment when needed)
    # location /api {
    #     proxy_pass http://localhost:3000;
    #     proxy_http_version 1.1;
    #     proxy_set_header Upgrade \$http_upgrade;
    #     proxy_set_header Connection 'upgrade';
    #     proxy_set_header Host \$host;
    #     proxy_cache_bypass \$http_upgrade;
    # }
}
EOF
    
    # Test Nginx configuration
    sudo nginx -t
    
    # Restart Nginx
    sudo systemctl restart nginx
    
    echo "✅ Nginx configured successfully"
    echo "   - Web server running on port 80"
    echo "   - Document root: /var/www/html"
    echo "   - Configuration: /etc/nginx/sites-available/default"
}

# Function to setup SSL with Certbot
setup_ssl() {
    echo "🔒 Setting up SSL with Certbot..."
    
    # Install Certbot
    sudo apt update
    sudo apt install -y certbot python3-certbot-nginx
    
    echo "✅ Certbot installed successfully"
    echo "   - To get SSL certificate: sudo certbot --nginx -d yourdomain.com"
    echo "   - To auto-renew: sudo certbot renew --dry-run"
}

# Function to setup PM2
setup_pm2() {
    echo "⚡ Setting up PM2..."
    
    # Install PM2 globally
    npm install -g pm2
    
    # Create PM2 ecosystem file
    cat > ecosystem.config.js <<EOF
module.exports = {
  apps: [{
    name: 'web-app',
    script: 'app.js',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
EOF
    
    # Setup PM2 startup
    pm2 startup
    pm2 save
    
    echo "✅ PM2 configured successfully"
    echo "   - Process manager ready"
    echo "   - Ecosystem file: ecosystem.config.js"
    echo "   - Commands: pm2 start, pm2 stop, pm2 restart, pm2 status"
}

# Function to setup Docker
setup_docker() {
    echo "🐳 Setting up Docker..."
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    echo "✅ Docker configured successfully"
    echo "   - Docker daemon running"
    echo "   - User added to docker group"
    echo "   - Note: You may need to log out and back in for group changes to take effect"
}

# Function to create sample web app
create_sample_app() {
    echo "📝 Creating sample web application..."
    
    # Create app directory
    mkdir -p ~/web-app
    cd ~/web-app
    
    # Create package.json
    cat > package.json <<EOF
{
  "name": "web-app",
  "version": "1.0.0",
  "description": "Sample web application",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF
    
    # Create app.js
    cat > app.js <<EOF
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from SetupX Web Development Environment!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'OK', uptime: process.uptime() });
});

app.listen(PORT, () => {
  console.log(\`Server running on port \${PORT}\`);
});
EOF
    
    # Install dependencies
    npm install
    
    echo "✅ Sample web application created"
    echo "   - Location: ~/web-app"
    echo "   - Start with: npm start"
    echo "   - Development: npm run dev"
}

# Function to show status
show_status() {
    echo ""
    echo "🔍 Web Development Environment Status"
    echo "===================================="
    
    # Check services
    services=("postgresql" "mysql" "nginx" "docker")
    for service in "${services[@]}"; do
        if systemctl is-active $service >/dev/null 2>&1; then
            echo "✅ $service: Active"
        else
            echo "❌ $service: Inactive"
        fi
    done
    
    # Check tools
    tools=("node" "npm" "pm2" "psql" "mysql" "nginx" "certbot" "docker")
    for tool in "${tools[@]}"; do
        if command -v $tool >/dev/null 2>&1; then
            echo "✅ $tool: Installed"
        else
            echo "❌ $tool: Not installed"
        fi
    done
}

# Main execution
echo "Setting up complete web development environment..."
echo ""

# Setup all components
setup_postgresql
echo ""
setup_mysql
echo ""
setup_nginx
echo ""
setup_ssl
echo ""
setup_pm2
echo ""
setup_docker
echo ""
create_sample_app
echo ""

# Show final status
show_status

echo ""
echo "🎉 Web development environment setup completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Test your setup: cd ~/web-app && npm start"
echo "2. Configure PM2: pm2 start ecosystem.config.js"
echo "3. Setup SSL: sudo certbot --nginx -d yourdomain.com"
echo "4. Configure databases for your applications"
echo "5. Review Nginx configuration: /etc/nginx/sites-available/default"
echo ""
echo "🔗 Useful Commands:"
echo "- PM2: pm2 start, pm2 stop, pm2 restart, pm2 status"
echo "- Nginx: sudo systemctl restart nginx"
echo "- PostgreSQL: psql -h localhost -U devuser -d devdb"
echo "- MySQL: mysql -u devuser -p devdb"
echo "- Docker: docker run hello-world"
echo ""
echo "⚠️  Note: You may need to log out and back in for Docker group changes to take effect"

#!/bin/bash
# PM2 Deployment Script
# Deploy new application with PM2 and port configuration
# Usage: setupx -sh pm2-deploy -n <app_name> -p <port> -d <directory> [-e <env>]

# Function to show usage
show_usage() {
    echo "PM2 Deployment Script"
    echo "===================="
    echo ""
    echo "Usage: setupx -sh pm2-deploy -n <app_name> -p <port> -d <directory> [-e <env>]"
    echo ""
    echo "Parameters:"
    echo "  -n, --name      Application name"
    echo "  -p, --port      Application port"
    echo "  -d, --dir       Application directory"
    echo "  -e, --env       Environment (development, production)"
    echo ""
    echo "Examples:"
    echo "  setupx -sh pm2-deploy -n myapp -p 3000 -d /var/www/myapp"
    echo "  setupx -sh pm2-deploy -n api -p 8080 -d /home/user/api -e production"
    echo "  setupx -sh pm2-deploy --name webapp --port 5000 --dir /opt/webapp --env production"
    echo ""
}

# Function to create PM2 ecosystem file
create_ecosystem_file() {
    local app_name="$1"
    local port="$2"
    local directory="$3"
    local environment="$4"
    
    local ecosystem_file="$directory/ecosystem.config.js"
    
    echo "📝 Creating PM2 ecosystem file..."
    cat > "$ecosystem_file" <<EOF
module.exports = {
  apps: [{
    name: '$app_name',
    script: 'app.js',
    cwd: '$directory',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: '$environment',
      PORT: $port,
      HOST: '0.0.0.0'
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: $port,
      HOST: '0.0.0.0'
    },
    env_development: {
      NODE_ENV: 'development',
      PORT: $port,
      HOST: '0.0.0.0'
    },
    // Logging
    log_file: '$directory/logs/combined.log',
    out_file: '$directory/logs/out.log',
    error_file: '$directory/logs/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Auto restart
    autorestart: true,
    watch: $([ "$environment" = "development" ] && echo "true" || echo "false"),
    ignore_watch: ['node_modules', 'logs'],
    max_memory_restart: '1G',
    
    // Advanced features
    min_uptime: '10s',
    max_restarts: 10,
    restart_delay: 4000,
    
    // Health monitoring
    health_check_grace_period: 3000,
    kill_timeout: 5000,
    
    // Process management
    pid_file: '$directory/pids/$app_name.pid',
    
    // Environment variables
    env_file: '$directory/.env'
  }]
};
EOF
    
    echo "✅ Ecosystem file created: $ecosystem_file"
}

# Function to create sample application
create_sample_app() {
    local app_name="$1"
    local port="$2"
    local directory="$3"
    local environment="$4"
    
    echo "📝 Creating sample application..."
    
    # Create package.json
    cat > "$directory/package.json" <<EOF
{
  "name": "$app_name",
  "version": "1.0.0",
  "description": "PM2 managed application",
  "main": "app.js",
  "scripts": {
    "start": "node app.js",
    "dev": "nodemon app.js",
    "pm2:start": "pm2 start ecosystem.config.js",
    "pm2:stop": "pm2 stop $app_name",
    "pm2:restart": "pm2 restart $app_name",
    "pm2:delete": "pm2 delete $app_name",
    "pm2:logs": "pm2 logs $app_name",
    "pm2:status": "pm2 status"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "helmet": "^7.0.0",
    "morgan": "^1.10.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF
    
    # Create app.js
    cat > "$directory/app.js" <<EOF
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || $port;
const NODE_ENV = process.env.NODE_ENV || '$environment';

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: NODE_ENV,
    port: PORT,
    pid: process.pid,
    memory: process.memoryUsage()
  });
});

// Main route
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to $app_name!',
    environment: NODE_ENV,
    port: PORT,
    timestamp: new Date().toISOString()
  });
});

// API routes
app.get('/api/status', (req, res) => {
  res.json({
    app: '$app_name',
    status: 'running',
    environment: NODE_ENV,
    uptime: process.uptime()
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Something went wrong!',
    environment: NODE_ENV
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(\`🚀 $app_name server running on port \${PORT}\`);
  console.log(\`📊 Environment: \${NODE_ENV}\`);
  console.log(\`🔗 Health check: http://localhost:\${PORT}/health\`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});
EOF
    
    # Create .env file
    cat > "$directory/.env" <<EOF
NODE_ENV=$environment
PORT=$port
HOST=0.0.0.0
APP_NAME=$app_name
EOF
    
    echo "✅ Sample application created"
}

# Function to setup directories
setup_directories() {
    local directory="$1"
    local app_name="$2"
    
    echo "📁 Setting up directories..."
    
    # Create main directory
    mkdir -p "$directory"
    
    # Create subdirectories
    mkdir -p "$directory/logs"
    mkdir -p "$directory/pids"
    mkdir -p "$directory/tmp"
    
    # Set permissions
    chmod 755 "$directory"
    chmod 755 "$directory/logs"
    chmod 755 "$directory/pids"
    chmod 755 "$directory/tmp"
    
    echo "✅ Directories created:"
    echo "  - $directory"
    echo "  - $directory/logs"
    echo "  - $directory/pids"
    echo "  - $directory/tmp"
}

# Function to deploy application
deploy_application() {
    local app_name="$1"
    local port="$2"
    local directory="$3"
    local environment="$4"
    
    echo "🚀 Deploying application: $app_name"
    echo "=================================="
    echo ""
    
    # Setup directories
    setup_directories "$directory" "$app_name"
    
    # Create sample application
    create_sample_app "$app_name" "$port" "$directory" "$environment"
    
    # Create ecosystem file
    create_ecosystem_file "$app_name" "$port" "$directory" "$environment"
    
    # Install dependencies
    echo "📦 Installing dependencies..."
    cd "$directory"
    npm install
    
    # Start with PM2
    echo "🔄 Starting application with PM2..."
    pm2 start ecosystem.config.js --env "$environment"
    
    # Save PM2 configuration
    pm2 save
    
    # Setup PM2 startup
    pm2 startup
    
    echo ""
    echo "🎉 Application deployed successfully!"
    echo "===================================="
    echo ""
    echo "📋 Deployment Details:"
    echo "  Application: $app_name"
    echo "  Port: $port"
    echo "  Directory: $directory"
    echo "  Environment: $environment"
    echo "  PM2 Config: $directory/ecosystem.config.js"
    echo ""
    echo "🔗 Access URLs:"
    echo "  Application: http://localhost:$port"
    echo "  Health Check: http://localhost:$port/health"
    echo "  API Status: http://localhost:$port/api/status"
    echo ""
    echo "📁 Files:"
    echo "  App: $directory/app.js"
    echo "  Config: $directory/ecosystem.config.js"
    echo "  Logs: $directory/logs/"
    echo "  PIDs: $directory/pids/"
    echo ""
    echo "🔧 PM2 Commands:"
    echo "  pm2 status                    # Show status"
    echo "  pm2 logs $app_name            # Show logs"
    echo "  pm2 restart $app_name         # Restart app"
    echo "  pm2 stop $app_name            # Stop app"
    echo "  pm2 delete $app_name          # Delete app"
    echo ""
}

# Function to show PM2 status
show_pm2_status() {
    echo "🔍 PM2 Status"
    echo "============="
    echo ""
    
    # Check if PM2 is installed
    if ! command -v pm2 >/dev/null 2>&1; then
        echo "❌ PM2 is not installed"
        echo "   Install with: npm install -g pm2"
        return 1
    fi
    
    # Show PM2 status
    echo "📊 PM2 Process List:"
    pm2 status
    
    echo ""
    echo "📈 PM2 Monitoring:"
    pm2 monit --no-daemon 2>/dev/null || echo "  Monitoring not available"
    
    echo ""
    echo "📁 PM2 Configuration:"
    echo "  Config: ~/.pm2/ecosystem.config.js"
    echo "  Logs: ~/.pm2/logs/"
    echo "  PIDs: ~/.pm2/pids/"
}

# Function to remove application
remove_application() {
    local app_name="$1"
    
    echo "🗑️ Removing application: $app_name"
    echo ""
    
    # Stop and delete from PM2
    echo "🔄 Stopping PM2 process..."
    pm2 stop "$app_name" 2>/dev/null || true
    pm2 delete "$app_name" 2>/dev/null || true
    
    # Save PM2 configuration
    pm2 save
    
    echo "✅ Application $app_name removed from PM2"
}

# Main script logic
case "$1" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
    -n|--name)
        app_name="$2"
        port="$4"
        directory="$6"
        environment="development"
        
        # Parse additional arguments
        while [[ $# -gt 0 ]]; do
            case $1 in
                -e|--env)
                    environment="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        
        if [ -z "$app_name" ] || [ -z "$port" ] || [ -z "$directory" ]; then
            echo "❌ Error: App name, port, and directory are required"
            echo ""
            show_usage
            exit 1
        fi
        
        deploy_application "$app_name" "$port" "$directory" "$environment"
        ;;
    remove)
        if [ -z "$2" ]; then
            echo "❌ Error: Application name is required"
            echo "Usage: setupx -sh pm2-deploy remove <app_name>"
            exit 1
        fi
        
        remove_application "$2"
        ;;
    status)
        show_pm2_status
        ;;
    *)
        echo "❌ Error: Invalid parameter"
        echo ""
        show_usage
        exit 1
        ;;
esac

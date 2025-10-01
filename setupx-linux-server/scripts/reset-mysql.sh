#!/usr/bin/env bash
# Reset MySQL Database Script
# Resets MySQL database with default or custom parameters

set -euo pipefail

# Default values
DB_NAME="mysql"
DB_USER="root"
DB_PASS="mysql123"

# Parse command line arguments
while getopts ":d:u:p:h" opt; do
    case $opt in
        d) DB_NAME="$OPTARG" ;;
        u) DB_USER="$OPTARG" ;;
        p) DB_PASS="$OPTARG" ;;
        h) echo "Usage: sudo $0 [-d <database>] [-u <username>] [-p <password>]"; exit 0 ;;
        *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

echo "🔄 Resetting MySQL Database"
echo "============================"
echo "Database: $DB_NAME"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run with sudo"
    exit 1
fi

# Check if MySQL is installed
if ! command -v mysql >/dev/null 2>&1; then
    echo "❌ MySQL is not installed"
    echo "Install with: apt install mysql-server mysql-client"
    exit 1
fi

# Start MySQL service
echo "🚀 Starting MySQL service..."
systemctl start mysql
systemctl enable mysql

# Secure MySQL installation
echo "🔐 Securing MySQL installation..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_PASS';" || true
mysql -e "DELETE FROM mysql.user WHERE User='';" || true
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" || true
mysql -e "DROP DATABASE IF EXISTS test;" || true
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" || true
mysql -e "FLUSH PRIVILEGES;" || true

# Create database if it doesn't exist
echo "📦 Creating database '$DB_NAME'..."
mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" || true

# Create user if it doesn't exist
echo "👤 Creating user '$DB_USER'..."
mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" || true
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" || true
mysql -e "FLUSH PRIVILEGES;" || true

# Test connection
echo "🧪 Testing connection..."
if mysql -u "$DB_USER" -p"$DB_PASS" -e "SELECT VERSION();" >/dev/null 2>&1; then
    echo "✅ MySQL reset successful!"
    echo ""
    echo "📊 Connection Details:"
    echo "  Host: localhost"
    echo "  Port: 3306"
    echo "  Database: $DB_NAME"
    echo "  Username: $DB_USER"
    echo "  Password: $DB_PASS"
    echo ""
    echo "🔗 Test connection:"
    echo "  mysql -h localhost -u $DB_USER -p$DB_PASS $DB_NAME"
else
    echo "❌ MySQL reset failed"
    exit 1
fi


#!/usr/bin/env bash
# Reset PostgreSQL Database Script
# Resets PostgreSQL database with default or custom parameters

set -euo pipefail

# Default values
DB_NAME="postgres"
DB_USER="postgres"
DB_PASS="postgres123"

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

echo "🔄 Resetting PostgreSQL Database"
echo "================================="
echo "Database: $DB_NAME"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run with sudo"
    exit 1
fi

# Check if PostgreSQL is installed
if ! command -v psql >/dev/null 2>&1; then
    echo "❌ PostgreSQL is not installed"
    echo "Install with: apt install postgresql postgresql-contrib"
    exit 1
fi

# Start PostgreSQL service
echo "🚀 Starting PostgreSQL service..."
systemctl start postgresql
systemctl enable postgresql

# Reset PostgreSQL password
echo "🔐 Setting PostgreSQL password..."
sudo -u postgres psql -c "ALTER USER $DB_USER PASSWORD '$DB_PASS';" || true

# Create database if it doesn't exist
echo "📦 Creating database '$DB_NAME'..."
sudo -u postgres createdb "$DB_NAME" || echo "Database already exists"

# Grant privileges
echo "🔑 Granting privileges..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" || true

# Test connection
echo "🧪 Testing connection..."
if sudo -u postgres psql -d "$DB_NAME" -U "$DB_USER" -c "SELECT version();" >/dev/null 2>&1; then
    echo "✅ PostgreSQL reset successful!"
    echo ""
    echo "📊 Connection Details:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  Database: $DB_NAME"
    echo "  Username: $DB_USER"
    echo "  Password: $DB_PASS"
    echo ""
    echo "🔗 Test connection:"
    echo "  psql -h localhost -U $DB_USER -d $DB_NAME"
else
    echo "❌ PostgreSQL reset failed"
    exit 1
fi


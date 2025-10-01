#!/usr/bin/env bash
# Reset MongoDB Database Script
# Resets MongoDB database with default or custom parameters

set -euo pipefail

# Default values
DB_NAME="mongodb"
DB_USER="admin"
DB_PASS="mongodb123"

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

echo "🔄 Resetting MongoDB Database"
echo "=============================="
echo "Database: $DB_NAME"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run with sudo"
    exit 1
fi

# Check if MongoDB is installed
if ! command -v mongod >/dev/null 2>&1; then
    echo "❌ MongoDB is not installed"
    echo "Install with: apt install mongodb-org"
    exit 1
fi

# Start MongoDB service
echo "🚀 Starting MongoDB service..."
systemctl start mongod
systemctl enable mongod

# Wait for MongoDB to start
echo "⏳ Waiting for MongoDB to start..."
sleep 5

# Create admin user
echo "👤 Creating admin user..."
mongosh --eval "db.adminCommand('createUser', {user: '$DB_USER', pwd: '$DB_PASS', roles: ['userAdminAnyDatabase', 'dbAdminAnyDatabase', 'readWriteAnyDatabase']})" admin || true

# Create database
echo "📦 Creating database '$DB_NAME'..."
mongosh --eval "use $DB_NAME; db.test.insertOne({test: 'data'})" || true

# Test connection
echo "🧪 Testing connection..."
if mongosh --eval "db.adminCommand('listCollections')" "$DB_NAME" >/dev/null 2>&1; then
    echo "✅ MongoDB reset successful!"
    echo ""
    echo "📊 Connection Details:"
    echo "  Host: localhost"
    echo "  Port: 27017"
    echo "  Database: $DB_NAME"
    echo "  Username: $DB_USER"
    echo "  Password: $DB_PASS"
    echo ""
    echo "🔗 Test connection:"
    echo "  mongosh mongodb://$DB_USER:$DB_PASS@localhost:27017/$DB_NAME"
else
    echo "❌ MongoDB reset failed"
    exit 1
fi


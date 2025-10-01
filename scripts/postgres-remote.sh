#!/usr/bin/env bash
# PostgreSQL Remote Server Setup Script
# Configure PostgreSQL for remote connections

set -euo pipefail

# Default values
PORT=5432
ALLOWED_IPS="0.0.0.0/0"

# Parse command line arguments
while getopts ":p:i:h" opt; do
    case $opt in
        p) PORT="$OPTARG" ;;
        i) ALLOWED_IPS="$OPTARG" ;;
        h) echo "Usage: sudo $0 [-p <port>] [-i <allowed_ips>]"; exit 0 ;;
        *) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    esac
done

echo "🌐 PostgreSQL Remote Server Setup"
echo "=================================="
echo "Port: $PORT"
echo "Allowed IPs: $ALLOWED_IPS"
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

# Configure PostgreSQL for remote connections
echo "🔧 Configuring PostgreSQL for remote connections..."

# Update postgresql.conf
POSTGRESQL_CONF="/etc/postgresql/*/main/postgresql.conf"
echo "📝 Updating postgresql.conf..."
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $POSTGRESQL_CONF
sed -i "s/#port = 5432/port = $PORT/" $POSTGRESQL_CONF

# Update pg_hba.conf
PG_HBA_CONF="/etc/postgresql/*/main/pg_hba.conf"
echo "📝 Updating pg_hba.conf..."
echo "host    all             all             $ALLOWED_IPS            md5" >> $PG_HBA_CONF

# Restart PostgreSQL
echo "♻️ Restarting PostgreSQL..."
systemctl restart postgresql

# Configure firewall
echo "🔥 Configuring firewall..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow $PORT/tcp
    echo "✅ Firewall rule added for port $PORT"
fi

# Test connection
echo "🧪 Testing connection..."
sleep 3
if systemctl is-active postgresql >/dev/null 2>&1; then
    echo "✅ PostgreSQL remote setup successful!"
    echo ""
    echo "📊 Remote Connection Details:"
    echo "  Host: $(hostname -I | awk '{print $1}')"
    echo "  Port: $PORT"
    echo "  Allowed IPs: $ALLOWED_IPS"
    echo ""
    echo "🔗 Test remote connection:"
    echo "  psql -h $(hostname -I | awk '{print $1}') -p $PORT -U postgres -d postgres"
    echo ""
    echo "📋 Connection examples:"
    echo "  From another server:"
    echo "    psql -h $(hostname -I | awk '{print $1}') -p $PORT -U postgres"
    echo "  From local machine:"
    echo "    psql -h localhost -p $PORT -U postgres"
    echo ""
    echo "⚠️ Security Notes:"
    echo "  - Change default passwords"
    echo "  - Use strong authentication"
    echo "  - Consider IP restrictions"
    echo "  - Enable SSL if needed"
else
    echo "❌ PostgreSQL remote setup failed"
    exit 1
fi


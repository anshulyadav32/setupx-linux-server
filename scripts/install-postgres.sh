#!/usr/bin/env bash
set -euo pipefail

# Default values
DB_NAME="mydb"
DB_USER="dbuser"
DB_PASS="dbpass123"

while getopts ":d:u:p:h" opt; do
  case $opt in
    d) DB_NAME="$OPTARG" ;;
    u) DB_USER="$OPTARG" ;;
    p) DB_PASS="$OPTARG" ;;
    h) echo "Usage: sudo $0 [-d dbname] [-u dbuser] [-p dbpass]"; exit 0 ;;
  esac
done

echo "🔎 Installing PostgreSQL..."

# Add PostgreSQL official repo for latest version
apt-get update -y
apt-get install -y wget gnupg lsb-release

sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

apt-get update -y
apt-get install -y postgresql postgresql-contrib

# Enable & start service
systemctl enable postgresql
systemctl start postgresql

# Detect version
PG_VER=$(psql -V | awk '{print $3}' | cut -d. -f1)

echo "🔐 Creating database and user..."
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}'" || true
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}" || true
sudo -u postgres psql -c "ALTER USER ${DB_USER} CREATEDB;" || true

# Save credentials
CREDFILE="$HOME/.db_cred"
cat > "$CREDFILE" <<CRED
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
CRED
chmod 600 "$CREDFILE"

echo "✅ PostgreSQL installed!"
echo "───────────────────────────────"
echo "DB_NAME = ${DB_NAME}"
echo "DB_USER = ${DB_USER}"
echo "DB_PASS = ${DB_PASS}"
echo "PG_VERSION = ${PG_VER}"
echo "Creds saved in $CREDFILE"
echo
echo "👉 Test with:"
echo "   sudo -u postgres psql -d ${DB_NAME} -U ${DB_USER} -W"
echo "───────────────────────────────"

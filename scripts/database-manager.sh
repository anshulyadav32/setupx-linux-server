#!/bin/bash
# Database Management Script
# Comprehensive database management for PostgreSQL, MySQL, MongoDB, Redis, and more

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to install PostgreSQL
install_postgresql() {
    print_header "Installing PostgreSQL"
    
    # Update package list
    apt update
    
    # Install PostgreSQL
    apt install -y postgresql postgresql-contrib postgresql-client
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Set up PostgreSQL
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres123';"
    
    print_status "PostgreSQL installed and configured"
    print_status "Default password: postgres123"
}

# Function to install MySQL
install_mysql() {
    print_header "Installing MySQL"
    
    # Update package list
    apt update
    
    # Install MySQL
    apt install -y mysql-server mysql-client
    
    # Start and enable MySQL
    systemctl start mysql
    systemctl enable mysql
    
    # Secure MySQL installation
    mysql_secure_installation
    
    print_status "MySQL installed and configured"
}

# Function to install MariaDB
install_mariadb() {
    print_header "Installing MariaDB"
    
    # Update package list
    apt update
    
    # Install MariaDB
    apt install -y mariadb-server mariadb-client
    
    # Start and enable MariaDB
    systemctl start mariadb
    systemctl enable mariadb
    
    # Secure MariaDB installation
    mysql_secure_installation
    
    print_status "MariaDB installed and configured"
}

# Function to install MongoDB
install_mongodb() {
    print_header "Installing MongoDB"
    
    # Add MongoDB GPG key
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    
    # Add MongoDB repository
    echo 'deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse' | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    
    # Update package list
    apt update
    
    # Install MongoDB
    apt install -y mongodb-org
    
    # Start and enable MongoDB
    systemctl start mongod
    systemctl enable mongod
    
    print_status "MongoDB installed and configured"
}

# Function to install Redis
install_redis() {
    print_header "Installing Redis"
    
    # Update package list
    apt update
    
    # Install Redis
    apt install -y redis-server
    
    # Configure Redis
    sed -i 's/^# requirepass foobared/requirepass redis123/' /etc/redis/redis.conf
    
    # Start and enable Redis
    systemctl start redis-server
    systemctl enable redis-server
    
    print_status "Redis installed and configured"
    print_status "Default password: redis123"
}

# Function to install SQLite
install_sqlite() {
    print_header "Installing SQLite"
    
    # Update package list
    apt update
    
    # Install SQLite
    apt install -y sqlite3 libsqlite3-dev
    
    print_status "SQLite installed"
}

# Function to install Cassandra
install_cassandra() {
    print_header "Installing Apache Cassandra"
    
    # Add Cassandra GPG key
    curl -fsSL https://www.apache.org/dist/cassandra/KEYS | gpg --dearmor -o /usr/share/keyrings/cassandra-archive-keyring.gpg
    
    # Add Cassandra repository
    echo 'deb [signed-by=/usr/share/keyrings/cassandra-archive-keyring.gpg] https://downloads.apache.org/cassandra/debian/40x main' | tee /etc/apt/sources.list.d/cassandra.list
    
    # Update package list
    apt update
    
    # Install Cassandra
    apt install -y cassandra
    
    # Start and enable Cassandra
    systemctl start cassandra
    systemctl enable cassandra
    
    print_status "Cassandra installed and configured"
}

# Function to install Elasticsearch
install_elasticsearch() {
    print_header "Installing Elasticsearch"
    
    # Add Elasticsearch GPG key
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
    
    # Add Elasticsearch repository
    echo 'deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main' | tee /etc/apt/sources.list.d/elastic-8.x.list
    
    # Update package list
    apt update
    
    # Install Elasticsearch
    apt install -y elasticsearch
    
    # Configure Elasticsearch
    echo "discovery.type: single-node" >> /etc/elasticsearch/elasticsearch.yml
    
    # Start and enable Elasticsearch
    systemctl start elasticsearch
    systemctl enable elasticsearch
    
    print_status "Elasticsearch installed and configured"
}

# Function to install InfluxDB
install_influxdb() {
    print_header "Installing InfluxDB"
    
    # Add InfluxDB GPG key
    curl -fsSL https://repos.influxdata.com/influxdb.key | gpg --dearmor -o /usr/share/keyrings/influxdb-archive-keyring.gpg
    
    # Add InfluxDB repository
    echo 'deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdb.list
    
    # Update package list
    apt update
    
    # Install InfluxDB
    apt install -y influxdb2
    
    # Start and enable InfluxDB
    systemctl start influxdb
    systemctl enable influxdb
    
    print_status "InfluxDB installed and configured"
}

# Function to install Neo4j
install_neo4j() {
    print_header "Installing Neo4j"
    
    # Add Neo4j GPG key
    curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /usr/share/keyrings/neo4j.gpg
    
    # Add Neo4j repository
    echo 'deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable 5' | tee /etc/apt/sources.list.d/neo4j.list
    
    # Update package list
    apt update
    
    # Install Neo4j
    apt install -y neo4j
    
    # Start and enable Neo4j
    systemctl start neo4j
    systemctl enable neo4j
    
    print_status "Neo4j installed and configured"
}

# Function to install CouchDB
install_couchdb() {
    print_header "Installing Apache CouchDB"
    
    # Add CouchDB GPG key
    curl -fsSL https://couchdb.apache.org/repo/keys.asc | gpg --dearmor -o /usr/share/keyrings/couchdb-archive-keyring.gpg
    
    # Add CouchDB repository
    echo 'deb [signed-by=/usr/share/keyrings/couchdb-archive-keyring.gpg] https://apache.jfrog.io/artifactory/couchdb-deb/ jammy main' | tee /etc/apt/sources.list.d/couchdb.list
    
    # Update package list
    apt update
    
    # Install CouchDB
    apt install -y couchdb
    
    # Start and enable CouchDB
    systemctl start couchdb
    systemctl enable couchdb
    
    print_status "CouchDB installed and configured"
}

# Function to install database tools
install_database_tools() {
    print_header "Installing Database Management Tools"
    
    # Update package list
    apt update
    
    # Install database tools
    apt install -y pgadmin4 mysql-workbench dbeaver-ce phpmyadmin adminer
    
    print_status "Database management tools installed"
}

# Function to create database backup
create_database_backup() {
    local db_type="$1"
    local backup_dir="/var/backups/databases"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    case "$db_type" in
        "postgresql")
            print_header "Creating PostgreSQL Backup"
            sudo -u postgres pg_dumpall > "$backup_dir/postgresql_backup_$(date +%Y%m%d_%H%M%S).sql"
            print_status "PostgreSQL backup created"
            ;;
        "mysql")
            print_header "Creating MySQL Backup"
            mysqldump --all-databases > "$backup_dir/mysql_backup_$(date +%Y%m%d_%H%M%S).sql"
            print_status "MySQL backup created"
            ;;
        "mongodb")
            print_header "Creating MongoDB Backup"
            mongodump --out "$backup_dir/mongodb_backup_$(date +%Y%m%d_%H%M%S)"
            print_status "MongoDB backup created"
            ;;
        *)
            print_error "Unsupported database type: $db_type"
            ;;
    esac
}

# Function to show database status
show_database_status() {
    print_header "Database Status"
    
    echo "PostgreSQL: $(systemctl is-active postgresql 2>/dev/null || echo 'Not installed')"
    echo "MySQL: $(systemctl is-active mysql 2>/dev/null || echo 'Not installed')"
    echo "MariaDB: $(systemctl is-active mariadb 2>/dev/null || echo 'Not installed')"
    echo "MongoDB: $(systemctl is-active mongod 2>/dev/null || echo 'Not installed')"
    echo "Redis: $(systemctl is-active redis-server 2>/dev/null || echo 'Not installed')"
    echo "Cassandra: $(systemctl is-active cassandra 2>/dev/null || echo 'Not installed')"
    echo "Elasticsearch: $(systemctl is-active elasticsearch 2>/dev/null || echo 'Not installed')"
    echo "InfluxDB: $(systemctl is-active influxdb 2>/dev/null || echo 'Not installed')"
    echo "Neo4j: $(systemctl is-active neo4j 2>/dev/null || echo 'Not installed')"
    echo "CouchDB: $(systemctl is-active couchdb 2>/dev/null || echo 'Not installed')"
}

# Function to show help
show_help() {
    echo "Database Management Script"
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  install-postgresql    Install PostgreSQL"
    echo "  install-mysql        Install MySQL"
    echo "  install-mariadb      Install MariaDB"
    echo "  install-mongodb      Install MongoDB"
    echo "  install-redis        Install Redis"
    echo "  install-sqlite       Install SQLite"
    echo "  install-cassandra    Install Cassandra"
    echo "  install-elasticsearch Install Elasticsearch"
    echo "  install-influxdb     Install InfluxDB"
    echo "  install-neo4j       Install Neo4j"
    echo "  install-couchdb     Install CouchDB"
    echo "  install-tools       Install database management tools"
    echo "  backup [db-type]     Create database backup"
    echo "  status               Show database status"
    echo "  help                 Show this help"
}

# Main script logic
main() {
    check_root
    
    case "${1:-help}" in
        "install-postgresql")
            install_postgresql
            ;;
        "install-mysql")
            install_mysql
            ;;
        "install-mariadb")
            install_mariadb
            ;;
        "install-mongodb")
            install_mongodb
            ;;
        "install-redis")
            install_redis
            ;;
        "install-sqlite")
            install_sqlite
            ;;
        "install-cassandra")
            install_cassandra
            ;;
        "install-elasticsearch")
            install_elasticsearch
            ;;
        "install-influxdb")
            install_influxdb
            ;;
        "install-neo4j")
            install_neo4j
            ;;
        "install-couchdb")
            install_couchdb
            ;;
        "install-tools")
            install_database_tools
            ;;
        "backup")
            create_database_backup "$2"
            ;;
        "status")
            show_database_status
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"

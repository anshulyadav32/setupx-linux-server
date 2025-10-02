#!/bin/bash
# Database Reset Script
# Reset passwords and configurations for all database systems

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

# Function to reset PostgreSQL
reset_postgresql() {
    local new_password="${1:-postgres123}"
    
    print_header "Resetting PostgreSQL"
    
    # Stop PostgreSQL
    systemctl stop postgresql
    
    # Start PostgreSQL in single-user mode
    sudo -u postgres postgres --single -D /var/lib/postgresql/data &
    sleep 5
    
    # Reset password
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$new_password';"
    
    # Restart PostgreSQL
    systemctl start postgresql
    
    print_status "PostgreSQL password reset to: $new_password"
}

# Function to reset MySQL
reset_mysql() {
    local new_password="${1:-mysql123}"
    
    print_header "Resetting MySQL"
    
    # Stop MySQL
    systemctl stop mysql
    
    # Start MySQL in safe mode
    mysqld_safe --skip-grant-tables &
    sleep 5
    
    # Reset password
    mysql -u root -e "USE mysql; UPDATE user SET authentication_string=PASSWORD('$new_password') WHERE User='root'; FLUSH PRIVILEGES;"
    
    # Stop safe mode MySQL
    pkill mysqld
    
    # Restart MySQL
    systemctl start mysql
    
    print_status "MySQL password reset to: $new_password"
}

# Function to reset MariaDB
reset_mariadb() {
    local new_password="${1:-mariadb123}"
    
    print_header "Resetting MariaDB"
    
    # Stop MariaDB
    systemctl stop mariadb
    
    # Start MariaDB in safe mode
    mysqld_safe --skip-grant-tables &
    sleep 5
    
    # Reset password
    mysql -u root -e "USE mysql; UPDATE user SET authentication_string=PASSWORD('$new_password') WHERE User='root'; FLUSH PRIVILEGES;"
    
    # Stop safe mode MariaDB
    pkill mysqld
    
    # Restart MariaDB
    systemctl start mariadb
    
    print_status "MariaDB password reset to: $new_password"
}

# Function to reset MongoDB
reset_mongodb() {
    local new_password="${1:-mongodb123}"
    
    print_header "Resetting MongoDB"
    
    # Stop MongoDB
    systemctl stop mongod
    
    # Start MongoDB without authentication
    mongod --noauth --port 27017 &
    sleep 5
    
    # Reset password
    mongo admin --eval "db.createUser({user: 'admin', pwd: '$new_password', roles: ['userAdminAnyDatabase', 'dbAdminAnyDatabase', 'readWriteAnyDatabase']})"
    
    # Stop MongoDB
    pkill mongod
    
    # Restart MongoDB
    systemctl start mongod
    
    print_status "MongoDB password reset to: $new_password"
}

# Function to reset Redis
reset_redis() {
    local new_password="${1:-redis123}"
    
    print_header "Resetting Redis"
    
    # Stop Redis
    systemctl stop redis-server
    
    # Update Redis configuration
    sed -i "s/^requirepass.*/requirepass $new_password/" /etc/redis/redis.conf
    
    # Start Redis
    systemctl start redis-server
    
    print_status "Redis password reset to: $new_password"
}

# Function to create new database
create_database() {
    local db_type="$1"
    local db_name="$2"
    local db_user="$3"
    local db_password="$4"
    
    case "$db_type" in
        "postgresql")
            print_header "Creating PostgreSQL Database"
            sudo -u postgres createdb "$db_name"
            sudo -u postgres psql -c "CREATE USER $db_user WITH PASSWORD '$db_password';"
            sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;"
            print_status "PostgreSQL database '$db_name' created with user '$db_user'"
            ;;
        "mysql")
            print_header "Creating MySQL Database"
            mysql -u root -p -e "CREATE DATABASE $db_name;"
            mysql -u root -p -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_password';"
            mysql -u root -p -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
            mysql -u root -p -e "FLUSH PRIVILEGES;"
            print_status "MySQL database '$db_name' created with user '$db_user'"
            ;;
        "mongodb")
            print_header "Creating MongoDB Database"
            mongo admin --eval "use $db_name; db.createUser({user: '$db_user', pwd: '$db_password', roles: ['readWrite']})"
            print_status "MongoDB database '$db_name' created with user '$db_user'"
            ;;
        *)
            print_error "Unsupported database type: $db_type"
            ;;
    esac
}

# Function to show help
show_help() {
    echo "Database Reset Script"
    echo "Usage: $0 [OPTION] [PASSWORD]"
    echo ""
    echo "Options:"
    echo "  reset-postgresql [password]    Reset PostgreSQL password"
    echo "  reset-mysql [password]        Reset MySQL password"
    echo "  reset-mariadb [password]      Reset MariaDB password"
    echo "  reset-mongodb [password]      Reset MongoDB password"
    echo "  reset-redis [password]        Reset Redis password"
    echo "  create-db [type] [name] [user] [pass]  Create new database"
    echo "  help                          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 reset-postgresql newpass123"
    echo "  $0 reset-mysql mysql456"
    echo "  $0 create-db postgresql myapp myuser mypass123"
}

# Main script logic
main() {
    check_root
    
    case "${1:-help}" in
        "reset-postgresql")
            reset_postgresql "$2"
            ;;
        "reset-mysql")
            reset_mysql "$2"
            ;;
        "reset-mariadb")
            reset_mariadb "$2"
            ;;
        "reset-mongodb")
            reset_mongodb "$2"
            ;;
        "reset-redis")
            reset_redis "$2"
            ;;
        "create-db")
            create_database "$2" "$3" "$4" "$5"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"

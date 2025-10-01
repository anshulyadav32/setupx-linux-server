#!/bin/bash
# SetCP - Database Password Management Script
# Reset PostgreSQL, MySQL, and MongoDB passwords
# Usage: setupx -sh setcp -p <database> <new_password>

# Function to show usage
show_usage() {
    echo "SetCP - Database Password Management"
    echo "==================================="
    echo ""
    echo "Usage: setupx -sh setcp -p <database> <new_password>"
    echo ""
    echo "Parameters:"
    echo "  -p, --password    Set database password"
    echo "  <database>       Database type: postgresql, mysql, mongodb"
    echo "  <new_password>   New password for the database"
    echo ""
    echo "Examples:"
    echo "  setupx -sh setcp -p postgresql newpass123"
    echo "  setupx -sh setcp -p mysql newpass123"
    echo "  setupx -sh setcp -p mongodb newpass123"
    echo ""
    echo "Available databases:"
    echo "  postgresql  - PostgreSQL database"
    echo "  mysql       - MySQL database"
    echo "  mongodb     - MongoDB database"
    echo ""
}

# Function to reset PostgreSQL password
reset_postgresql_password() {
    local new_password="$1"
    
    echo "🐘 Resetting PostgreSQL password..."
    echo ""
    
    # Check if PostgreSQL is running
    if ! systemctl is-active postgresql >/dev/null 2>&1; then
        echo "❌ PostgreSQL service is not running"
        echo "   Starting PostgreSQL service..."
        sudo systemctl start postgresql
        sudo systemctl enable postgresql
    fi
    
    # Reset postgres user password
    echo "🔑 Setting postgres user password..."
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$new_password';"
    
    # Update pg_hba.conf to allow password authentication
    echo "🔧 Configuring PostgreSQL authentication..."
    sudo sed -i "s/local   all             all                                     peer/local   all             all                                     md5/" /etc/postgresql/*/main/pg_hba.conf
    
    # Restart PostgreSQL
    echo "🔄 Restarting PostgreSQL service..."
    sudo systemctl restart postgresql
    
    # Test connection
    echo "🔍 Testing PostgreSQL connection..."
    if PGPASSWORD="$new_password" psql -h localhost -U postgres -c "SELECT version();" >/dev/null 2>&1; then
        echo "✅ PostgreSQL password reset successful"
        echo "   Connection: psql -h localhost -U postgres"
        echo "   Password: $new_password"
    else
        echo "❌ PostgreSQL password reset failed"
        return 1
    fi
}

# Function to reset MySQL password
reset_mysql_password() {
    local new_password="$1"
    
    echo "🐬 Resetting MySQL password..."
    echo ""
    
    # Check if MySQL is running
    if ! systemctl is-active mysql >/dev/null 2>&1; then
        echo "❌ MySQL service is not running"
        echo "   Starting MySQL service..."
        sudo systemctl start mysql
        sudo systemctl enable mysql
    fi
    
    # Reset root password
    echo "🔑 Setting MySQL root password..."
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$new_password';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    
    # Test connection
    echo "🔍 Testing MySQL connection..."
    if mysql -u root -p"$new_password" -e "SELECT VERSION();" >/dev/null 2>&1; then
        echo "✅ MySQL password reset successful"
        echo "   Connection: mysql -u root -p"
        echo "   Password: $new_password"
    else
        echo "❌ MySQL password reset failed"
        return 1
    fi
}

# Function to reset MongoDB password
reset_mongodb_password() {
    local new_password="$1"
    
    echo "🍃 Resetting MongoDB password..."
    echo ""
    
    # Check if MongoDB is running
    if ! systemctl is-active mongod >/dev/null 2>&1; then
        echo "❌ MongoDB service is not running"
        echo "   Starting MongoDB service..."
        sudo systemctl start mongod
        sudo systemctl enable mongod
    fi
    
    # Create admin user if it doesn't exist
    echo "🔑 Setting MongoDB admin password..."
    mongo admin --eval "db.createUser({user: 'admin', pwd: '$new_password', roles: ['userAdminAnyDatabase', 'dbAdminAnyDatabase', 'readWriteAnyDatabase']})" 2>/dev/null || \
    mongo admin --eval "db.changeUserPassword('admin', '$new_password')" 2>/dev/null
    
    # Test connection
    echo "🔍 Testing MongoDB connection..."
    if mongo admin -u admin -p"$new_password" --eval "db.runCommand('ping')" >/dev/null 2>&1; then
        echo "✅ MongoDB password reset successful"
        echo "   Connection: mongo admin -u admin -p"
        echo "   Password: $new_password"
    else
        echo "❌ MongoDB password reset failed"
        return 1
    fi
}

# Function to create PostgreSQL database and user
create_postgresql_db_user() {
    local db_name="$1"
    local username="$2"
    local password="$3"
    
    echo "🐘 Creating PostgreSQL database and user..."
    echo ""
    
    # Create database
    echo "📁 Creating database: $db_name"
    sudo -u postgres createdb "$db_name"
    
    # Create user
    echo "👤 Creating user: $username"
    sudo -u postgres psql -c "CREATE USER $username WITH ENCRYPTED PASSWORD '$password';"
    
    # Grant privileges
    echo "🔑 Granting privileges..."
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $username;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON SCHEMA public TO $username;"
    
    # Test connection
    echo "🔍 Testing database connection..."
    if PGPASSWORD="$password" psql -h localhost -U "$username" -d "$db_name" -c "SELECT current_database();" >/dev/null 2>&1; then
        echo "✅ PostgreSQL database and user created successfully"
        echo "   Database: $db_name"
        echo "   User: $username"
        echo "   Password: $password"
        echo "   Connection: psql -h localhost -U $username -d $db_name"
    else
        echo "❌ PostgreSQL database creation failed"
        return 1
    fi
}

# Function to show database status
show_database_status() {
    echo "🔍 Database Status"
    echo "================="
    echo ""
    
    # PostgreSQL status
    if systemctl is-active postgresql >/dev/null 2>&1; then
        echo "✅ PostgreSQL: Active"
        echo "   Service: $(systemctl is-active postgresql)"
        echo "   Version: $(sudo -u postgres psql -c 'SELECT version();' 2>/dev/null | head -1 | cut -d' ' -f3-5)"
    else
        echo "❌ PostgreSQL: Inactive"
    fi
    
    # MySQL status
    if systemctl is-active mysql >/dev/null 2>&1; then
        echo "✅ MySQL: Active"
        echo "   Service: $(systemctl is-active mysql)"
        echo "   Version: $(mysql --version | cut -d' ' -f3)"
    else
        echo "❌ MySQL: Inactive"
    fi
    
    # MongoDB status
    if systemctl is-active mongod >/dev/null 2>&1; then
        echo "✅ MongoDB: Active"
        echo "   Service: $(systemctl is-active mongod)"
        echo "   Version: $(mongo --version | head -1 | cut -d' ' -f3)"
    else
        echo "❌ MongoDB: Inactive"
    fi
    
    echo ""
}

# Main script logic
case "$1" in
    -h|--help|help)
        show_usage
        exit 0
        ;;
    -p|--password)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "❌ Error: Database type and password are required"
            echo ""
            show_usage
            exit 1
        fi
        
        database_type="$2"
        new_password="$3"
        
        case "$database_type" in
            postgresql|postgres)
                reset_postgresql_password "$new_password"
                ;;
            mysql)
                reset_mysql_password "$new_password"
                ;;
            mongodb|mongo)
                reset_mongodb_password "$new_password"
                ;;
            *)
                echo "❌ Error: Unknown database type '$database_type'"
                echo "   Available types: postgresql, mysql, mongodb"
                exit 1
                ;;
        esac
        ;;
    create-db)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "❌ Error: Database name, username, and password are required"
            echo "Usage: setupx -sh setcp create-db <db_name> <username> <password>"
            exit 1
        fi
        
        create_postgresql_db_user "$2" "$3" "$4"
        ;;
    status)
        show_database_status
        ;;
    *)
        echo "❌ Error: Invalid parameter"
        echo ""
        show_usage
        exit 1
        ;;
esac

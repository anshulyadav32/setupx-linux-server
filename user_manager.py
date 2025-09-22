#!/usr/bin/env python3
"""
User Management System
Handles user authentication, registration, and session management for the SMTP web application.
"""

import sqlite3
import hashlib
import secrets
import os
from datetime import datetime, timedelta
import logging
from functools import wraps
from flask import session, request, redirect, url_for, flash

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class UserManager:
    """User management class for handling authentication"""
    
    def __init__(self, db_path='data/users.db'):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize the user database"""
        # Ensure data directory exists
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create users table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                salt TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_login TIMESTAMP,
                is_active BOOLEAN DEFAULT 1,
                is_admin BOOLEAN DEFAULT 0,
                failed_login_attempts INTEGER DEFAULT 0,
                locked_until TIMESTAMP
            )
        ''')
        
        # Create sessions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_sessions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id INTEGER NOT NULL,
                session_token TEXT UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                expires_at TIMESTAMP NOT NULL,
                ip_address TEXT,
                user_agent TEXT,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (user_id) REFERENCES users (id)
            )
        ''')
        
        conn.commit()
        conn.close()
        
        # Create default admin user if no users exist
        self.create_default_admin()
        
        logger.info("User database initialized")
    
    def create_default_admin(self):
        """Create default admin user if no users exist"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('SELECT COUNT(*) FROM users')
        user_count = cursor.fetchone()[0]
        
        if user_count == 0:
            # Create default admin user
            admin_password = 'admin123'  # Should be changed on first login
            self.create_user('admin', 'admin@localhost', admin_password, is_admin=True)
            logger.info("Default admin user created (username: admin, password: admin123)")
            print("Default admin user created:")
            print("Username: admin")
            print("Password: admin123")
            print("Please change this password after first login!")
        
        conn.close()
    
    def hash_password(self, password, salt=None):
        """Hash password with salt"""
        if salt is None:
            salt = secrets.token_hex(32)
        
        password_hash = hashlib.pbkdf2_hmac('sha256', 
                                          password.encode('utf-8'), 
                                          salt.encode('utf-8'), 
                                          100000)
        return password_hash.hex(), salt
    
    def create_user(self, username, email, password, is_admin=False):
        """Create a new user"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Check if user already exists
            cursor.execute('SELECT id FROM users WHERE username = ? OR email = ?', 
                         (username, email))
            if cursor.fetchone():
                return False, "User already exists"
            
            # Hash password
            password_hash, salt = self.hash_password(password)
            
            # Insert user
            cursor.execute('''
                INSERT INTO users (username, email, password_hash, salt, is_admin)
                VALUES (?, ?, ?, ?, ?)
            ''', (username, email, password_hash, salt, is_admin))
            
            conn.commit()
            user_id = cursor.lastrowid
            conn.close()
            
            logger.info(f"User created: {username} (ID: {user_id})")
            return True, "User created successfully"
            
        except Exception as e:
            logger.error(f"Error creating user: {e}")
            return False, str(e)
    
    def authenticate_user(self, username, password, ip_address=None, user_agent=None):
        """Authenticate user and create session"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get user data
            cursor.execute('''
                SELECT id, username, email, password_hash, salt, is_active, 
                       failed_login_attempts, locked_until
                FROM users WHERE username = ? OR email = ?
            ''', (username, username))
            
            user_data = cursor.fetchone()
            if not user_data:
                return False, "Invalid credentials", None
            
            user_id, db_username, email, stored_hash, salt, is_active, failed_attempts, locked_until = user_data
            
            # Check if account is locked
            if locked_until:
                lock_time = datetime.fromisoformat(locked_until)
                if datetime.now() < lock_time:
                    return False, "Account temporarily locked", None
            
            # Check if account is active
            if not is_active:
                return False, "Account disabled", None
            
            # Verify password
            password_hash, _ = self.hash_password(password, salt)
            if password_hash != stored_hash:
                # Increment failed attempts
                failed_attempts += 1
                lock_until = None
                
                if failed_attempts >= 5:
                    lock_until = datetime.now() + timedelta(minutes=30)
                    cursor.execute('''
                        UPDATE users SET failed_login_attempts = ?, locked_until = ?
                        WHERE id = ?
                    ''', (failed_attempts, lock_until.isoformat(), user_id))
                else:
                    cursor.execute('''
                        UPDATE users SET failed_login_attempts = ?
                        WHERE id = ?
                    ''', (failed_attempts, user_id))
                
                conn.commit()
                conn.close()
                return False, "Invalid credentials", None
            
            # Reset failed attempts and create session
            session_token = secrets.token_urlsafe(32)
            expires_at = datetime.now() + timedelta(hours=24)
            
            cursor.execute('''
                INSERT INTO user_sessions (user_id, session_token, expires_at, ip_address, user_agent)
                VALUES (?, ?, ?, ?, ?)
            ''', (user_id, session_token, expires_at.isoformat(), ip_address, user_agent))
            
            cursor.execute('''
                UPDATE users SET failed_login_attempts = 0, locked_until = NULL, last_login = CURRENT_TIMESTAMP
                WHERE id = ?
            ''', (user_id,))
            
            conn.commit()
            conn.close()
            
            user_info = {
                'id': user_id,
                'username': db_username,
                'email': email,
                'session_token': session_token
            }
            
            logger.info(f"User authenticated: {db_username}")
            return True, "Login successful", user_info
            
        except Exception as e:
            logger.error(f"Authentication error: {e}")
            return False, "Authentication failed", None
    
    def validate_session(self, session_token):
        """Validate user session"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT u.id, u.username, u.email, u.is_admin, s.expires_at
                FROM users u
                JOIN user_sessions s ON u.id = s.user_id
                WHERE s.session_token = ? AND s.is_active = 1 AND u.is_active = 1
            ''', (session_token,))
            
            result = cursor.fetchone()
            if not result:
                conn.close()
                return False, None
            
            user_id, username, email, is_admin, expires_at = result
            
            # Check if session expired
            if datetime.now() > datetime.fromisoformat(expires_at):
                cursor.execute('UPDATE user_sessions SET is_active = 0 WHERE session_token = ?', 
                             (session_token,))
                conn.commit()
                conn.close()
                return False, None
            
            conn.close()
            
            user_info = {
                'id': user_id,
                'username': username,
                'email': email,
                'is_admin': is_admin
            }
            
            return True, user_info
            
        except Exception as e:
            logger.error(f"Session validation error: {e}")
            return False, None
    
    def logout_user(self, session_token):
        """Logout user by invalidating session"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('UPDATE user_sessions SET is_active = 0 WHERE session_token = ?', 
                         (session_token,))
            conn.commit()
            conn.close()
            
            logger.info("User logged out")
            return True
            
        except Exception as e:
            logger.error(f"Logout error: {e}")
            return False
    
    def change_password(self, user_id, old_password, new_password):
        """Change user password"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get current password hash
            cursor.execute('SELECT password_hash, salt FROM users WHERE id = ?', (user_id,))
            result = cursor.fetchone()
            if not result:
                conn.close()
                return False, "User not found"
            
            stored_hash, salt = result
            
            # Verify old password
            old_hash, _ = self.hash_password(old_password, salt)
            if old_hash != stored_hash:
                conn.close()
                return False, "Invalid current password"
            
            # Hash new password
            new_hash, new_salt = self.hash_password(new_password)
            
            # Update password
            cursor.execute('''
                UPDATE users SET password_hash = ?, salt = ?
                WHERE id = ?
            ''', (new_hash, new_salt, user_id))
            
            conn.commit()
            conn.close()
            
            logger.info(f"Password changed for user ID: {user_id}")
            return True, "Password changed successfully"
            
        except Exception as e:
            logger.error(f"Password change error: {e}")
            return False, str(e)
    
    def get_user_list(self):
        """Get list of all users (admin only)"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT id, username, email, created_at, last_login, is_active, is_admin
                FROM users ORDER BY created_at DESC
            ''')
            
            users = []
            for row in cursor.fetchall():
                users.append({
                    'id': row[0],
                    'username': row[1],
                    'email': row[2],
                    'created_at': row[3],
                    'last_login': row[4],
                    'is_active': bool(row[5]),
                    'is_admin': bool(row[6])
                })
            
            conn.close()
            return users
            
        except Exception as e:
            logger.error(f"Error getting user list: {e}")
            return []

    def update_user(self, user_id, username, email, is_admin=False, is_active=True):
        """Update user information"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Check if username or email already exists for other users
            cursor.execute('''
                SELECT id FROM users 
                WHERE (username = ? OR email = ?) AND id != ?
            ''', (username, email, user_id))
            
            if cursor.fetchone():
                conn.close()
                return False, "Username or email already exists"
            
            # Update user
            cursor.execute('''
                UPDATE users 
                SET username = ?, email = ?, is_admin = ?, is_active = ?
                WHERE id = ?
            ''', (username, email, is_admin, is_active, user_id))
            
            conn.commit()
            conn.close()
            logger.info(f"User {username} updated successfully")
            return True, "User updated successfully"
            
        except Exception as e:
            logger.error(f"Error updating user: {e}")
            return False, f"Error updating user: {str(e)}"
    
    def delete_user(self, user_id):
        """Delete a user"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get username for logging
            cursor.execute('SELECT username FROM users WHERE id = ?', (user_id,))
            result = cursor.fetchone()
            if not result:
                conn.close()
                return False, "User not found"
            
            username = result[0]
            
            # Delete user sessions first
            cursor.execute('DELETE FROM user_sessions WHERE user_id = ?', (user_id,))
            
            # Delete user
            cursor.execute('DELETE FROM users WHERE id = ?', (user_id,))
            
            conn.commit()
            conn.close()
            logger.info(f"User {username} deleted successfully")
            return True, "User deleted successfully"
            
        except Exception as e:
            logger.error(f"Error deleting user: {e}")
            return False, f"Error deleting user: {str(e)}"
    
    def set_user_active(self, user_id, is_active):
        """Set user active status"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get username for logging
            cursor.execute('SELECT username FROM users WHERE id = ?', (user_id,))
            result = cursor.fetchone()
            if not result:
                conn.close()
                return False, "User not found"
            
            username = result[0]
            
            # Update active status
            cursor.execute('UPDATE users SET is_active = ? WHERE id = ?', (is_active, user_id))
            
            # If deactivating, remove all sessions
            if not is_active:
                cursor.execute('DELETE FROM user_sessions WHERE user_id = ?', (user_id,))
            
            conn.commit()
            conn.close()
            status = "activated" if is_active else "deactivated"
            logger.info(f"User {username} {status} successfully")
            return True, f"User {status} successfully"
            
        except Exception as e:
            logger.error(f"Error updating user status: {e}")
            return False, f"Error updating user status: {str(e)}"

# Flask decorators for authentication
def login_required(f):
    """Decorator to require login for routes"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'session_token' not in session:
            flash('Please log in to access this page.', 'warning')
            return redirect(url_for('login'))
        
        user_manager = UserManager()
        is_valid, user_info = user_manager.validate_session(session['session_token'])
        
        if not is_valid:
            session.clear()
            flash('Your session has expired. Please log in again.', 'warning')
            return redirect(url_for('login'))
        
        # Add user info to request context
        request.current_user = user_info
        return f(*args, **kwargs)
    
    return decorated_function

def admin_required(f):
    """Decorator to require admin privileges"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'session_token' not in session:
            flash('Please log in to access this page.', 'warning')
            return redirect(url_for('login'))
        
        user_manager = UserManager()
        is_valid, user_info = user_manager.validate_session(session['session_token'])
        
        if not is_valid:
            session.clear()
            flash('Your session has expired. Please log in again.', 'warning')
            return redirect(url_for('login'))
        
        if not user_info.get('is_admin'):
            flash('Admin privileges required.', 'error')
            return redirect(url_for('index'))
        
        # Add user info to request context
        request.current_user = user_info
        return f(*args, **kwargs)
    
    return decorated_function

if __name__ == '__main__':
    # Test the user manager
    user_manager = UserManager()
    print("User management system initialized")
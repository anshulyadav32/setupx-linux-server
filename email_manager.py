"""
Email Management System
Supports Gmail and Outlook/Exchange integration for comprehensive email management
"""

import os
import json
import sqlite3
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
import imaplib
import smtplib
import email
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import base64
import requests
from requests.auth import HTTPBasicAuth

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EmailManager:
    """Core email management class supporting multiple providers"""
    
    def __init__(self, db_path: str = "data/emails.db"):
        self.db_path = db_path
        self.init_database()
        
    def init_database(self):
        """Initialize the email management database"""
        os.makedirs(os.path.dirname(self.db_path), exist_ok=True)
        
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Email accounts table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS email_accounts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email_address TEXT UNIQUE NOT NULL,
                    provider TEXT NOT NULL,
                    config TEXT NOT NULL,
                    is_active BOOLEAN DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Emails table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS emails (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    account_id INTEGER,
                    message_id TEXT,
                    subject TEXT,
                    sender TEXT,
                    recipients TEXT,
                    body_text TEXT,
                    body_html TEXT,
                    attachments TEXT,
                    folder TEXT DEFAULT 'INBOX',
                    is_read BOOLEAN DEFAULT 0,
                    is_starred BOOLEAN DEFAULT 0,
                    received_at TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (account_id) REFERENCES email_accounts (id)
                )
            ''')
            
            # Email folders table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS email_folders (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    account_id INTEGER,
                    folder_name TEXT NOT NULL,
                    folder_type TEXT DEFAULT 'custom',
                    message_count INTEGER DEFAULT 0,
                    FOREIGN KEY (account_id) REFERENCES email_accounts (id)
                )
            ''')
            
            conn.commit()
            logger.info("Email database initialized successfully")

class GmailManager:
    """Gmail API integration for email management"""
    
    def __init__(self, credentials_path: str = "config/gmail_credentials.json"):
        self.credentials_path = credentials_path
        self.access_token = None
        self.refresh_token = None
        
    def setup_oauth(self, client_id: str, client_secret: str, redirect_uri: str = "http://localhost:8080/oauth/callback"):
        """Setup OAuth2 for Gmail API access"""
        auth_url = f"https://accounts.google.com/o/oauth2/auth?client_id={client_id}&redirect_uri={redirect_uri}&scope=https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.send&response_type=code&access_type=offline"
        return auth_url
        
    def exchange_code_for_tokens(self, code: str, client_id: str, client_secret: str, redirect_uri: str):
        """Exchange authorization code for access and refresh tokens"""
        token_url = "https://oauth2.googleapis.com/token"
        data = {
            'code': code,
            'client_id': client_id,
            'client_secret': client_secret,
            'redirect_uri': redirect_uri,
            'grant_type': 'authorization_code'
        }
        
        response = requests.post(token_url, data=data)
        if response.status_code == 200:
            tokens = response.json()
            self.access_token = tokens.get('access_token')
            self.refresh_token = tokens.get('refresh_token')
            
            # Save credentials
            self._save_credentials(tokens)
            return True
        return False
        
    def _save_credentials(self, tokens: dict):
        """Save OAuth credentials to file"""
        os.makedirs(os.path.dirname(self.credentials_path), exist_ok=True)
        with open(self.credentials_path, 'w') as f:
            json.dump(tokens, f)
            
    def _load_credentials(self):
        """Load OAuth credentials from file"""
        try:
            with open(self.credentials_path, 'r') as f:
                tokens = json.load(f)
                self.access_token = tokens.get('access_token')
                self.refresh_token = tokens.get('refresh_token')
                return True
        except FileNotFoundError:
            return False
            
    def refresh_access_token(self, client_id: str, client_secret: str):
        """Refresh the access token using refresh token"""
        if not self.refresh_token:
            return False
            
        token_url = "https://oauth2.googleapis.com/token"
        data = {
            'refresh_token': self.refresh_token,
            'client_id': client_id,
            'client_secret': client_secret,
            'grant_type': 'refresh_token'
        }
        
        response = requests.post(token_url, data=data)
        if response.status_code == 200:
            tokens = response.json()
            self.access_token = tokens.get('access_token')
            self._save_credentials({**tokens, 'refresh_token': self.refresh_token})
            return True
        return False
        
    def get_messages(self, query: str = "", max_results: int = 10):
        """Get Gmail messages using Gmail API"""
        if not self.access_token:
            if not self._load_credentials():
                return []
                
        headers = {'Authorization': f'Bearer {self.access_token}'}
        url = f"https://gmail.googleapis.com/gmail/v1/users/me/messages"
        params = {'q': query, 'maxResults': max_results}
        
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json().get('messages', [])
        return []
        
    def get_message_details(self, message_id: str):
        """Get detailed information about a specific Gmail message"""
        if not self.access_token:
            return None
            
        headers = {'Authorization': f'Bearer {self.access_token}'}
        url = f"https://gmail.googleapis.com/gmail/v1/users/me/messages/{message_id}"
        
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.json()
        return None
        
    def send_message(self, to: str, subject: str, body: str, body_type: str = "text"):
        """Send email via Gmail API"""
        if not self.access_token:
            return False
            
        message = MIMEMultipart()
        message['to'] = to
        message['subject'] = subject
        
        if body_type == "html":
            message.attach(MIMEText(body, 'html'))
        else:
            message.attach(MIMEText(body, 'plain'))
            
        raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode()
        
        headers = {'Authorization': f'Bearer {self.access_token}'}
        url = "https://gmail.googleapis.com/gmail/v1/users/me/messages/send"
        data = {'raw': raw_message}
        
        response = requests.post(url, headers=headers, json=data)
        return response.status_code == 200

class OutlookManager:
    """Outlook/Exchange integration for email management"""
    
    def __init__(self, credentials_path: str = "config/outlook_credentials.json"):
        self.credentials_path = credentials_path
        self.access_token = None
        self.refresh_token = None
        
    def setup_oauth(self, client_id: str, redirect_uri: str = "http://localhost:8080/oauth/callback"):
        """Setup OAuth2 for Outlook API access"""
        auth_url = f"https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id={client_id}&response_type=code&redirect_uri={redirect_uri}&scope=https://graph.microsoft.com/Mail.ReadWrite https://graph.microsoft.com/Mail.Send&response_mode=query"
        return auth_url
        
    def exchange_code_for_tokens(self, code: str, client_id: str, client_secret: str, redirect_uri: str):
        """Exchange authorization code for access and refresh tokens"""
        token_url = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
        data = {
            'code': code,
            'client_id': client_id,
            'client_secret': client_secret,
            'redirect_uri': redirect_uri,
            'grant_type': 'authorization_code'
        }
        
        response = requests.post(token_url, data=data)
        if response.status_code == 200:
            tokens = response.json()
            self.access_token = tokens.get('access_token')
            self.refresh_token = tokens.get('refresh_token')
            
            # Save credentials
            self._save_credentials(tokens)
            return True
        return False
        
    def _save_credentials(self, tokens: dict):
        """Save OAuth credentials to file"""
        os.makedirs(os.path.dirname(self.credentials_path), exist_ok=True)
        with open(self.credentials_path, 'w') as f:
            json.dump(tokens, f)
            
    def _load_credentials(self):
        """Load OAuth credentials from file"""
        try:
            with open(self.credentials_path, 'r') as f:
                tokens = json.load(f)
                self.access_token = tokens.get('access_token')
                self.refresh_token = tokens.get('refresh_token')
                return True
        except FileNotFoundError:
            return False
            
    def get_messages(self, folder: str = "inbox", max_results: int = 10):
        """Get Outlook messages using Microsoft Graph API"""
        if not self.access_token:
            if not self._load_credentials():
                return []
                
        headers = {'Authorization': f'Bearer {self.access_token}'}
        url = f"https://graph.microsoft.com/v1.0/me/mailFolders/{folder}/messages"
        params = {'$top': max_results, '$orderby': 'receivedDateTime desc'}
        
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json().get('value', [])
        return []
        
    def send_message(self, to: str, subject: str, body: str, body_type: str = "text"):
        """Send email via Microsoft Graph API"""
        if not self.access_token:
            return False
            
        headers = {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }
        
        message_data = {
            "message": {
                "subject": subject,
                "body": {
                    "contentType": "HTML" if body_type == "html" else "Text",
                    "content": body
                },
                "toRecipients": [
                    {
                        "emailAddress": {
                            "address": to
                        }
                    }
                ]
            }
        }
        
        url = "https://graph.microsoft.com/v1.0/me/sendMail"
        response = requests.post(url, headers=headers, json=message_data)
        return response.status_code == 202

class EmailAccountManager:
    """Manage multiple email accounts and their configurations"""
    
    def __init__(self, email_manager: EmailManager):
        self.email_manager = email_manager
        self.gmail_manager = GmailManager()
        self.outlook_manager = OutlookManager()
        
    def add_account(self, name: str, email_address: str, provider: str, config: dict):
        """Add a new email account"""
        with sqlite3.connect(self.email_manager.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO email_accounts (name, email_address, provider, config)
                VALUES (?, ?, ?, ?)
            ''', (name, email_address, provider, json.dumps(config)))
            conn.commit()
            return cursor.lastrowid
            
    def get_accounts(self):
        """Get all email accounts"""
        with sqlite3.connect(self.email_manager.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM email_accounts WHERE is_active = 1')
            accounts = []
            for row in cursor.fetchall():
                account = {
                    'id': row[0],
                    'name': row[1],
                    'email_address': row[2],
                    'provider': row[3],
                    'config': json.loads(row[4]),
                    'is_active': row[5],
                    'created_at': row[6],
                    'updated_at': row[7]
                }
                accounts.append(account)
            return accounts
            
    def sync_account_emails(self, account_id: int):
        """Sync emails for a specific account"""
        account = self.get_account_by_id(account_id)
        if not account:
            return False
            
        if account['provider'] == 'gmail':
            return self._sync_gmail_emails(account)
        elif account['provider'] == 'outlook':
            return self._sync_outlook_emails(account)
        return False
        
    def _sync_gmail_emails(self, account: dict):
        """Sync Gmail emails"""
        messages = self.gmail_manager.get_messages(max_results=50)
        
        with sqlite3.connect(self.email_manager.db_path) as conn:
            cursor = conn.cursor()
            
            for msg in messages:
                details = self.gmail_manager.get_message_details(msg['id'])
                if details:
                    # Extract email details and save to database
                    self._save_email_to_db(cursor, account['id'], details, 'gmail')
            
            conn.commit()
        return True
        
    def _sync_outlook_emails(self, account: dict):
        """Sync Outlook emails"""
        messages = self.outlook_manager.get_messages(max_results=50)
        
        with sqlite3.connect(self.email_manager.db_path) as conn:
            cursor = conn.cursor()
            
            for msg in messages:
                # Save Outlook message to database
                self._save_email_to_db(cursor, account['id'], msg, 'outlook')
            
            conn.commit()
        return True
        
    def _save_email_to_db(self, cursor, account_id: int, email_data: dict, provider: str):
        """Save email data to database"""
        # Implementation depends on email data structure from each provider
        # This is a simplified version
        try:
            if provider == 'gmail':
                # Parse Gmail message format
                headers = {h['name']: h['value'] for h in email_data.get('payload', {}).get('headers', [])}
                subject = headers.get('Subject', '')
                sender = headers.get('From', '')
                message_id = email_data.get('id', '')
            else:  # outlook
                subject = email_data.get('subject', '')
                sender = email_data.get('from', {}).get('emailAddress', {}).get('address', '')
                message_id = email_data.get('id', '')
                
            cursor.execute('''
                INSERT OR IGNORE INTO emails 
                (account_id, message_id, subject, sender, received_at)
                VALUES (?, ?, ?, ?, ?)
            ''', (account_id, message_id, subject, sender, datetime.now()))
            
        except Exception as e:
            logger.error(f"Error saving email to database: {e}")
            
    def get_account_by_id(self, account_id: int):
        """Get account by ID"""
        with sqlite3.connect(self.email_manager.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM email_accounts WHERE id = ?', (account_id,))
            row = cursor.fetchone()
            if row:
                return {
                    'id': row[0],
                    'name': row[1],
                    'email_address': row[2],
                    'provider': row[3],
                    'config': json.loads(row[4]),
                    'is_active': row[5],
                    'created_at': row[6],
                    'updated_at': row[7]
                }
        return None
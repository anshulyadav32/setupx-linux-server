#!/usr/bin/env python3
"""
Web Interface for SMTP Server and Client
A Flask-based web interface for managing emails.
"""

from flask import Flask, render_template, request, jsonify, redirect, url_for, flash, session
from flask_session import Session
import os
import email
import glob
from datetime import datetime, timedelta
import threading
import time
from pathlib import Path
import json
import secrets

# Import our SMTP modules
from smtp_client import SMTPClient
# Import authentication system
from user_manager import UserManager, login_required, admin_required
# Import domain management
from domain_manager import DomainManager
# Import email management
from email_manager import EmailManager

app = Flask(__name__)

# Enhanced security configuration
app.secret_key = secrets.token_hex(32)  # Generate secure random key
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_FILE_DIR'] = 'data/sessions'
app.config['SESSION_PERMANENT'] = False
app.config['SESSION_USE_SIGNER'] = True
app.config['SESSION_KEY_PREFIX'] = 'smtp_web:'
app.config['SESSION_COOKIE_SECURE'] = False  # Set to True in production with HTTPS
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(hours=24)

# Initialize Flask-Session
Session(app)

# Configuration
MAIL_DIR = 'received_emails'
SMTP_SERVER = 'localhost'
SMTP_PORT = 1025

# Initialize user manager
user_manager = UserManager()

# Initialize domain manager
domain_manager = DomainManager()

# Initialize email manager
email_manager = EmailManager()

def ensure_mail_dir():
    """Ensure the mail directory exists"""
    if not os.path.exists(MAIL_DIR):
        os.makedirs(MAIL_DIR)

def ensure_data_dirs():
    """Ensure all data directories exist"""
    ensure_mail_dir()
    # Ensure session directory exists
    os.makedirs('data/sessions', exist_ok=True)
    # Ensure user database directory exists
    os.makedirs('data', exist_ok=True)

def get_email_files():
    """Get list of email files sorted by modification time (newest first)"""
    ensure_mail_dir()
    email_files = glob.glob(os.path.join(MAIL_DIR, '*.eml'))
    email_files.sort(key=os.path.getmtime, reverse=True)
    return email_files

def parse_email_file(filepath):
    """Parse an email file and return email details"""
    try:
        with open(filepath, 'rb') as f:
            msg = email.message_from_bytes(f.read())
        
        # Extract email details
        email_data = {
            'filename': os.path.basename(filepath),
            'filepath': filepath,
            'subject': msg.get('Subject', 'No Subject'),
            'from': msg.get('From', 'Unknown Sender'),
            'to': msg.get('To', 'Unknown Recipient'),
            'date': msg.get('Date', 'Unknown Date'),
            'modified': datetime.fromtimestamp(os.path.getmtime(filepath)).strftime('%Y-%m-%d %H:%M:%S'),
            'size': os.path.getsize(filepath)
        }
        
        # Get email body
        body = ""
        html_body = ""
        
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                if content_type == "text/plain":
                    body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
                elif content_type == "text/html":
                    html_body = part.get_payload(decode=True).decode('utf-8', errors='ignore')
        else:
            body = msg.get_payload(decode=True).decode('utf-8', errors='ignore')
        
        email_data['body'] = body
        email_data['html_body'] = html_body
        
        return email_data
        
    except Exception as e:
        return {
            'filename': os.path.basename(filepath),
            'error': str(e),
            'subject': 'Error parsing email',
            'from': 'Unknown',
            'to': 'Unknown',
            'date': 'Unknown',
            'modified': 'Unknown',
            'size': 0,
            'body': f'Error parsing email: {e}'
        }

# Authentication Routes
@app.route('/login', methods=['GET', 'POST'])
def login():
    """User login"""
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        
        if not username or not password:
            flash('Username and password are required', 'error')
            return render_template('login.html')
        
        # Get client info
        ip_address = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR'))
        user_agent = request.headers.get('User-Agent')
        
        success, message, user_info = user_manager.authenticate_user(
            username, password, ip_address, user_agent
        )
        
        if success:
            session['session_token'] = user_info['session_token']
            session['user_id'] = user_info['id']
            session['username'] = user_info['username']
            flash(f'Welcome back, {user_info["username"]}!', 'success')
            return redirect(url_for('index'))
        else:
            flash(message, 'error')
    
    return render_template('login.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    """User registration"""
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')
        
        # Validation
        if not all([username, email, password, confirm_password]):
            flash('All fields are required', 'error')
            return render_template('register.html')
        
        if password != confirm_password:
            flash('Passwords do not match', 'error')
            return render_template('register.html')
        
        if len(password) < 6:
            flash('Password must be at least 6 characters long', 'error')
            return render_template('register.html')
        
        success, message = user_manager.create_user(username, email, password)
        
        if success:
            flash('Registration successful! Please log in.', 'success')
            return redirect(url_for('login'))
        else:
            flash(message, 'error')
    
    return render_template('register.html')

@app.route('/logout')
@login_required
def logout():
    """User logout"""
    if 'session_token' in session:
        user_manager.logout_user(session['session_token'])
    
    session.clear()
    flash('You have been logged out successfully', 'info')
    return redirect(url_for('login'))

@app.route('/profile')
@login_required
def profile():
    """User profile page"""
    return render_template('profile.html', current_user=request.current_user)

@app.route('/change_password', methods=['POST'])
@login_required
def change_password():
    """Change user password"""
    old_password = request.form.get('old_password')
    new_password = request.form.get('new_password')
    confirm_password = request.form.get('confirm_password')
    
    if not all([old_password, new_password, confirm_password]):
        flash('All password fields are required', 'error')
        return redirect(url_for('profile'))
    
    if new_password != confirm_password:
        flash('New passwords do not match', 'error')
        return redirect(url_for('profile'))
    
    if len(new_password) < 6:
        flash('Password must be at least 6 characters long', 'error')
        return redirect(url_for('profile'))
    
    success, message = user_manager.change_password(
        request.current_user['id'], old_password, new_password
    )
    
    if success:
        flash('Password changed successfully', 'success')
    else:
        flash(message, 'error')
    
    return redirect(url_for('profile'))

@app.route('/admin/users', methods=['GET', 'POST'])
@admin_required
def admin_users():
    """Admin user management"""
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'add':
            username = request.form.get('username')
            email = request.form.get('email')
            password = request.form.get('password')
            is_admin = 'is_admin' in request.form
            
            success, message = user_manager.create_user(username, email, password, is_admin)
            if success:
                flash(f'User "{username}" created successfully.', 'success')
            else:
                flash(message, 'error')
        
        elif action == 'edit':
            user_id = request.form.get('user_id')
            username = request.form.get('username')
            email = request.form.get('email')
            is_admin = 'is_admin' in request.form
            is_active = 'is_active' in request.form
            
            success, message = user_manager.update_user(user_id, username, email, is_admin, is_active)
            if success:
                flash(f'User "{username}" updated successfully.', 'success')
            else:
                flash(message, 'error')
        
        elif action == 'delete':
            user_id = request.form.get('user_id')
            success, message = user_manager.delete_user(user_id)
            if success:
                flash('User deleted successfully.', 'success')
            else:
                flash(message, 'error')
        
        elif action in ['activate', 'deactivate']:
            user_id = request.form.get('user_id')
            is_active = action == 'activate'
            success, message = user_manager.set_user_active(user_id, is_active)
            if success:
                status = 'activated' if is_active else 'deactivated'
                flash(f'User {status} successfully.', 'success')
            else:
                flash(message, 'error')
        
        return redirect(url_for('admin_users'))
    
    users = user_manager.get_user_list()
    return render_template('admin_users.html', users=users, current_user=request.current_user)

@app.route('/')
@login_required
def index():
    """Main dashboard"""
    email_files = get_email_files()
    email_count = len(email_files)
    
    # Get recent emails for preview
    recent_emails = []
    for filepath in email_files[:10]:  # Show last 10 emails
        email_data = parse_email_file(filepath)
        recent_emails.append(email_data)
    
    return render_template('index.html', 
                         email_count=email_count, 
                         recent_emails=recent_emails,
                         current_user=request.current_user)

@app.route('/emails')
@login_required
def list_emails():
    """List all received emails"""
    email_files = get_email_files()
    emails = []
    
    for filepath in email_files:
        email_data = parse_email_file(filepath)
        emails.append(email_data)
    
    return render_template('emails.html', emails=emails, current_user=request.current_user)

@app.route('/email/<filename>')
@login_required
def view_email(filename):
    """View a specific email"""
    filepath = os.path.join(MAIL_DIR, filename)
    
    if not os.path.exists(filepath):
        flash('Email not found', 'error')
        return redirect(url_for('list_emails'))
    
    email_data = parse_email_file(filepath)
    return render_template('view_email.html', email=email_data, current_user=request.current_user)

@app.route('/compose')
@login_required
def compose():
    """Show email composition form"""
    return render_template('compose.html', current_user=request.current_user)

@app.route('/send_email', methods=['POST'])
@login_required
def send_email():
    """Send an email via the web interface"""
    try:
        # Get form data
        to_addr = request.form.get('to')
        subject = request.form.get('subject')
        body = request.form.get('body')
        from_addr = request.form.get('from', 'webmail@localhost')
        
        # Validate required fields
        if not to_addr or not subject:
            flash('To address and subject are required', 'error')
            return redirect(url_for('compose'))
        
        # Create SMTP client and send email
        client = SMTPClient(SMTP_SERVER, SMTP_PORT, use_tls=False, use_ssl=False)
        
        if client.connect():
            success = client.send_email(from_addr, to_addr, subject, body or "")
            client.disconnect()
            
            if success:
                flash(f'Email sent successfully to {to_addr}', 'success')
                return redirect(url_for('index'))
            else:
                flash('Failed to send email', 'error')
        else:
            flash('Could not connect to SMTP server', 'error')
    
    except Exception as e:
        flash(f'Error sending email: {e}', 'error')
    
    return redirect(url_for('compose'))

@app.route('/api/emails')
@login_required
def api_emails():
    """API endpoint to get emails as JSON"""
    email_files = get_email_files()
    emails = []
    
    for filepath in email_files:
        email_data = parse_email_file(filepath)
        # Remove body content for API response to keep it lightweight
        api_data = {k: v for k, v in email_data.items() if k not in ['body', 'html_body']}
        emails.append(api_data)
    
    return jsonify(emails)

@app.route('/api/email/<filename>')
@login_required
def api_email_detail(filename):
    """API endpoint to get specific email details"""
    filepath = os.path.join(MAIL_DIR, filename)
    
    if not os.path.exists(filepath):
        return jsonify({'error': 'Email not found'}), 404
    
    email_data = parse_email_file(filepath)
    return jsonify(email_data)

@app.route('/delete_email/<filename>', methods=['POST'])
@login_required
def delete_email(filename):
    """Delete an email file"""
    filepath = os.path.join(MAIL_DIR, filename)
    
    try:
        if os.path.exists(filepath):
            os.remove(filepath)
            flash(f'Email {filename} deleted successfully', 'success')
        else:
            flash('Email not found', 'error')
    except Exception as e:
        flash(f'Error deleting email: {e}', 'error')
    
    return redirect(url_for('list_emails'))

@app.route('/settings')
@login_required
def settings():
    """Settings page"""
    return render_template('settings.html', 
                         smtp_server=SMTP_SERVER, 
                         smtp_port=SMTP_PORT,
                         mail_dir=MAIL_DIR,
                         current_user=request.current_user)

@app.route('/admin/domains', methods=['GET', 'POST'])
@admin_required
def admin_domains():
    """Admin domain management"""
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'add':
            domain_name = request.form.get('domain_name', '').strip()
            description = request.form.get('description', '').strip()
            is_local = 'is_local' in request.form
            
            # Relay configuration
            relay_config = None
            if not is_local:
                relay_config = {
                    'host': request.form.get('relay_host', '').strip(),
                    'port': int(request.form.get('relay_port', 587)),
                    'username': request.form.get('relay_username', '').strip(),
                    'password': request.form.get('relay_password', '').strip(),
                    'use_tls': 'use_tls' in request.form,
                    'use_ssl': 'use_ssl' in request.form
                }
            
            success, message = domain_manager.add_domain(domain_name, description, is_local, relay_config)
            if success:
                flash(f'Domain "{domain_name}" added successfully.', 'success')
            else:
                flash(message, 'error')
        
        elif action == 'edit':
            domain_id = int(request.form.get('domain_id'))
            domain_name = request.form.get('domain_name', '').strip()
            description = request.form.get('description', '').strip()
            is_active = 'is_active' in request.form
            is_local = 'is_local' in request.form
            
            # Relay configuration
            relay_config = None
            if not is_local:
                relay_config = {
                    'host': request.form.get('relay_host', '').strip(),
                    'port': int(request.form.get('relay_port', 587)),
                    'username': request.form.get('relay_username', '').strip(),
                    'password': request.form.get('relay_password', '').strip(),
                    'use_tls': 'use_tls' in request.form,
                    'use_ssl': 'use_ssl' in request.form
                }
            
            success, message = domain_manager.update_domain(domain_id, domain_name, description, is_active, is_local, relay_config)
            if success:
                flash(f'Domain "{domain_name}" updated successfully.', 'success')
            else:
                flash(message, 'error')
        
        elif action == 'delete':
            domain_id = int(request.form.get('domain_id'))
            success, message = domain_manager.delete_domain(domain_id)
            if success:
                flash('Domain deleted successfully.', 'success')
            else:
                flash(message, 'error')
        
        elif action in ['activate', 'deactivate']:
            domain_id = int(request.form.get('domain_id'))
            domain = domain_manager.get_domain(domain_id)
            if domain:
                is_active = action == 'activate'
                success, message = domain_manager.update_domain(
                    domain_id, domain['domain_name'], domain['description'],
                    is_active, domain['is_local']
                )
                if success:
                    status = 'activated' if is_active else 'deactivated'
                    flash(f'Domain {status} successfully.', 'success')
                else:
                    flash(message, 'error')
            else:
                flash('Domain not found.', 'error')
        
        return redirect(url_for('admin_domains'))
    
    # GET request - show domains
    domains = domain_manager.get_domains()
    return render_template('admin_domains.html', domains=domains, current_user=request.current_user)

@app.route('/api/domain/<domain_name>/dns-status', methods=['GET'])
@admin_required
def get_domain_dns_status(domain_name):
    """Get DNS status for a specific domain"""
    try:
        status = domain_manager.check_domain_dns_status(domain_name)
        return jsonify(status)
    except Exception as e:
        return jsonify({
            'error': str(e),
            'domain': domain_name,
            'overall_status': 'error'
        }), 500

# Email Management Routes
@app.route('/email_accounts')
@login_required
def email_accounts():
    """Email accounts management page"""
    try:
        accounts = email_manager.get_email_accounts(session['user_id'])
        return render_template('email_accounts.html', accounts=accounts)
    except Exception as e:
        flash(f'Error loading email accounts: {str(e)}', 'error')
        return redirect(url_for('index'))

@app.route('/email_inbox')
@login_required
def email_inbox():
    """Email inbox page"""
    try:
        account_id = request.args.get('account_id')
        if not account_id:
            flash('Please select an email account', 'warning')
            return redirect(url_for('email_accounts'))
        
        emails = email_manager.get_emails(account_id)
        account = email_manager.get_account_by_id(account_id)
        return render_template('email_inbox.html', emails=emails, account=account)
    except Exception as e:
        flash(f'Error loading inbox: {str(e)}', 'error')
        return redirect(url_for('email_accounts'))

@app.route('/email_compose')
@login_required
def email_compose():
    """Email compose page"""
    try:
        accounts = email_manager.get_email_accounts(session['user_id'])
        return render_template('email_compose.html', accounts=accounts)
    except Exception as e:
        flash(f'Error loading compose page: {str(e)}', 'error')
        return redirect(url_for('email_accounts'))

@app.route('/email_drafts')
@login_required
def email_drafts():
    """Email drafts page"""
    try:
        account_id = request.args.get('account_id')
        if not account_id:
            # Get all accounts for user and show drafts from all
            accounts = email_manager.get_email_accounts(session['user_id'])
            drafts = []
            for account in accounts:
                account_drafts = email_manager.get_drafts(account['id'])
                drafts.extend(account_drafts)
        else:
            drafts = email_manager.get_drafts(account_id)
            accounts = [email_manager.get_account_by_id(account_id)]
        
        return render_template('email_drafts.html', drafts=drafts, accounts=accounts)
    except Exception as e:
        flash(f'Error loading drafts: {str(e)}', 'error')
        return redirect(url_for('email_accounts'))

@app.route('/email_sent')
@login_required
def email_sent():
    """Email sent page"""
    try:
        account_id = request.args.get('account_id')
        if not account_id:
            # Get all accounts for user and show sent emails from all
            accounts = email_manager.get_email_accounts(session['user_id'])
            sent_emails = []
            for account in accounts:
                account_sent = email_manager.get_sent_emails(account['id'])
                sent_emails.extend(account_sent)
        else:
            sent_emails = email_manager.get_sent_emails(account_id)
            accounts = [email_manager.get_account_by_id(account_id)]
        
        return render_template('email_sent.html', sent_emails=sent_emails, accounts=accounts)
    except Exception as e:
        flash(f'Error loading sent emails: {str(e)}', 'error')
        return redirect(url_for('email_accounts'))

@app.route('/email_trash')
@login_required
def email_trash():
    """Email trash page"""
    try:
        account_id = request.args.get('account_id')
        if not account_id:
            # Get all accounts for user and show trash from all
            accounts = email_manager.get_email_accounts(session['user_id'])
            trash_emails = []
            for account in accounts:
                account_trash = email_manager.get_trash_emails(account['id'])
                trash_emails.extend(account_trash)
        else:
            trash_emails = email_manager.get_trash_emails(account_id)
            accounts = [email_manager.get_account_by_id(account_id)]
        
        return render_template('email_trash.html', trash_emails=trash_emails, accounts=accounts)
    except Exception as e:
        flash(f'Error loading trash: {str(e)}', 'error')
        return redirect(url_for('email_accounts'))

# OAuth Routes
@app.route('/oauth/<provider>/authorize')
@login_required
def oauth_authorize(provider):
    """Start OAuth authorization flow"""
    try:
        email = request.args.get('email')
        if not email:
            return "Email parameter is required", 400
        
        if provider == 'gmail':
            from gmail_integration import GmailIntegration
            gmail = GmailIntegration()
            auth_url = gmail.get_authorization_url()
            # Store email in session for callback
            session[f'oauth_{provider}_email'] = email
            return redirect(auth_url)
        elif provider == 'outlook':
            from outlook_integration import OutlookIntegration
            outlook = OutlookIntegration()
            auth_url = outlook.get_authorization_url()
            # Store email in session for callback
            session[f'oauth_{provider}_email'] = email
            return redirect(auth_url)
        else:
            return "Unsupported provider", 400
    except Exception as e:
        return f"Error starting OAuth: {str(e)}", 500

@app.route('/oauth/<provider>/callback')
@login_required
def oauth_callback(provider):
    """Handle OAuth callback"""
    try:
        code = request.args.get('code')
        error = request.args.get('error')
        
        if error:
            return f"OAuth error: {error}", 400
        
        if not code:
            return "Authorization code not received", 400
        
        email = session.get(f'oauth_{provider}_email')
        if not email:
            return "Email not found in session", 400
        
        # Complete OAuth and add account
        success = email_manager.complete_oauth_flow(provider, code, email, session['user_id'])
        
        if success:
            # Close popup and refresh parent
            return '''
            <script>
                window.opener.location.reload();
                window.close();
            </script>
            '''
        else:
            return "Failed to complete OAuth flow", 500
            
    except Exception as e:
        return f"Error in OAuth callback: {str(e)}", 500

@app.route('/api/email/accounts', methods=['GET'])
@login_required
def api_get_email_accounts():
    """Get user's email accounts"""
    try:
        accounts = email_manager.get_email_accounts(session['user_id'])
        return jsonify({'success': True, 'accounts': accounts})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/accounts', methods=['POST'])
@login_required
def api_add_email_account():
    """Add new email account"""
    try:
        data = request.get_json()
        provider = data.get('provider')
        email_address = data.get('email')
        
        if not provider or not email_address:
            return jsonify({'success': False, 'error': 'Provider and email are required'}), 400
        
        # Start OAuth flow
        auth_url = email_manager.start_oauth_flow(provider, email_address, session['user_id'])
        return jsonify({'success': True, 'auth_url': auth_url})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/oauth/callback/<provider>')
@login_required
def api_oauth_callback(provider):
    """Handle OAuth callback"""
    try:
        code = request.args.get('code')
        state = request.args.get('state')
        
        if not code:
            return jsonify({'success': False, 'error': 'Authorization code not received'}), 400
        
        # Complete OAuth flow
        account = email_manager.complete_oauth_flow(provider, code, state, session['user_id'])
        return jsonify({'success': True, 'account': account})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/accounts/<account_id>/sync', methods=['POST'])
@login_required
def api_sync_email_account(account_id):
    """Sync email account"""
    try:
        result = email_manager.sync_account(account_id, session['user_id'])
        return jsonify({'success': True, 'result': result})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/accounts/<account_id>', methods=['DELETE'])
@login_required
def api_delete_email_account(account_id):
    """Delete email account"""
    try:
        email_manager.delete_account(account_id, session['user_id'])
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/send', methods=['POST'])
@login_required
def api_send_email():
    """Send email"""
    try:
        data = request.get_json()
        account_id = data.get('account_id')
        to_addresses = data.get('to', [])
        cc_addresses = data.get('cc', [])
        bcc_addresses = data.get('bcc', [])
        subject = data.get('subject', '')
        body = data.get('body', '')
        attachments = data.get('attachments', [])
        
        if not account_id or not to_addresses:
            return jsonify({'success': False, 'error': 'Account ID and recipients are required'}), 400
        
        result = email_manager.send_email(
            account_id=account_id,
            to_addresses=to_addresses,
            cc_addresses=cc_addresses,
            bcc_addresses=bcc_addresses,
            subject=subject,
            body=body,
            attachments=attachments,
            user_id=session['user_id']
        )
        
        return jsonify({'success': True, 'message_id': result})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/<account_id>/messages', methods=['GET'])
@login_required
def api_get_email_messages(account_id):
    """Get email messages for account"""
    try:
        page = int(request.args.get('page', 1))
        per_page = int(request.args.get('per_page', 50))
        folder = request.args.get('folder', 'INBOX')
        
        messages = email_manager.get_messages(
            account_id=account_id,
            folder=folder,
            page=page,
            per_page=per_page,
            user_id=session['user_id']
        )
        
        return jsonify({'success': True, 'messages': messages})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/messages/<message_id>/read', methods=['POST'])
@login_required
def api_mark_email_read(message_id):
    """Mark email as read"""
    try:
        email_manager.mark_as_read(message_id, session['user_id'])
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/email/messages/<message_id>', methods=['DELETE'])
@login_required
def api_delete_email_message(message_id):
    """Delete email message"""
    try:
        email_manager.delete_message(message_id, session['user_id'])
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/domains/dns-status', methods=['GET'])
@admin_required
def get_all_domains_dns_status():
    """Get DNS status for all domains"""
    try:
        domains = domain_manager.get_domains()
        results = []
        
        for domain in domains:
            status = domain_manager.check_domain_dns_status(domain['name'])
            results.append(status)
        
        return jsonify({
            'domains': results,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

def main():
    """Main function to start the web interface"""
    print("SMTP Web Interface with Authentication")
    print("=" * 40)
    print(f"Mail directory: {MAIL_DIR}")
    print(f"SMTP Server: {SMTP_SERVER}:{SMTP_PORT}")
    print("Starting web server on http://localhost:5000")
    print("Default admin login: admin / admin123")
    print("Press Ctrl+C to stop")
    
    ensure_data_dirs()
    
    try:
        app.run(host='0.0.0.0', port=5000, debug=True)
    except KeyboardInterrupt:
        print("\nWeb interface stopped")

if __name__ == '__main__':
    main()
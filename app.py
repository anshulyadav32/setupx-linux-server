#!/usr/bin/env python3
"""
Vercel Entry Point for SMTP Web Interface
This file serves as the entry point for Vercel deployment.
"""

import os
import sys
from pathlib import Path

# Add the current directory to Python path
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

# Import the Flask app from web_interface
from web_interface import app

# Ensure data directories exist
def ensure_data_dirs():
    """Ensure required data directories exist"""
    dirs = ['data', 'data/sessions', 'received_emails', 'uploads', 'logs']
    for dir_name in dirs:
        os.makedirs(dir_name, exist_ok=True)

# Initialize for serverless environment
ensure_data_dirs()

# Configure for production
if os.environ.get('VERCEL'):
    app.config['SESSION_COOKIE_SECURE'] = True
    app.config['DEBUG'] = False

# Export the app for Vercel
application = app

if __name__ == '__main__':
    # For local testing
    app.run(host='0.0.0.0', port=5000, debug=False)
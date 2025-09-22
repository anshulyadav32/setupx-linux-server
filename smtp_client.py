#!/usr/bin/env python3
"""
SMTP Client Implementation
A simple SMTP client that can send emails to SMTP servers.
"""

import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
import os
import argparse
import getpass
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SMTPClient:
    """SMTP Client for sending emails"""
    
    def __init__(self, smtp_server, smtp_port, use_tls=True, use_ssl=False):
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.use_tls = use_tls
        self.use_ssl = use_ssl
        self.server = None
    
    def connect(self, username=None, password=None):
        """Connect to the SMTP server"""
        try:
            if self.use_ssl:
                # Create SSL context
                context = ssl.create_default_context()
                self.server = smtplib.SMTP_SSL(self.smtp_server, self.smtp_port, context=context)
            else:
                self.server = smtplib.SMTP(self.smtp_server, self.smtp_port)
                
                if self.use_tls:
                    # Enable TLS
                    self.server.starttls()
            
            # Login if credentials provided
            if username and password:
                self.server.login(username, password)
                logger.info(f"Logged in as {username}")
            
            logger.info(f"Connected to SMTP server {self.smtp_server}:{self.smtp_port}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to SMTP server: {e}")
            return False
    
    def send_email(self, from_addr, to_addrs, subject, body, attachments=None, html_body=None):
        """Send an email"""
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = from_addr
            msg['To'] = ', '.join(to_addrs) if isinstance(to_addrs, list) else to_addrs
            msg['Subject'] = subject
            msg['Date'] = datetime.now().strftime('%a, %d %b %Y %H:%M:%S %z')
            
            # Add text body
            if body:
                text_part = MIMEText(body, 'plain')
                msg.attach(text_part)
            
            # Add HTML body if provided
            if html_body:
                html_part = MIMEText(html_body, 'html')
                msg.attach(html_part)
            
            # Add attachments if provided
            if attachments:
                for attachment_path in attachments:
                    if os.path.isfile(attachment_path):
                        with open(attachment_path, 'rb') as attachment:
                            part = MIMEBase('application', 'octet-stream')
                            part.set_payload(attachment.read())
                        
                        encoders.encode_base64(part)
                        part.add_header(
                            'Content-Disposition',
                            f'attachment; filename= {os.path.basename(attachment_path)}'
                        )
                        msg.attach(part)
                        logger.info(f"Attached file: {attachment_path}")
            
            # Send email
            to_list = to_addrs if isinstance(to_addrs, list) else [to_addrs]
            self.server.send_message(msg, from_addr, to_list)
            
            logger.info(f"Email sent successfully to {to_list}")
            print(f"Email sent successfully!")
            print(f"From: {from_addr}")
            print(f"To: {', '.join(to_list)}")
            print(f"Subject: {subject}")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            print(f"Failed to send email: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from the SMTP server"""
        if self.server:
            self.server.quit()
            logger.info("Disconnected from SMTP server")

def send_test_email(smtp_server, smtp_port, from_addr, to_addr, subject, body, username=None, password=None):
    """Send a test email"""
    client = SMTPClient(smtp_server, smtp_port, use_tls=False, use_ssl=False)
    
    if client.connect(username, password):
        success = client.send_email(from_addr, to_addr, subject, body)
        client.disconnect()
        return success
    return False

def main():
    """Main function for command-line usage"""
    parser = argparse.ArgumentParser(description='SMTP Client for sending emails')
    parser.add_argument('--server', required=True, help='SMTP server address')
    parser.add_argument('--port', type=int, default=587, help='SMTP server port (default: 587)')
    parser.add_argument('--from', dest='from_addr', required=True, help='Sender email address')
    parser.add_argument('--to', dest='to_addr', required=True, help='Recipient email address')
    parser.add_argument('--subject', required=True, help='Email subject')
    parser.add_argument('--body', help='Email body text')
    parser.add_argument('--html-body', help='Email body in HTML format')
    parser.add_argument('--username', help='SMTP username for authentication')
    parser.add_argument('--password', help='SMTP password for authentication')
    parser.add_argument('--attachments', nargs='*', help='File paths to attach')
    parser.add_argument('--no-tls', action='store_true', help='Disable TLS')
    parser.add_argument('--ssl', action='store_true', help='Use SSL instead of TLS')
    
    args = parser.parse_args()
    
    # Get password if username provided but password not
    password = args.password
    if args.username and not password:
        password = getpass.getpass("Enter SMTP password: ")
    
    # Default body if none provided
    body = args.body or "This is a test email sent from SMTP Client."
    
    print(f"Sending email via {args.server}:{args.port}")
    print(f"From: {args.from_addr}")
    print(f"To: {args.to_addr}")
    print(f"Subject: {args.subject}")
    
    # Create client
    client = SMTPClient(
        args.server, 
        args.port, 
        use_tls=not args.no_tls and not args.ssl,
        use_ssl=args.ssl
    )
    
    try:
        if client.connect(args.username, password):
            success = client.send_email(
                args.from_addr,
                args.to_addr,
                args.subject,
                body,
                args.attachments,
                args.html_body
            )
            
            if success:
                print("\nEmail sent successfully!")
            else:
                print("\nFailed to send email.")
        else:
            print("Failed to connect to SMTP server.")
            
    finally:
        client.disconnect()

if __name__ == '__main__':
    main()
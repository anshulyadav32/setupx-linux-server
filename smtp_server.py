#!/usr/bin/env python3
"""
SMTP Server Implementation
A simple SMTP server that can receive emails and save them to files.
"""

import asyncio
import email
import os
from datetime import datetime
import argparse
import logging
from aiosmtpd.controller import Controller
from aiosmtpd.smtp import SMTP as SMTPProtocol

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class CustomSMTPHandler:
    """Custom SMTP Handler that saves received emails to files"""
    
    def __init__(self, mail_dir='received_emails'):
        self.mail_dir = mail_dir
        
        # Create mail directory if it doesn't exist
        if not os.path.exists(self.mail_dir):
            os.makedirs(self.mail_dir)
            logger.info(f"Created mail directory: {self.mail_dir}")
    
    async def handle_DATA(self, server, session, envelope):
        """Handle incoming email data"""
        try:
            # Get email data
            data = envelope.content
            mailfrom = envelope.mail_from
            rcpttos = envelope.rcpt_tos
            
            # Parse the email
            msg = email.message_from_bytes(data)
            
            # Generate filename with timestamp
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"email_{timestamp}_{hash(data) % 10000}.eml"
            filepath = os.path.join(self.mail_dir, filename)
            
            # Save email to file
            with open(filepath, 'wb') as f:
                f.write(data)
            
            # Log email details
            subject = msg.get('Subject', 'No Subject')
            from_addr = msg.get('From', mailfrom)
            to_addrs = ', '.join(rcpttos)
            
            logger.info(f"Email received and saved to {filename}")
            logger.info(f"From: {from_addr}")
            logger.info(f"To: {to_addrs}")
            logger.info(f"Subject: {subject}")
            
            print(f"\n=== New Email Received ===")
            print(f"File: {filename}")
            print(f"From: {from_addr}")
            print(f"To: {to_addrs}")
            print(f"Subject: {subject}")
            print(f"Size: {len(data)} bytes")
            print("=" * 30)
            
            return '250 Message accepted for delivery'
            
        except Exception as e:
            logger.error(f"Error processing email: {e}")
            print(f"Error processing email: {e}")
            return '550 Error processing message'

async def main():
    """Main function to start the SMTP server"""
    parser = argparse.ArgumentParser(description='Simple SMTP Server')
    parser.add_argument('--host', default='localhost', help='Host to bind to (default: localhost)')
    parser.add_argument('--port', type=int, default=1025, help='Port to bind to (default: 1025)')
    parser.add_argument('--mail-dir', default='received_emails', help='Directory to save emails (default: received_emails)')
    
    args = parser.parse_args()
    
    print(f"Starting SMTP Server on {args.host}:{args.port}")
    print(f"Emails will be saved to: {args.mail_dir}")
    print("Press Ctrl+C to stop the server\n")
    
    try:
        # Create SMTP handler
        handler = CustomSMTPHandler(args.mail_dir)
        
        # Create and start the SMTP controller
        controller = Controller(handler, hostname=args.host, port=args.port)
        controller.start()
        
        logger.info(f"SMTP Server started on {args.host}:{args.port}")
        print(f"SMTP Server is running on {args.host}:{args.port}")
        print("Press Ctrl+C to stop...")
        
        # Keep the server running
        try:
            while True:
                await asyncio.sleep(1)
        except KeyboardInterrupt:
            pass
        
    except KeyboardInterrupt:
        print("\nShutting down SMTP server...")
        logger.info("SMTP Server stopped")
    except Exception as e:
        print(f"Error starting server: {e}")
        logger.error(f"Error starting server: {e}")
    finally:
        if 'controller' in locals():
            controller.stop()

if __name__ == '__main__':
    asyncio.run(main())
#!/usr/bin/env python3
"""
Bulk Email Sending Example
Demonstrates how to send emails to multiple recipients efficiently.
"""

import sys
import csv
import time
from pathlib import Path

# Add parent directory to path to import our modules
sys.path.append(str(Path(__file__).parent.parent))

from smtp_client import SMTPClient

def create_sample_recipients():
    """Create a sample CSV file with recipient data"""
    recipients_file = 'sample_recipients.csv'
    
    sample_data = [
        ['name', 'email', 'company'],
        ['John Doe', 'john@example.com', 'Tech Corp'],
        ['Jane Smith', 'jane@example.com', 'Design Studio'],
        ['Bob Johnson', 'bob@example.com', 'Marketing Inc'],
        ['Alice Brown', 'alice@example.com', 'Development LLC'],
        ['Charlie Wilson', 'charlie@example.com', 'Consulting Group']
    ]
    
    with open(recipients_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(sample_data)
    
    print(f"Created sample recipients file: {recipients_file}")
    return recipients_file

def load_recipients(csv_file):
    """Load recipients from CSV file"""
    recipients = []
    
    try:
        with open(csv_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                recipients.append(row)
        
        print(f"Loaded {len(recipients)} recipients from {csv_file}")
        return recipients
        
    except FileNotFoundError:
        print(f"Error: File {csv_file} not found")
        return []
    except Exception as e:
        print(f"Error loading recipients: {e}")
        return []

def create_personalized_email(recipient, template):
    """Create personalized email content"""
    # Replace placeholders in template
    personalized = template
    for key, value in recipient.items():
        placeholder = f"{{{key}}}"
        personalized = personalized.replace(placeholder, value)
    
    return personalized

def send_bulk_emails(smtp_server, smtp_port, from_addr, recipients, subject_template, body_template, delay=1):
    """Send bulk emails to multiple recipients"""
    client = SMTPClient(smtp_server, smtp_port, use_tls=False, use_ssl=False)
    
    if not client.connect():
        print("Failed to connect to SMTP server")
        return False
    
    successful_sends = 0
    failed_sends = 0
    
    print(f"\nStarting bulk email send to {len(recipients)} recipients...")
    print("-" * 50)
    
    for i, recipient in enumerate(recipients, 1):
        try:
            # Create personalized content
            subject = create_personalized_email(recipient, subject_template)
            body = create_personalized_email(recipient, body_template)
            
            # Send email
            success = client.send_email(
                from_addr,
                recipient['email'],
                subject,
                body
            )
            
            if success:
                successful_sends += 1
                print(f"✓ [{i}/{len(recipients)}] Sent to {recipient['name']} ({recipient['email']})")
            else:
                failed_sends += 1
                print(f"✗ [{i}/{len(recipients)}] Failed to send to {recipient['name']} ({recipient['email']})")
            
            # Add delay between sends to avoid overwhelming the server
            if delay > 0 and i < len(recipients):
                time.sleep(delay)
                
        except Exception as e:
            failed_sends += 1
            print(f"✗ [{i}/{len(recipients)}] Error sending to {recipient['name']}: {e}")
    
    client.disconnect()
    
    print("-" * 50)
    print(f"Bulk email send completed:")
    print(f"  Successful: {successful_sends}")
    print(f"  Failed: {failed_sends}")
    print(f"  Total: {len(recipients)}")
    
    return successful_sends > 0

def main():
    """Main function for bulk email sending"""
    print("Bulk Email Sending Example")
    print("=" * 40)
    
    # Configuration
    smtp_server = 'localhost'
    smtp_port = 1025
    from_addr = 'newsletter@company.com'
    
    # Email templates with placeholders
    subject_template = "Welcome to our newsletter, {name}!"
    
    body_template = """
Dear {name},

Welcome to our monthly newsletter!

We're excited to have you from {company} as part of our community.
You'll receive updates about:

- Industry news and trends
- Product updates and features
- Exclusive offers and promotions
- Technical tips and best practices

If you have any questions, feel free to reply to this email.

Best regards,
The Newsletter Team

---
This email was sent to: {email}
To unsubscribe, reply with "UNSUBSCRIBE" in the subject line.
"""
    
    print(f"Configuration:")
    print(f"  SMTP Server: {smtp_server}:{smtp_port}")
    print(f"  From Address: {from_addr}")
    print(f"  Subject Template: {subject_template}")
    
    # Create sample recipients file if it doesn't exist
    recipients_file = 'sample_recipients.csv'
    if not Path(recipients_file).exists():
        print(f"\nCreating sample recipients file...")
        recipients_file = create_sample_recipients()
    
    # Load recipients
    print(f"\nLoading recipients from {recipients_file}...")
    recipients = load_recipients(recipients_file)
    
    if not recipients:
        print("No recipients loaded. Exiting.")
        return
    
    # Show preview
    print(f"\nPreview of first email:")
    print("-" * 30)
    sample_recipient = recipients[0]
    sample_subject = create_personalized_email(sample_recipient, subject_template)
    sample_body = create_personalized_email(sample_recipient, body_template)
    
    print(f"To: {sample_recipient['name']} <{sample_recipient['email']}>")
    print(f"Subject: {sample_subject}")
    print(f"Body (first 200 chars): {sample_body[:200]}...")
    
    # Confirm before sending
    print(f"\nReady to send {len(recipients)} emails.")
    print("Make sure the SMTP server is running: python smtp_server.py")
    
    try:
        confirm = input("\nProceed with bulk send? (y/N): ").lower().strip()
        if confirm != 'y':
            print("Bulk send cancelled.")
            return
        
        # Send bulk emails
        success = send_bulk_emails(
            smtp_server, smtp_port, from_addr,
            recipients, subject_template, body_template,
            delay=0.5  # 0.5 second delay between emails
        )
        
        if success:
            print("\n✓ Bulk email send completed successfully!")
            print("Check the 'received_emails' directory for the saved emails.")
        else:
            print("\n✗ Bulk email send failed.")
            
    except KeyboardInterrupt:
        print("\nBulk send cancelled by user.")
    except Exception as e:
        print(f"\nError during bulk send: {e}")

def send_newsletter_example():
    """Example of sending a newsletter with HTML content"""
    print("\n=== Newsletter Example ===")
    
    html_template = """
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .footer { background-color: #f4f4f4; padding: 10px; text-align: center; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Monthly Newsletter</h1>
        </div>
        <div class="content">
            <h2>Hello {name}!</h2>
            <p>We hope this newsletter finds you well at <strong>{company}</strong>.</p>
            
            <h3>This Month's Highlights:</h3>
            <ul>
                <li>🚀 New product features released</li>
                <li>📊 Industry report: Q4 trends</li>
                <li>🎉 Customer success stories</li>
                <li>💡 Tips for better productivity</li>
            </ul>
            
            <p>Thank you for being a valued subscriber!</p>
        </div>
        <div class="footer">
            <p>Sent to: {email} | <a href="#">Unsubscribe</a></p>
        </div>
    </body>
    </html>
    """
    
    # This would use the same bulk sending logic but with HTML content
    print("HTML newsletter template created.")
    print("To send HTML newsletters, modify the send_bulk_emails function")
    print("to use the html_body parameter in client.send_email()")

if __name__ == '__main__':
    main()
    send_newsletter_example()
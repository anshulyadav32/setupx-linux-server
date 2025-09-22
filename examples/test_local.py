#!/usr/bin/env python3
"""
Local Testing Example
Demonstrates how to test the SMTP server and client locally.
"""

import sys
import os
import time
import threading
import subprocess
from pathlib import Path

# Add parent directory to path to import our modules
sys.path.append(str(Path(__file__).parent.parent))

from smtp_client import SMTPClient, send_test_email

def test_local_smtp():
    """Test local SMTP server and client"""
    print("=== Local SMTP Testing ===")
    print("This script will test the SMTP server and client locally.\n")
    
    # Configuration
    smtp_host = 'localhost'
    smtp_port = 1025
    from_addr = 'test@example.com'
    to_addr = 'recipient@example.com'
    
    print(f"Testing configuration:")
    print(f"SMTP Server: {smtp_host}:{smtp_port}")
    print(f"From: {from_addr}")
    print(f"To: {to_addr}\n")
    
    # Test 1: Simple text email
    print("Test 1: Sending simple text email...")
    success = send_test_email(
        smtp_host, smtp_port,
        from_addr, to_addr,
        "Test Email #1",
        "This is a simple test email sent from the local testing script."
    )
    
    if success:
        print("✓ Test 1 passed\n")
    else:
        print("✗ Test 1 failed\n")
        return False
    
    time.sleep(1)
    
    # Test 2: Email with HTML content
    print("Test 2: Sending HTML email...")
    client = SMTPClient(smtp_host, smtp_port, use_tls=False, use_ssl=False)
    
    if client.connect():
        html_body = """
        <html>
        <body>
            <h1>HTML Test Email</h1>
            <p>This is a <b>test email</b> with <i>HTML formatting</i>.</p>
            <ul>
                <li>Feature 1: HTML support</li>
                <li>Feature 2: Rich formatting</li>
                <li>Feature 3: Multiple content types</li>
            </ul>
            <p>Best regards,<br>SMTP Test Suite</p>
        </body>
        </html>
        """
        
        success = client.send_email(
            from_addr, to_addr,
            "HTML Test Email #2",
            "This is the plain text version of the email.",
            html_body=html_body
        )
        client.disconnect()
        
        if success:
            print("✓ Test 2 passed\n")
        else:
            print("✗ Test 2 failed\n")
            return False
    else:
        print("✗ Test 2 failed - Could not connect\n")
        return False
    
    time.sleep(1)
    
    # Test 3: Multiple recipients
    print("Test 3: Sending email to multiple recipients...")
    recipients = ['user1@example.com', 'user2@example.com', 'user3@example.com']
    
    success = send_test_email(
        smtp_host, smtp_port,
        from_addr, recipients,
        "Multi-Recipient Test #3",
        "This email is being sent to multiple recipients simultaneously."
    )
    
    if success:
        print("✓ Test 3 passed\n")
    else:
        print("✗ Test 3 failed\n")
        return False
    
    print("=== All Tests Completed Successfully! ===")
    print("Check the 'received_emails' directory for the saved email files.")
    return True

def create_test_attachment():
    """Create a test file for attachment testing"""
    test_file = "test_attachment.txt"
    with open(test_file, 'w') as f:
        f.write("This is a test attachment file.\n")
        f.write("Created by the SMTP testing script.\n")
        f.write(f"Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}\n")
    return test_file

def test_with_attachment():
    """Test sending email with attachment"""
    print("\n=== Attachment Test ===")
    
    # Create test attachment
    attachment_file = create_test_attachment()
    print(f"Created test attachment: {attachment_file}")
    
    # Send email with attachment
    client = SMTPClient('localhost', 1025, use_tls=False, use_ssl=False)
    
    if client.connect():
        success = client.send_email(
            'sender@example.com',
            'recipient@example.com',
            'Email with Attachment',
            'This email contains a test attachment.',
            attachments=[attachment_file]
        )
        client.disconnect()
        
        if success:
            print("✓ Attachment test passed")
        else:
            print("✗ Attachment test failed")
    
    # Clean up
    if os.path.exists(attachment_file):
        os.remove(attachment_file)
        print(f"Cleaned up test file: {attachment_file}")

def main():
    """Main function"""
    print("SMTP Local Testing Script")
    print("=" * 50)
    print("Make sure the SMTP server is running before starting tests.")
    print("Run: python smtp_server.py")
    print("=" * 50)
    
    input("Press Enter to start tests (or Ctrl+C to cancel)...")
    
    try:
        # Run basic tests
        if test_local_smtp():
            # Run attachment test
            test_with_attachment()
            
            print("\n=== Testing Complete ===")
            print("All tests completed successfully!")
        else:
            print("\n=== Testing Failed ===")
            print("Some tests failed. Check the server is running and try again.")
            
    except KeyboardInterrupt:
        print("\nTesting cancelled by user.")
    except Exception as e:
        print(f"\nError during testing: {e}")

if __name__ == '__main__':
    main()
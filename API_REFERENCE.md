# SMTP Web Application - API Reference

## 📋 Overview

The SMTP Web Application provides both REST API endpoints and SMTP server functionality. This document covers all available APIs, endpoints, and integration methods.

---

## 🌐 Web Interface API

### Base URL
- **Development**: `http://localhost:5000`
- **Production**: `http://your-domain:5000`

### Authentication
Currently, the application uses session-based authentication. Future versions will include API key authentication.

---

## 📧 Email Management API

### Get All Emails
**Endpoint**: `GET /api/emails`

**Description**: Retrieve all stored emails with pagination support.

**Parameters**:
- `page` (optional): Page number (default: 1)
- `per_page` (optional): Items per page (default: 20, max: 100)
- `search` (optional): Search term for subject/sender/recipient
- `sort` (optional): Sort field (`date`, `subject`, `sender`) (default: `date`)
- `order` (optional): Sort order (`asc`, `desc`) (default: `desc`)

**Example Request**:
```bash
curl -X GET "http://localhost:5000/api/emails?page=1&per_page=10&search=test&sort=date&order=desc"
```

**Example Response**:
```json
{
  "emails": [
    {
      "id": "email_20250101_120000_001",
      "subject": "Test Email",
      "sender": "sender@example.com",
      "recipients": ["recipient@example.com"],
      "date": "2025-01-01T12:00:00Z",
      "size": 1024,
      "has_attachments": false,
      "preview": "This is a test email..."
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 10,
    "total": 25,
    "pages": 3,
    "has_next": true,
    "has_prev": false
  },
  "status": "success"
}
```

### Get Single Email
**Endpoint**: `GET /api/emails/<email_id>`

**Description**: Retrieve a specific email by ID.

**Example Request**:
```bash
curl -X GET "http://localhost:5000/api/emails/email_20250101_120000_001"
```

**Example Response**:
```json
{
  "email": {
    "id": "email_20250101_120000_001",
    "subject": "Test Email",
    "sender": "sender@example.com",
    "recipients": ["recipient@example.com"],
    "cc": [],
    "bcc": [],
    "date": "2025-01-01T12:00:00Z",
    "size": 1024,
    "headers": {
      "Message-ID": "<123456@example.com>",
      "Content-Type": "text/html; charset=utf-8",
      "X-Mailer": "Test Mailer"
    },
    "body": {
      "text": "This is the plain text version...",
      "html": "<html><body>This is the HTML version...</body></html>"
    },
    "attachments": []
  },
  "status": "success"
}
```

### Delete Email
**Endpoint**: `DELETE /api/emails/<email_id>`

**Description**: Delete a specific email.

**Example Request**:
```bash
curl -X DELETE "http://localhost:5000/api/emails/email_20250101_120000_001"
```

**Example Response**:
```json
{
  "message": "Email deleted successfully",
  "status": "success"
}
```

### Bulk Delete Emails
**Endpoint**: `DELETE /api/emails`

**Description**: Delete multiple emails.

**Request Body**:
```json
{
  "email_ids": ["email_20250101_120000_001", "email_20250101_120000_002"]
}
```

**Example Request**:
```bash
curl -X DELETE "http://localhost:5000/api/emails" \
  -H "Content-Type: application/json" \
  -d '{"email_ids": ["email_20250101_120000_001", "email_20250101_120000_002"]}'
```

**Example Response**:
```json
{
  "message": "2 emails deleted successfully",
  "deleted_count": 2,
  "status": "success"
}
```

---

## 📤 Email Sending API

### Send Email
**Endpoint**: `POST /api/send`

**Description**: Send an email through the SMTP server.

**Request Body**:
```json
{
  "to": ["recipient@example.com"],
  "cc": ["cc@example.com"],
  "bcc": ["bcc@example.com"],
  "subject": "Test Email",
  "body": "This is the email body",
  "html": "<html><body>This is the HTML body</body></html>",
  "attachments": [
    {
      "filename": "document.pdf",
      "content": "base64-encoded-content",
      "content_type": "application/pdf"
    }
  ]
}
```

**Example Request**:
```bash
curl -X POST "http://localhost:5000/api/send" \
  -H "Content-Type: application/json" \
  -d '{
    "to": ["test@example.com"],
    "subject": "API Test Email",
    "body": "This email was sent via API",
    "html": "<p>This email was sent via <strong>API</strong></p>"
  }'
```

**Example Response**:
```json
{
  "message": "Email sent successfully",
  "message_id": "20250101120000.123456@localhost",
  "recipients": ["test@example.com"],
  "status": "success"
}
```

### Send Email with Template
**Endpoint**: `POST /api/send/template`

**Description**: Send an email using a predefined template.

**Request Body**:
```json
{
  "template": "welcome",
  "to": ["user@example.com"],
  "variables": {
    "name": "John Doe",
    "company": "Example Corp"
  }
}
```

**Example Request**:
```bash
curl -X POST "http://localhost:5000/api/send/template" \
  -H "Content-Type: application/json" \
  -d '{
    "template": "welcome",
    "to": ["john@example.com"],
    "variables": {"name": "John Doe"}
  }'
```

---

## 📊 Statistics API

### Get Email Statistics
**Endpoint**: `GET /api/stats`

**Description**: Get email statistics and metrics.

**Parameters**:
- `period` (optional): Time period (`day`, `week`, `month`, `year`) (default: `week`)
- `start_date` (optional): Start date (ISO format)
- `end_date` (optional): End date (ISO format)

**Example Request**:
```bash
curl -X GET "http://localhost:5000/api/stats?period=week"
```

**Example Response**:
```json
{
  "stats": {
    "total_emails": 150,
    "emails_today": 12,
    "emails_this_week": 45,
    "emails_this_month": 120,
    "storage_used_mb": 25.6,
    "storage_limit_mb": 1000,
    "top_senders": [
      {"email": "sender1@example.com", "count": 25},
      {"email": "sender2@example.com", "count": 18}
    ],
    "top_recipients": [
      {"email": "recipient1@example.com", "count": 30},
      {"email": "recipient2@example.com", "count": 22}
    ],
    "daily_counts": [
      {"date": "2025-01-01", "count": 8},
      {"date": "2025-01-02", "count": 12}
    ]
  },
  "status": "success"
}
```

### Get Server Status
**Endpoint**: `GET /api/status`

**Description**: Get SMTP server and web interface status.

**Example Request**:
```bash
curl -X GET "http://localhost:5000/api/status"
```

**Example Response**:
```json
{
  "status": {
    "smtp_server": {
      "running": true,
      "host": "localhost",
      "port": 1025,
      "uptime": "2 days, 3 hours",
      "connections": 5,
      "messages_processed": 150
    },
    "web_interface": {
      "running": true,
      "host": "localhost",
      "port": 5000,
      "uptime": "2 days, 3 hours"
    },
    "storage": {
      "emails_count": 150,
      "total_size_mb": 25.6,
      "available_space_mb": 974.4
    },
    "system": {
      "cpu_usage": 15.2,
      "memory_usage": 45.8,
      "disk_usage": 2.6
    }
  },
  "timestamp": "2025-01-01T12:00:00Z",
  "status": "success"
}
```

---

## ⚙️ Configuration API

### Get Configuration
**Endpoint**: `GET /api/config`

**Description**: Get current application configuration.

**Example Request**:
```bash
curl -X GET "http://localhost:5000/api/config"
```

**Example Response**:
```json
{
  "config": {
    "smtp_server": {
      "host": "localhost",
      "port": 1025,
      "debug": false,
      "max_message_size": 10485760
    },
    "web_interface": {
      "host": "localhost",
      "port": 5000,
      "debug": false
    },
    "email_storage": {
      "directory": "emails",
      "max_size_mb": 1000,
      "auto_cleanup": true,
      "cleanup_days": 30
    }
  },
  "status": "success"
}
```

### Update Configuration
**Endpoint**: `PUT /api/config`

**Description**: Update application configuration.

**Request Body**:
```json
{
  "smtp_server": {
    "port": 2525
  },
  "email_storage": {
    "max_size_mb": 2000
  }
}
```

**Example Request**:
```bash
curl -X PUT "http://localhost:5000/api/config" \
  -H "Content-Type: application/json" \
  -d '{"smtp_server": {"port": 2525}}'
```

**Example Response**:
```json
{
  "message": "Configuration updated successfully",
  "updated_fields": ["smtp_server.port"],
  "restart_required": true,
  "status": "success"
}
```

---

## 🔧 Service Management API

### Start Services
**Endpoint**: `POST /api/services/start`

**Description**: Start SMTP server and/or web interface services.

**Request Body**:
```json
{
  "services": ["smtp", "web"]  // or ["all"]
}
```

**Example Request**:
```bash
curl -X POST "http://localhost:5000/api/services/start" \
  -H "Content-Type: application/json" \
  -d '{"services": ["smtp"]}'
```

### Stop Services
**Endpoint**: `POST /api/services/stop`

**Description**: Stop SMTP server and/or web interface services.

**Request Body**:
```json
{
  "services": ["smtp", "web"]  // or ["all"]
}
```

### Restart Services
**Endpoint**: `POST /api/services/restart`

**Description**: Restart SMTP server and/or web interface services.

**Request Body**:
```json
{
  "services": ["smtp", "web"]  // or ["all"]
}
```

---

## 📁 File Management API

### Upload Attachment
**Endpoint**: `POST /api/attachments`

**Description**: Upload file for use as email attachment.

**Request**: Multipart form data with file

**Example Request**:
```bash
curl -X POST "http://localhost:5000/api/attachments" \
  -F "file=@document.pdf"
```

**Example Response**:
```json
{
  "attachment": {
    "id": "att_20250101_120000_001",
    "filename": "document.pdf",
    "size": 1024000,
    "content_type": "application/pdf",
    "upload_date": "2025-01-01T12:00:00Z"
  },
  "status": "success"
}
```

### Get Attachment
**Endpoint**: `GET /api/attachments/<attachment_id>`

**Description**: Download attachment file.

**Example Request**:
```bash
curl -X GET "http://localhost:5000/api/attachments/att_20250101_120000_001" \
  --output document.pdf
```

---

## 🔍 Search API

### Search Emails
**Endpoint**: `GET /api/search`

**Description**: Advanced email search with filters.

**Parameters**:
- `q`: Search query
- `sender`: Filter by sender email
- `recipient`: Filter by recipient email
- `subject`: Filter by subject
- `date_from`: Start date filter (ISO format)
- `date_to`: End date filter (ISO format)
- `has_attachments`: Filter emails with attachments (true/false)
- `size_min`: Minimum email size in bytes
- `size_max`: Maximum email size in bytes

**Example Request**:
```bash
curl -X GET "http://localhost:5000/api/search?q=invoice&sender=billing@example.com&has_attachments=true"
```

**Example Response**:
```json
{
  "results": [
    {
      "id": "email_20250101_120000_001",
      "subject": "Invoice #12345",
      "sender": "billing@example.com",
      "recipients": ["customer@example.com"],
      "date": "2025-01-01T12:00:00Z",
      "relevance_score": 0.95
    }
  ],
  "total_results": 1,
  "query": "invoice",
  "filters": {
    "sender": "billing@example.com",
    "has_attachments": true
  },
  "status": "success"
}
```

---

## 🔐 SMTP Server Protocol

### Connection
- **Host**: localhost (or configured host)
- **Port**: 1025 (or configured port)
- **Security**: None (STARTTLS optional)
- **Authentication**: None (optional)

### Supported Commands
- `HELO` / `EHLO`: Greeting
- `MAIL FROM`: Sender specification
- `RCPT TO`: Recipient specification
- `DATA`: Message data
- `QUIT`: Close connection
- `RSET`: Reset session
- `NOOP`: No operation
- `HELP`: Show help

### Example SMTP Session
```
telnet localhost 1025
220 localhost SMTP Server ready
HELO client.example.com
250 Hello client.example.com
MAIL FROM:<sender@example.com>
250 OK
RCPT TO:<recipient@example.com>
250 OK
DATA
354 Start mail input; end with <CRLF>.<CRLF>
Subject: Test Email

This is a test email.
.
250 Message accepted for delivery
QUIT
221 Bye
```

---

## 🐍 Python Client Library

### Installation
```bash
pip install requests  # For HTTP API
# SMTP client is built into Python standard library
```

### HTTP API Client Example
```python
import requests
import json

class SMTPWebAppClient:
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
        self.session = requests.Session()
    
    def get_emails(self, page=1, per_page=20):
        """Get list of emails"""
        response = self.session.get(
            f"{self.base_url}/api/emails",
            params={"page": page, "per_page": per_page}
        )
        return response.json()
    
    def get_email(self, email_id):
        """Get specific email"""
        response = self.session.get(f"{self.base_url}/api/emails/{email_id}")
        return response.json()
    
    def send_email(self, to, subject, body, html=None):
        """Send email via API"""
        data = {
            "to": to if isinstance(to, list) else [to],
            "subject": subject,
            "body": body
        }
        if html:
            data["html"] = html
            
        response = self.session.post(
            f"{self.base_url}/api/send",
            json=data
        )
        return response.json()
    
    def get_stats(self, period="week"):
        """Get email statistics"""
        response = self.session.get(
            f"{self.base_url}/api/stats",
            params={"period": period}
        )
        return response.json()

# Usage example
client = SMTPWebAppClient()

# Get emails
emails = client.get_emails(page=1, per_page=10)
print(f"Found {emails['pagination']['total']} emails")

# Send email
result = client.send_email(
    to="test@example.com",
    subject="API Test",
    body="This email was sent via Python API client"
)
print(f"Email sent: {result['message_id']}")
```

### SMTP Client Example
```python
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def send_smtp_email(host="localhost", port=1025):
    """Send email via SMTP"""
    # Create message
    msg = MIMEMultipart()
    msg['From'] = "sender@example.com"
    msg['To'] = "recipient@example.com"
    msg['Subject'] = "SMTP Test Email"
    
    # Add body
    body = "This is a test email sent via SMTP"
    msg.attach(MIMEText(body, 'plain'))
    
    # Send email
    with smtplib.SMTP(host, port) as server:
        server.send_message(msg)
    
    print("Email sent successfully via SMTP")

# Usage
send_smtp_email()
```

---

## 🌐 JavaScript Client Example

### Fetch API
```javascript
class SMTPWebAppClient {
    constructor(baseUrl = 'http://localhost:5000') {
        this.baseUrl = baseUrl;
    }
    
    async getEmails(page = 1, perPage = 20) {
        const response = await fetch(
            `${this.baseUrl}/api/emails?page=${page}&per_page=${perPage}`
        );
        return await response.json();
    }
    
    async getEmail(emailId) {
        const response = await fetch(`${this.baseUrl}/api/emails/${emailId}`);
        return await response.json();
    }
    
    async sendEmail(to, subject, body, html = null) {
        const data = {
            to: Array.isArray(to) ? to : [to],
            subject,
            body
        };
        
        if (html) {
            data.html = html;
        }
        
        const response = await fetch(`${this.baseUrl}/api/send`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data)
        });
        
        return await response.json();
    }
    
    async getStats(period = 'week') {
        const response = await fetch(
            `${this.baseUrl}/api/stats?period=${period}`
        );
        return await response.json();
    }
}

// Usage example
const client = new SMTPWebAppClient();

// Get emails
client.getEmails(1, 10).then(emails => {
    console.log(`Found ${emails.pagination.total} emails`);
});

// Send email
client.sendEmail(
    'test@example.com',
    'JavaScript API Test',
    'This email was sent via JavaScript API client'
).then(result => {
    console.log(`Email sent: ${result.message_id}`);
});
```

---

## 📝 Error Handling

### HTTP Status Codes
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `403`: Forbidden
- `404`: Not Found
- `422`: Validation Error
- `500`: Internal Server Error

### Error Response Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email address format",
    "details": {
      "field": "to",
      "value": "invalid-email"
    }
  },
  "status": "error"
}
```

### Common Error Codes
- `VALIDATION_ERROR`: Input validation failed
- `EMAIL_NOT_FOUND`: Requested email doesn't exist
- `SMTP_ERROR`: SMTP server error
- `STORAGE_FULL`: Email storage limit reached
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `SERVICE_UNAVAILABLE`: Service temporarily unavailable

---

## 🔒 Security Considerations

### Rate Limiting
- Default: 100 requests per minute per IP
- Configurable via `MAX_REQUESTS_PER_MINUTE`
- Returns `429 Too Many Requests` when exceeded

### Input Validation
- All email addresses validated
- File uploads scanned for malicious content
- SQL injection protection
- XSS protection for web interface

### CORS Support
```javascript
// Configure CORS for cross-origin requests
const corsOptions = {
    origin: ['http://localhost:3000', 'https://yourdomain.com'],
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
};
```

---

## 📚 SDK and Libraries

### Official Python SDK
```bash
pip install smtp-webapp-sdk
```

### Community Libraries
- **Node.js**: `npm install smtp-webapp-client`
- **PHP**: `composer require smtp-webapp/client`
- **Go**: `go get github.com/smtp-webapp/go-client`

---

*Last updated: January 2025*
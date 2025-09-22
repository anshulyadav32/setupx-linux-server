#!/usr/bin/env python3
"""
Gmail API Integration Module
Handles Gmail OAuth authentication, email retrieval, and sending
"""

import os
import json
import base64
import logging
from datetime import datetime, timezone
from typing import List, Dict, Optional, Any
import pickle

# Gmail API imports
try:
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import Flow
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    from email.mime.text import MIMEText
    from email.mime.multipart import MIMEMultipart
    from email.mime.base import MIMEBase
    from email import encoders
except ImportError as e:
    logging.error(f"Gmail API dependencies not installed: {e}")
    logging.error("Install with: pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client")

class GmailIntegration:
    """Gmail API integration for OAuth authentication and email operations"""
    
    def __init__(self, config_path: str = "config/gmail_config.json"):
        """Initialize Gmail integration with configuration"""
        self.config_path = config_path
        self.config = self._load_config()
        self.scopes = [
            'https://www.googleapis.com/auth/gmail.readonly',
            'https://www.googleapis.com/auth/gmail.send',
            'https://www.googleapis.com/auth/gmail.modify'
        ]
        self.logger = logging.getLogger(__name__)
        
    def _load_config(self) -> Dict[str, Any]:
        """Load Gmail configuration from JSON file"""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            self.logger.error(f"Gmail config file not found: {self.config_path}")
            return {}
        except json.JSONDecodeError as e:
            self.logger.error(f"Invalid JSON in Gmail config: {e}")
            return {}
    
    def get_authorization_url(self, user_id: str, email: str) -> str:
        """Generate OAuth authorization URL for Gmail"""
        try:
            # Create flow instance
            flow = Flow.from_client_config(
                {
                    "web": {
                        "client_id": self.config.get("client_id"),
                        "client_secret": self.config.get("client_secret"),
                        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                        "token_uri": "https://oauth2.googleapis.com/token",
                        "redirect_uris": [self.config.get("redirect_uri")]
                    }
                },
                scopes=self.scopes
            )
            
            flow.redirect_uri = self.config.get("redirect_uri")
            
            # Generate authorization URL with state parameter
            auth_url, state = flow.authorization_url(
                access_type='offline',
                include_granted_scopes='true',
                state=f"{user_id}:{email}:gmail"
            )
            
            return auth_url
            
        except Exception as e:
            self.logger.error(f"Error generating Gmail auth URL: {e}")
            raise
    
    def exchange_code_for_tokens(self, code: str, state: str) -> Dict[str, Any]:
        """Exchange authorization code for access tokens"""
        try:
            # Create flow instance
            flow = Flow.from_client_config(
                {
                    "web": {
                        "client_id": self.config.get("client_id"),
                        "client_secret": self.config.get("client_secret"),
                        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                        "token_uri": "https://oauth2.googleapis.com/token",
                        "redirect_uris": [self.config.get("redirect_uri")]
                    }
                },
                scopes=self.scopes,
                state=state
            )
            
            flow.redirect_uri = self.config.get("redirect_uri")
            
            # Fetch tokens
            flow.fetch_token(code=code)
            
            # Get credentials
            credentials = flow.credentials
            
            # Return token information
            return {
                'access_token': credentials.token,
                'refresh_token': credentials.refresh_token,
                'token_uri': credentials.token_uri,
                'client_id': credentials.client_id,
                'client_secret': credentials.client_secret,
                'scopes': credentials.scopes,
                'expiry': credentials.expiry.isoformat() if credentials.expiry else None
            }
            
        except Exception as e:
            self.logger.error(f"Error exchanging Gmail code for tokens: {e}")
            raise
    
    def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """Refresh Gmail access token using refresh token"""
        try:
            credentials = Credentials(
                token=None,
                refresh_token=refresh_token,
                token_uri="https://oauth2.googleapis.com/token",
                client_id=self.config.get("client_id"),
                client_secret=self.config.get("client_secret")
            )
            
            # Refresh the token
            credentials.refresh(Request())
            
            return {
                'access_token': credentials.token,
                'refresh_token': credentials.refresh_token,
                'expiry': credentials.expiry.isoformat() if credentials.expiry else None
            }
            
        except Exception as e:
            self.logger.error(f"Error refreshing Gmail token: {e}")
            raise
    
    def get_service(self, access_token: str, refresh_token: str = None):
        """Get Gmail API service instance"""
        try:
            credentials = Credentials(
                token=access_token,
                refresh_token=refresh_token,
                token_uri="https://oauth2.googleapis.com/token",
                client_id=self.config.get("client_id"),
                client_secret=self.config.get("client_secret")
            )
            
            # Build and return service
            service = build('gmail', 'v1', credentials=credentials)
            return service
            
        except Exception as e:
            self.logger.error(f"Error creating Gmail service: {e}")
            raise
    
    def get_user_profile(self, access_token: str, refresh_token: str = None) -> Dict[str, Any]:
        """Get Gmail user profile information"""
        try:
            service = self.get_service(access_token, refresh_token)
            profile = service.users().getProfile(userId='me').execute()
            
            return {
                'email': profile.get('emailAddress'),
                'messages_total': profile.get('messagesTotal', 0),
                'threads_total': profile.get('threadsTotal', 0),
                'history_id': profile.get('historyId')
            }
            
        except Exception as e:
            self.logger.error(f"Error getting Gmail profile: {e}")
            raise
    
    def get_messages(self, access_token: str, refresh_token: str = None, 
                    max_results: int = 50, page_token: str = None,
                    query: str = None) -> Dict[str, Any]:
        """Get Gmail messages"""
        try:
            service = self.get_service(access_token, refresh_token)
            
            # Build request parameters
            params = {
                'userId': 'me',
                'maxResults': max_results
            }
            
            if page_token:
                params['pageToken'] = page_token
            if query:
                params['q'] = query
            
            # Get message list
            result = service.users().messages().list(**params).execute()
            messages = result.get('messages', [])
            
            # Get detailed message information
            detailed_messages = []
            for msg in messages:
                try:
                    msg_detail = service.users().messages().get(
                        userId='me', 
                        id=msg['id'],
                        format='full'
                    ).execute()
                    
                    # Parse message details
                    headers = msg_detail['payload'].get('headers', [])
                    header_dict = {h['name']: h['value'] for h in headers}
                    
                    # Get message body
                    body = self._extract_message_body(msg_detail['payload'])
                    
                    detailed_messages.append({
                        'id': msg_detail['id'],
                        'thread_id': msg_detail['threadId'],
                        'subject': header_dict.get('Subject', 'No Subject'),
                        'from': header_dict.get('From', 'Unknown'),
                        'to': header_dict.get('To', 'Unknown'),
                        'date': header_dict.get('Date', 'Unknown'),
                        'body': body,
                        'snippet': msg_detail.get('snippet', ''),
                        'labels': msg_detail.get('labelIds', []),
                        'size': msg_detail.get('sizeEstimate', 0),
                        'unread': 'UNREAD' in msg_detail.get('labelIds', [])
                    })
                    
                except Exception as e:
                    self.logger.error(f"Error getting message details for {msg['id']}: {e}")
                    continue
            
            return {
                'messages': detailed_messages,
                'next_page_token': result.get('nextPageToken'),
                'result_size_estimate': result.get('resultSizeEstimate', 0)
            }
            
        except Exception as e:
            self.logger.error(f"Error getting Gmail messages: {e}")
            raise
    
    def _extract_message_body(self, payload: Dict[str, Any]) -> str:
        """Extract message body from Gmail payload"""
        try:
            # Handle multipart messages
            if 'parts' in payload:
                for part in payload['parts']:
                    if part['mimeType'] == 'text/plain':
                        data = part['body'].get('data')
                        if data:
                            return base64.urlsafe_b64decode(data).decode('utf-8')
                    elif part['mimeType'] == 'text/html':
                        data = part['body'].get('data')
                        if data:
                            return base64.urlsafe_b64decode(data).decode('utf-8')
            
            # Handle single part messages
            elif payload['mimeType'] in ['text/plain', 'text/html']:
                data = payload['body'].get('data')
                if data:
                    return base64.urlsafe_b64decode(data).decode('utf-8')
            
            return ""
            
        except Exception as e:
            self.logger.error(f"Error extracting message body: {e}")
            return ""
    
    def send_message(self, access_token: str, refresh_token: str = None,
                    to_addresses: List[str] = None, cc_addresses: List[str] = None,
                    bcc_addresses: List[str] = None, subject: str = "",
                    body: str = "", attachments: List[Dict] = None) -> str:
        """Send email via Gmail API"""
        try:
            service = self.get_service(access_token, refresh_token)
            
            # Create message
            message = MIMEMultipart()
            message['to'] = ', '.join(to_addresses or [])
            if cc_addresses:
                message['cc'] = ', '.join(cc_addresses)
            if bcc_addresses:
                message['bcc'] = ', '.join(bcc_addresses)
            message['subject'] = subject
            
            # Add body
            message.attach(MIMEText(body, 'plain'))
            
            # Add attachments if any
            if attachments:
                for attachment in attachments:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(attachment['content'])
                    encoders.encode_base64(part)
                    part.add_header(
                        'Content-Disposition',
                        f'attachment; filename= {attachment["filename"]}'
                    )
                    message.attach(part)
            
            # Encode message
            raw_message = base64.urlsafe_b64encode(message.as_bytes()).decode('utf-8')
            
            # Send message
            result = service.users().messages().send(
                userId='me',
                body={'raw': raw_message}
            ).execute()
            
            return result['id']
            
        except Exception as e:
            self.logger.error(f"Error sending Gmail message: {e}")
            raise
    
    def mark_as_read(self, access_token: str, message_id: str, refresh_token: str = None) -> bool:
        """Mark Gmail message as read"""
        try:
            service = self.get_service(access_token, refresh_token)
            
            service.users().messages().modify(
                userId='me',
                id=message_id,
                body={'removeLabelIds': ['UNREAD']}
            ).execute()
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error marking Gmail message as read: {e}")
            return False
    
    def delete_message(self, access_token: str, message_id: str, refresh_token: str = None) -> bool:
        """Delete Gmail message"""
        try:
            service = self.get_service(access_token, refresh_token)
            
            service.users().messages().delete(
                userId='me',
                id=message_id
            ).execute()
            
            return True
            
        except Exception as e:
            self.logger.error(f"Error deleting Gmail message: {e}")
            return False
#!/usr/bin/env python3
"""
Outlook/Microsoft Graph API Integration Module
Handles Outlook OAuth authentication, email retrieval, and sending
"""

import os
import json
import base64
import logging
from datetime import datetime, timezone
from typing import List, Dict, Optional, Any
import requests
from urllib.parse import urlencode

class OutlookIntegration:
    """Outlook/Microsoft Graph API integration for OAuth authentication and email operations"""
    
    def __init__(self, config_path: str = "config/outlook_config.json"):
        """Initialize Outlook integration with configuration"""
        self.config_path = config_path
        self.config = self._load_config()
        self.base_url = "https://graph.microsoft.com/v1.0"
        self.auth_url = "https://login.microsoftonline.com"
        self.scopes = [
            'https://graph.microsoft.com/Mail.Read',
            'https://graph.microsoft.com/Mail.ReadWrite',
            'https://graph.microsoft.com/Mail.Send',
            'https://graph.microsoft.com/User.Read'
        ]
        self.logger = logging.getLogger(__name__)
        
    def _load_config(self) -> Dict[str, Any]:
        """Load Outlook configuration from JSON file"""
        try:
            with open(self.config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            self.logger.error(f"Outlook config file not found: {self.config_path}")
            return {}
        except json.JSONDecodeError as e:
            self.logger.error(f"Invalid JSON in Outlook config: {e}")
            return {}
    
    def get_authorization_url(self, user_id: str, email: str) -> str:
        """Generate OAuth authorization URL for Outlook"""
        try:
            tenant_id = self.config.get("tenant_id", "common")
            
            params = {
                'client_id': self.config.get("client_id"),
                'response_type': 'code',
                'redirect_uri': self.config.get("redirect_uri"),
                'scope': ' '.join(self.scopes),
                'state': f"{user_id}:{email}:outlook",
                'response_mode': 'query'
            }
            
            auth_url = f"{self.auth_url}/{tenant_id}/oauth2/v2.0/authorize?{urlencode(params)}"
            return auth_url
            
        except Exception as e:
            self.logger.error(f"Error generating Outlook auth URL: {e}")
            raise
    
    def exchange_code_for_tokens(self, code: str, state: str) -> Dict[str, Any]:
        """Exchange authorization code for access tokens"""
        try:
            tenant_id = self.config.get("tenant_id", "common")
            token_url = f"{self.auth_url}/{tenant_id}/oauth2/v2.0/token"
            
            data = {
                'client_id': self.config.get("client_id"),
                'client_secret': self.config.get("client_secret"),
                'code': code,
                'redirect_uri': self.config.get("redirect_uri"),
                'grant_type': 'authorization_code',
                'scope': ' '.join(self.scopes)
            }
            
            response = requests.post(token_url, data=data)
            response.raise_for_status()
            
            token_data = response.json()
            
            return {
                'access_token': token_data.get('access_token'),
                'refresh_token': token_data.get('refresh_token'),
                'expires_in': token_data.get('expires_in'),
                'token_type': token_data.get('token_type'),
                'scope': token_data.get('scope')
            }
            
        except Exception as e:
            self.logger.error(f"Error exchanging Outlook code for tokens: {e}")
            raise
    
    def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """Refresh Outlook access token using refresh token"""
        try:
            tenant_id = self.config.get("tenant_id", "common")
            token_url = f"{self.auth_url}/{tenant_id}/oauth2/v2.0/token"
            
            data = {
                'client_id': self.config.get("client_id"),
                'client_secret': self.config.get("client_secret"),
                'refresh_token': refresh_token,
                'grant_type': 'refresh_token',
                'scope': ' '.join(self.scopes)
            }
            
            response = requests.post(token_url, data=data)
            response.raise_for_status()
            
            token_data = response.json()
            
            return {
                'access_token': token_data.get('access_token'),
                'refresh_token': token_data.get('refresh_token'),
                'expires_in': token_data.get('expires_in')
            }
            
        except Exception as e:
            self.logger.error(f"Error refreshing Outlook token: {e}")
            raise
    
    def _make_request(self, method: str, endpoint: str, access_token: str, 
                     data: Dict = None, params: Dict = None) -> Dict[str, Any]:
        """Make authenticated request to Microsoft Graph API"""
        try:
            headers = {
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/json'
            }
            
            url = f"{self.base_url}{endpoint}"
            
            if method.upper() == 'GET':
                response = requests.get(url, headers=headers, params=params)
            elif method.upper() == 'POST':
                response = requests.post(url, headers=headers, json=data, params=params)
            elif method.upper() == 'PATCH':
                response = requests.patch(url, headers=headers, json=data, params=params)
            elif method.upper() == 'DELETE':
                response = requests.delete(url, headers=headers, params=params)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            response.raise_for_status()
            
            # Handle empty responses
            if response.status_code == 204:
                return {}
            
            return response.json()
            
        except Exception as e:
            self.logger.error(f"Error making Outlook API request: {e}")
            raise
    
    def get_user_profile(self, access_token: str) -> Dict[str, Any]:
        """Get Outlook user profile information"""
        try:
            profile = self._make_request('GET', '/me', access_token)
            
            return {
                'email': profile.get('mail') or profile.get('userPrincipalName'),
                'display_name': profile.get('displayName'),
                'given_name': profile.get('givenName'),
                'surname': profile.get('surname'),
                'id': profile.get('id')
            }
            
        except Exception as e:
            self.logger.error(f"Error getting Outlook profile: {e}")
            raise
    
    def get_messages(self, access_token: str, max_results: int = 50, 
                    skip: int = 0, folder: str = 'inbox',
                    filter_query: str = None) -> Dict[str, Any]:
        """Get Outlook messages"""
        try:
            params = {
                '$top': max_results,
                '$skip': skip,
                '$orderby': 'receivedDateTime desc',
                '$select': 'id,subject,from,toRecipients,ccRecipients,receivedDateTime,bodyPreview,body,isRead,hasAttachments'
            }
            
            if filter_query:
                params['$filter'] = filter_query
            
            endpoint = f'/me/mailFolders/{folder}/messages'
            result = self._make_request('GET', endpoint, access_token, params=params)
            
            messages = []
            for msg in result.get('value', []):
                # Parse message details
                from_address = msg.get('from', {}).get('emailAddress', {})
                to_addresses = [addr.get('emailAddress', {}) for addr in msg.get('toRecipients', [])]
                cc_addresses = [addr.get('emailAddress', {}) for addr in msg.get('ccRecipients', [])]
                
                # Get message body
                body_content = msg.get('body', {})
                body = body_content.get('content', '') if body_content else ''
                
                messages.append({
                    'id': msg.get('id'),
                    'subject': msg.get('subject', 'No Subject'),
                    'from': f"{from_address.get('name', '')} <{from_address.get('address', '')}>",
                    'to': [f"{addr.get('name', '')} <{addr.get('address', '')}>" for addr in to_addresses],
                    'cc': [f"{addr.get('name', '')} <{addr.get('address', '')}>" for addr in cc_addresses],
                    'date': msg.get('receivedDateTime'),
                    'body': body,
                    'snippet': msg.get('bodyPreview', ''),
                    'unread': not msg.get('isRead', True),
                    'has_attachments': msg.get('hasAttachments', False)
                })
            
            return {
                'messages': messages,
                'total_count': len(messages),
                'has_more': len(result.get('value', [])) == max_results
            }
            
        except Exception as e:
            self.logger.error(f"Error getting Outlook messages: {e}")
            raise
    
    def get_message_details(self, access_token: str, message_id: str) -> Dict[str, Any]:
        """Get detailed information for a specific message"""
        try:
            endpoint = f'/me/messages/{message_id}'
            params = {
                '$select': 'id,subject,from,toRecipients,ccRecipients,bccRecipients,receivedDateTime,sentDateTime,body,bodyPreview,isRead,hasAttachments,attachments'
            }
            
            message = self._make_request('GET', endpoint, access_token, params=params)
            
            # Parse message details
            from_address = message.get('from', {}).get('emailAddress', {})
            to_addresses = [addr.get('emailAddress', {}) for addr in message.get('toRecipients', [])]
            cc_addresses = [addr.get('emailAddress', {}) for addr in message.get('ccRecipients', [])]
            bcc_addresses = [addr.get('emailAddress', {}) for addr in message.get('bccRecipients', [])]
            
            # Get message body
            body_content = message.get('body', {})
            body = body_content.get('content', '') if body_content else ''
            
            return {
                'id': message.get('id'),
                'subject': message.get('subject', 'No Subject'),
                'from': f"{from_address.get('name', '')} <{from_address.get('address', '')}>",
                'to': [f"{addr.get('name', '')} <{addr.get('address', '')}>" for addr in to_addresses],
                'cc': [f"{addr.get('name', '')} <{addr.get('address', '')}>" for addr in cc_addresses],
                'bcc': [f"{addr.get('name', '')} <{addr.get('address', '')}>" for addr in bcc_addresses],
                'received_date': message.get('receivedDateTime'),
                'sent_date': message.get('sentDateTime'),
                'body': body,
                'body_type': body_content.get('contentType', 'text'),
                'snippet': message.get('bodyPreview', ''),
                'unread': not message.get('isRead', True),
                'has_attachments': message.get('hasAttachments', False),
                'attachments': message.get('attachments', [])
            }
            
        except Exception as e:
            self.logger.error(f"Error getting Outlook message details: {e}")
            raise
    
    def send_message(self, access_token: str, to_addresses: List[str] = None,
                    cc_addresses: List[str] = None, bcc_addresses: List[str] = None,
                    subject: str = "", body: str = "", body_type: str = "text",
                    attachments: List[Dict] = None) -> str:
        """Send email via Outlook API"""
        try:
            # Build recipient lists
            to_recipients = [{'emailAddress': {'address': addr}} for addr in (to_addresses or [])]
            cc_recipients = [{'emailAddress': {'address': addr}} for addr in (cc_addresses or [])]
            bcc_recipients = [{'emailAddress': {'address': addr}} for addr in (bcc_addresses or [])]
            
            # Build message
            message_data = {
                'message': {
                    'subject': subject,
                    'body': {
                        'contentType': 'HTML' if body_type.lower() == 'html' else 'Text',
                        'content': body
                    },
                    'toRecipients': to_recipients
                }
            }
            
            if cc_recipients:
                message_data['message']['ccRecipients'] = cc_recipients
            if bcc_recipients:
                message_data['message']['bccRecipients'] = bcc_recipients
            
            # Add attachments if any
            if attachments:
                message_data['message']['attachments'] = []
                for attachment in attachments:
                    attachment_data = {
                        '@odata.type': '#microsoft.graph.fileAttachment',
                        'name': attachment['filename'],
                        'contentBytes': base64.b64encode(attachment['content']).decode('utf-8')
                    }
                    message_data['message']['attachments'].append(attachment_data)
            
            # Send message
            result = self._make_request('POST', '/me/sendMail', access_token, data=message_data)
            
            # Outlook sendMail returns empty response on success
            return "sent_successfully"
            
        except Exception as e:
            self.logger.error(f"Error sending Outlook message: {e}")
            raise
    
    def mark_as_read(self, access_token: str, message_id: str) -> bool:
        """Mark Outlook message as read"""
        try:
            data = {'isRead': True}
            self._make_request('PATCH', f'/me/messages/{message_id}', access_token, data=data)
            return True
            
        except Exception as e:
            self.logger.error(f"Error marking Outlook message as read: {e}")
            return False
    
    def mark_as_unread(self, access_token: str, message_id: str) -> bool:
        """Mark Outlook message as unread"""
        try:
            data = {'isRead': False}
            self._make_request('PATCH', f'/me/messages/{message_id}', access_token, data=data)
            return True
            
        except Exception as e:
            self.logger.error(f"Error marking Outlook message as unread: {e}")
            return False
    
    def delete_message(self, access_token: str, message_id: str) -> bool:
        """Delete Outlook message"""
        try:
            self._make_request('DELETE', f'/me/messages/{message_id}', access_token)
            return True
            
        except Exception as e:
            self.logger.error(f"Error deleting Outlook message: {e}")
            return False
    
    def get_folders(self, access_token: str) -> List[Dict[str, Any]]:
        """Get Outlook mail folders"""
        try:
            result = self._make_request('GET', '/me/mailFolders', access_token)
            
            folders = []
            for folder in result.get('value', []):
                folders.append({
                    'id': folder.get('id'),
                    'display_name': folder.get('displayName'),
                    'parent_folder_id': folder.get('parentFolderId'),
                    'child_folder_count': folder.get('childFolderCount', 0),
                    'unread_item_count': folder.get('unreadItemCount', 0),
                    'total_item_count': folder.get('totalItemCount', 0)
                })
            
            return folders
            
        except Exception as e:
            self.logger.error(f"Error getting Outlook folders: {e}")
            raise
    
    def move_message(self, access_token: str, message_id: str, destination_folder_id: str) -> bool:
        """Move message to a different folder"""
        try:
            data = {'destinationId': destination_folder_id}
            self._make_request('POST', f'/me/messages/{message_id}/move', access_token, data=data)
            return True
            
        except Exception as e:
            self.logger.error(f"Error moving Outlook message: {e}")
            return False
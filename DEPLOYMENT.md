# Vercel Deployment Guide

This guide will help you deploy your SMTP Email Management System to Vercel.

## Prerequisites

1. **Vercel Account**: Sign up at [vercel.com](https://vercel.com)
2. **Git Repository**: Your code should be in a Git repository (GitHub, GitLab, or Bitbucket)
3. **Vercel CLI** (optional): Install with `npm i -g vercel`

## Deployment Steps

### Method 1: Deploy via Vercel Dashboard (Recommended)

1. **Push your code to Git repository**
   ```bash
   git add .
   git commit -m "Prepare for Vercel deployment"
   git push origin main
   ```

2. **Connect to Vercel**
   - Go to [vercel.com/dashboard](https://vercel.com/dashboard)
   - Click "New Project"
   - Import your Git repository
   - Select the repository containing your email management system

3. **Configure Environment Variables**
   In the Vercel dashboard, add these environment variables:
   ```
   FLASK_ENV=production
   SECRET_KEY=your-super-secret-key-here-generate-a-new-one
   GMAIL_CLIENT_ID=your-gmail-client-id
   GMAIL_CLIENT_SECRET=your-gmail-client-secret
   OUTLOOK_CLIENT_ID=your-outlook-client-id
   OUTLOOK_CLIENT_SECRET=your-outlook-client-secret
   ```

4. **Deploy**
   - Click "Deploy"
   - Vercel will automatically detect the Python project and use the `vercel.json` configuration

### Method 2: Deploy via Vercel CLI

1. **Install Vercel CLI**
   ```bash
   npm i -g vercel
   ```

2. **Login to Vercel**
   ```bash
   vercel login
   ```

3. **Deploy**
   ```bash
   vercel --prod
   ```

4. **Set Environment Variables**
   ```bash
   vercel env add SECRET_KEY
   vercel env add GMAIL_CLIENT_ID
   vercel env add GMAIL_CLIENT_SECRET
   vercel env add OUTLOOK_CLIENT_ID
   vercel env add OUTLOOK_CLIENT_SECRET
   ```

## Configuration Files Created

### `vercel.json`
- Configures Python runtime
- Sets up routing
- Defines environment variables
- Configures function timeout

### `app.py`
- Vercel-compatible entry point
- Imports Flask app from `web_interface.py`
- Handles serverless environment setup

### `requirements.txt`
- Updated with all necessary dependencies
- Includes Flask, Google APIs, OAuth libraries
- Optimized for serverless deployment

### `.vercelignore`
- Excludes unnecessary files from deployment
- Reduces bundle size
- Excludes local databases and logs

## Important Notes

### Database Considerations
- **Local SQLite databases won't persist** in serverless environment
- Consider using external database services:
  - **PostgreSQL**: Vercel Postgres, Supabase, or Neon
  - **MySQL**: PlanetScale or Railway
  - **MongoDB**: MongoDB Atlas

### Session Storage
- File-based sessions won't work in serverless
- Consider using:
  - **Redis**: Upstash Redis
  - **Database sessions**: Store in your external database

### File Storage
- Uploaded files and received emails won't persist
- Consider using:
  - **Vercel Blob**: For file storage
  - **AWS S3**: For larger storage needs
  - **Cloudinary**: For image/document management

### SMTP Server Limitations
- The built-in SMTP server (`smtp_server.py`) won't work in serverless
- Use external SMTP services:
  - **SendGrid**
  - **Mailgun**
  - **AWS SES**
  - **Postmark**

## Environment Variables Reference

Create these in your Vercel dashboard:

| Variable | Description | Required |
|----------|-------------|----------|
| `FLASK_ENV` | Set to "production" | Yes |
| `SECRET_KEY` | Flask secret key (generate new one) | Yes |
| `GMAIL_CLIENT_ID` | Google OAuth client ID | For Gmail |
| `GMAIL_CLIENT_SECRET` | Google OAuth client secret | For Gmail |
| `OUTLOOK_CLIENT_ID` | Microsoft OAuth client ID | For Outlook |
| `OUTLOOK_CLIENT_SECRET` | Microsoft OAuth client secret | For Outlook |
| `DATABASE_URL` | External database URL | Recommended |

## OAuth Setup

### Gmail OAuth
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Gmail API
4. Create OAuth 2.0 credentials
5. Add your Vercel domain to authorized origins
6. Add redirect URI: `https://your-app.vercel.app/oauth/gmail/callback`

### Outlook OAuth
1. Go to [Azure Portal](https://portal.azure.com/)
2. Register a new application
3. Add Microsoft Graph permissions
4. Add redirect URI: `https://your-app.vercel.app/oauth/outlook/callback`

## Testing Deployment

1. **Check deployment status** in Vercel dashboard
2. **Visit your deployed URL**
3. **Test login** with admin/admin123
4. **Test email account creation**
5. **Verify OAuth flows work**

## Troubleshooting

### Common Issues

1. **Import Errors**
   - Check all dependencies are in `requirements.txt`
   - Verify Python version compatibility

2. **Database Errors**
   - Set up external database
   - Update connection strings

3. **OAuth Errors**
   - Verify redirect URIs match your domain
   - Check client IDs and secrets

4. **Session Errors**
   - Configure external session storage
   - Check session configuration

### Logs and Debugging

- View logs in Vercel dashboard under "Functions" tab
- Use `vercel logs` command for CLI access
- Add debug logging to your application

## Production Checklist

- [ ] Environment variables configured
- [ ] External database set up
- [ ] OAuth applications configured
- [ ] Session storage configured
- [ ] File storage configured
- [ ] SMTP service configured
- [ ] Domain configured (optional)
- [ ] SSL certificate (automatic with Vercel)

## Support

For deployment issues:
- Check [Vercel Documentation](https://vercel.com/docs)
- Review [Python on Vercel Guide](https://vercel.com/docs/functions/serverless-functions/runtimes/python)
- Contact Vercel support for platform issues

Your email management system is now ready for production deployment on Vercel! 🚀
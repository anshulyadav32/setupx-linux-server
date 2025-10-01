# 🚀 Deployment Guide

This project supports multiple deployment platforms for maximum flexibility and performance.

## 🌐 Deployment Options

### 1. GitHub Pages
- **URL**: `https://anshulyadav32.github.io/setupx-linux-server/`
- **Branch**: `github-pages`
- **Auto-deploy**: ✅ Enabled via GitHub Actions
- **Features**: Free, integrated with GitHub

### 2. Vercel
- **URL**: `https://setupx-linux-server.vercel.app`
- **Auto-deploy**: ✅ Enabled via GitHub Actions
- **Features**: Global CDN, serverless functions, preview deployments

### 3. Manual Deployment
- **Local**: `python -m http.server 8000`
- **Any static host**: Upload files to any web server

## 🔧 Setup Instructions

### GitHub Pages Setup
1. Go to repository **Settings** → **Pages**
2. Select **Source**: GitHub Actions
3. Push to `github-pages` branch to trigger deployment

### Vercel Setup
1. Install Vercel CLI: `npm i -g vercel`
2. Login: `vercel login`
3. Deploy: `vercel --prod`
4. Or connect GitHub repository in Vercel dashboard

### Environment Variables
For Vercel deployment, add these secrets in GitHub:
- `VERCEL_TOKEN`: Your Vercel API token
- `VERCEL_ORG_ID`: Your Vercel organization ID
- `VERCEL_PROJECT_ID`: Your Vercel project ID

## 📁 File Structure
```
├── index.html          # Main website
├── styles.css          # Styling
├── script.js           # JavaScript
├── package.json        # Node.js configuration
├── vercel.json         # Vercel configuration
├── .github/workflows/  # GitHub Actions
│   ├── github-pages.yml
│   └── vercel-deploy.yml
└── README.md           # Documentation
```

## 🚀 Quick Deploy Commands

### GitHub Pages
```bash
git push origin github-pages
```

### Vercel
```bash
vercel --prod
```

### Local Development
```bash
python -m http.server 8000
# or
npx serve .
```

## 🔄 Automatic Deployments

Both platforms will automatically deploy when you:
- Push to `main` branch (Vercel)
- Push to `github-pages` branch (GitHub Pages)
- Create pull requests (Vercel preview)

## 📊 Performance Features

### Vercel Optimizations
- Global CDN distribution
- Automatic HTTPS
- Edge functions support
- Preview deployments for PRs
- Analytics and monitoring

### GitHub Pages Features
- Free hosting
- Custom domain support
- Jekyll integration (if needed)
- GitHub integration

## 🛠️ Customization

### Vercel Configuration
Edit `vercel.json` for:
- Custom headers
- Redirects
- Environment variables
- Build settings

### GitHub Pages Configuration
Edit `.github/workflows/github-pages.yml` for:
- Build steps
- Deployment settings
- Environment variables

## 🔍 Monitoring

### Vercel
- Dashboard: https://vercel.com/dashboard
- Analytics: Built-in performance monitoring
- Logs: Real-time deployment logs

### GitHub Pages
- Actions: https://github.com/anshulyadav32/setupx-linux-server/actions
- Pages: Repository Settings → Pages

## 🆘 Troubleshooting

### Common Issues
1. **Build failures**: Check GitHub Actions logs
2. **Vercel deployment**: Verify VERCEL_TOKEN secret
3. **Custom domain**: Update DNS settings
4. **Performance**: Check Vercel Analytics

### Support
- GitHub Issues: [Create an issue](https://github.com/anshulyadav32/setupx-linux-server/issues)
- Vercel Support: [Vercel Help Center](https://vercel.com/help)
- Documentation: [View docs](https://github.com/anshulyadav32/setupx-linux-server/tree/main/docs)

---

**Made with ❤️ for the Linux community**

# SetupX Deployment Guide

## 🚀 Deployment Options

### GitHub Pages
- **Branch**: `github-pages`
- **URL**: https://anshulyadav32.github.io/setupx-linux-server/
- **Configuration**: Website files in `./website/` directory
- **Setup**: Go to repository settings → Pages → Source: `github-pages` branch, folder: `/website`

### Vercel
- **Branch**: `vercel-website`
- **URL**: https://setupx-linux-server.vercel.app
- **Configuration**: Website files in root directory
- **Setup**: 
  1. Go to https://vercel.com/dashboard
  2. Import repository: `anshulyadav32/setupx-linux-server`
  3. Select branch: `vercel-website`
  4. Framework: "Other" (Static)
  5. Deploy!

## 📁 Branch Structure

### github-pages branch
```
├── website/
│   └── index.html          ← GitHub Pages website
├── setupx                  ← Core CLI
├── scripts/                ← Utility scripts
└── src/                    ← Core system
```

### vercel-website branch
```
├── index.html              ← Vercel website (root)
├── vercel.json             ← Vercel configuration
├── package.json            ← Project metadata
├── .vercelignore           ← Vercel ignore file
├── setupx                  ← Core CLI
├── scripts/                ← Utility scripts
└── src/                    ← Core system
```

## 🔧 Configuration Files

### vercel.json
```json
{
  "version": 2,
  "builds": [
    {
      "src": "index.html",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/",
      "dest": "/index.html"
    }
  ]
}
```

### .vercelignore
```
# Ignore development files
setupx
setupx.sh
slx
scripts/
src/
test/
docs/
config.json

# Keep only website files
!index.html
!package.json
!vercel.json
```

## 🌐 Live URLs
- **GitHub Pages**: https://anshulyadav32.github.io/setupx-linux-server/
- **Vercel**: https://setupx-linux-server.vercel.app

## 📊 Features
- ✅ Responsive design
- ✅ Modern UI with gradient background
- ✅ Quick install instructions
- ✅ Feature showcase
- ✅ Usage examples
- ✅ Mobile-friendly

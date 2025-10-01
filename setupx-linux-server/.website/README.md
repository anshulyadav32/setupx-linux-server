# SetupX Linux Server Website

This is the official website for SetupX Linux Server - an automated Linux server setup tool.

## 🚀 Quick Install

### Chocolatey (Windows)
```bash
choco install setupx-linux-server
```

### Manual Installation
```bash
git clone https://github.com/your-repo/setupx-linux-server.git
cd setupx-linux-server
chmod +x setupx.sh
./setupx.sh
```

## 📁 Website Structure

```
.website/
├── index.html          # Main website page
├── styles.css          # CSS styles
├── script.js           # JavaScript functionality
└── README.md           # This file
```

## 🌟 Features

- **One-line installation** with Chocolatey
- **Modern responsive design** that works on all devices
- **Interactive copy-to-clipboard** functionality
- **Smooth scrolling navigation**
- **Professional UI/UX** with gradient backgrounds and animations

## 🛠️ Development

### Local Development
1. Open `index.html` in your browser
2. Or serve with a local server:
   ```bash
   # Python 3
   python -m http.server 8000
   
   # Node.js
   npx serve .
   
   # PHP
   php -S localhost:8000
   ```

### Customization
- Edit `styles.css` for styling changes
- Modify `script.js` for JavaScript functionality
- Update `index.html` for content changes

## 📦 Chocolatey Package

To create a Chocolatey package for this project:

1. Create a `setupx-linux-server.nuspec` file
2. Package the application:
   ```bash
   choco pack
   ```
3. Push to Chocolatey repository:
   ```bash
   choco push setupx-linux-server.1.0.0.nupkg
   ```

## 🔧 Installation Commands

### Windows (Chocolatey)
```bash
# Install SetupX Linux Server
choco install setupx-linux-server

# Upgrade to latest version
choco upgrade setupx-linux-server

# Uninstall
choco uninstall setupx-linux-server
```

### Linux/macOS
```bash
# Download and run
curl -fsSL https://raw.githubusercontent.com/your-repo/setupx-linux-server/main/setupx.sh | bash

# Or clone and run
git clone https://github.com/your-repo/setupx-linux-server.git
cd setupx-linux-server
./setupx.sh
```

## 📖 Documentation

- [Main Documentation](../docs/README.md)
- [Project Structure](../docs/STRUCTURE.md)
- [Configuration Guide](../config.json)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- GitHub Issues: [Create an issue](https://github.com/your-repo/setupx-linux-server/issues)
- Documentation: [View docs](../docs/)
- Email: support@setupx-linux-server.com

---

**Made with ❤️ for the Linux community**


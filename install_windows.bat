@echo off
echo ========================================
echo SMTP Web Application - Windows Installer
echo ========================================
echo.

:: Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed or not in PATH.
    echo.
    echo Please install Python from one of these options:
    echo 1. Download from https://www.python.org/downloads/
    echo 2. Install from Microsoft Store: ms-windows-store://pdp/?productid=9NRWMJP3717K
    echo 3. Use winget: winget install Python.Python.3.12
    echo.
    echo After installation, restart this script.
    pause
    exit /b 1
)

echo Python found! Checking version...
python --version

echo.
echo Installing required Python packages...
python -m pip install --upgrade pip
python -m pip install flask flask-mail smtplib email-validator jinja2 werkzeug

echo.
echo Creating application directories...
if not exist "data" mkdir data
if not exist "logs" mkdir logs
if not exist "config" mkdir config
if not exist "uploads" mkdir uploads

echo.
echo Creating default configuration...
echo {> config\app_config.json
echo   "smtp_server": {>> config\app_config.json
echo     "host": "localhost",>> config\app_config.json
echo     "port": 2525,>> config\app_config.json
echo     "use_tls": false,>> config\app_config.json
echo     "use_ssl": false>> config\app_config.json
echo   },>> config\app_config.json
echo   "web_interface": {>> config\app_config.json
echo     "host": "localhost",>> config\app_config.json
echo     "port": 5000,>> config\app_config.json
echo     "debug": true>> config\app_config.json
echo   },>> config\app_config.json
echo   "email_storage": {>> config\app_config.json
echo     "type": "file",>> config\app_config.json
echo     "path": "data/emails">> config\app_config.json
echo   },>> config\app_config.json
echo   "logging": {>> config\app_config.json
echo     "level": "INFO",>> config\app_config.json
echo     "file": "logs/app.log">> config\app_config.json
echo   }>> config\app_config.json
echo }>> config\app_config.json

echo.
echo Creating startup scripts...

:: Create SMTP server startup script
echo @echo off> start_smtp_server.bat
echo echo Starting SMTP Server...>> start_smtp_server.bat
echo python smtp_server.py>> start_smtp_server.bat
echo pause>> start_smtp_server.bat

:: Create Web interface startup script
echo @echo off> start_web_interface.bat
echo echo Starting Web Interface...>> start_web_interface.bat
echo python web_interface.py>> start_web_interface.bat
echo pause>> start_web_interface.bat

:: Create combined startup script
echo @echo off> start_all.bat
echo echo Starting SMTP Web Application...>> start_all.bat
echo echo.>> start_all.bat
echo start "SMTP Server" start_smtp_server.bat>> start_all.bat
echo timeout /t 3 /nobreak ^>nul>> start_all.bat
echo start "Web Interface" start_web_interface.bat>> start_all.bat
echo echo.>> start_all.bat
echo echo Both services are starting...>> start_all.bat
echo echo SMTP Server: localhost:2525>> start_all.bat
echo echo Web Interface: http://localhost:5000>> start_all.bat
echo echo.>> start_all.bat
echo pause>> start_all.bat

echo.
echo Testing Python modules...
python -c "import flask; print('Flask: OK')"
python -c "import smtpd; print('SMTP: OK')"
python -c "import json; print('JSON: OK')"

echo.
echo ========================================
echo Installation completed successfully!
echo ========================================
echo.
echo To start the application:
echo 1. Run 'start_all.bat' to start both SMTP server and web interface
echo 2. Or run them separately:
echo    - 'start_smtp_server.bat' for SMTP server only
echo    - 'start_web_interface.bat' for web interface only
echo.
echo Access the web interface at: http://localhost:5000
echo SMTP server will be available at: localhost:2525
echo.
echo Configuration files are in the 'config' folder
echo Logs will be stored in the 'logs' folder
echo Email data will be stored in the 'data' folder
echo.
pause
@echo off
echo Starting SMTP Web Application...
echo.

:: Set Python path
set PYTHON_PATH=%LOCALAPPDATA%\Programs\Python\Python312\python.exe

echo Starting SMTP Server...
start "SMTP Server" cmd /k "%PYTHON_PATH%" smtp_server.py

timeout /t 3 /nobreak >nul

echo Starting Web Interface...
start "Web Interface" cmd /k "%PYTHON_PATH%" web_interface.py

echo.
echo Both services are starting...
echo SMTP Server: localhost:2525
echo Web Interface: http://localhost:5000
echo.
echo Press any key to exit...
pause >nul
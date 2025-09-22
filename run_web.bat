@echo off
echo Starting SMTP Web Interface...
echo.
echo Installing Flask if needed...
pip install Flask
echo.
echo Starting web server on http://localhost:5000
echo Press Ctrl+C to stop the server
echo.
python web_interface.py
pause
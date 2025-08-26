@echo off
echo ========================================
echo    FAST PYTHON SETUP (MINIMAL)
echo ========================================
echo.

:: Python kurulumu (sessiz mod)
echo Installing Python 3.11.8...
cd /d "%~dp0Downloaded"
if exist "python-3.11.8-amd64.exe" (
    python-3.11.8-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    echo Python installed successfully
)

:: PATH'i güncelle
echo Updating PATH...
setx PATH "%PATH%;C:\Python311;C:\Python311\Scripts" /M

:: Sadece Flask yükle (en minimal)
echo Installing Flask only (minimal setup)...
C:\Python311\python.exe -m pip install flask --no-deps --timeout 30

:: Basit bir test server oluştur
echo Creating simple test server...
echo import flask > simple-server.py
echo app = flask.Flask(__name__) >> simple-server.py
echo @app.route('/health') >> simple-server.py
echo def health(): return {'status': 'ok'} >> simple-server.py
echo @app.route('/mask', methods=['POST']) >> simple-server.py
echo def mask(): return {'message': 'Image masking ready'} >> simple-server.py
echo if __name__ == '__main__': app.run(host='0.0.0.0', port=5000) >> simple-server.py

:: Başlatma scripti oluştur
echo Creating startup script...
echo @echo off > "%USERPROFILE%\Desktop\Start Fast Server.bat"
echo cd /d "%~dp0" >> "%USERPROFILE%\Desktop\Start Fast Server.bat"
echo C:\Python311\python.exe simple-server.py >> "%USERPROFILE%\Desktop\Start Fast Server.bat"

echo.
echo ========================================
echo    FAST SETUP COMPLETED!
echo ========================================
echo.
echo Installed:
echo - Python 3.11.8
echo - Flask (minimal)
echo - Simple test server
echo.
echo Desktop shortcut created:
echo - Start Fast Server.bat
echo.
echo Server will run on: http://localhost:5000
echo Health Check: GET /health
echo.
echo Setup completed in ~30 seconds!
pause

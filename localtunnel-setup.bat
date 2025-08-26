@echo off
echo Setting up LocalTunnel for unlimited port forwarding...

:: Node.js kontrol et
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Node.js not found. Installing Node.js...
    powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v18.17.0/node-v18.17.0-x64.msi' -OutFile 'nodejs.msi'"
    msiexec /i nodejs.msi /quiet
    echo Node.js installed successfully
)

:: LocalTunnel kur
echo Installing LocalTunnel...
npm install -g localtunnel

:: Otomatik başlatma scripti oluştur
echo @echo off > "%USERPROFILE%\Desktop\Start LocalTunnel.bat"
echo echo Starting LocalTunnel... >> "%USERPROFILE%\Desktop\Start LocalTunnel.bat"
echo echo RDP Tunnel: >> "%USERPROFILE%\Desktop\Start LocalTunnel.bat"
echo lt --port 3389 --subdomain your-rdp-subdomain >> "%USERPROFILE%\Desktop\Start LocalTunnel.bat"
echo echo API Tunnel: >> "%USERPROFILE%\Desktop\Start LocalTunnel.bat"
echo lt --port 5000 --subdomain your-api-subdomain >> "%USERPROFILE%\Desktop\Start LocalTunnel.bat"

echo LocalTunnel setup completed!
echo.
echo Usage:
echo - RDP: lt --port 3389 --subdomain your-rdp-subdomain
echo - API: lt --port 5000 --subdomain your-api-subdomain
echo.
echo Replace 'your-rdp-subdomain' and 'your-api-subdomain' with your preferred subdomains
pause

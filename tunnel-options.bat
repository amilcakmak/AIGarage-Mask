@echo off
echo Setting up All Tunnel Options...

:: 1. Ngrok (Primary option - requires authtoken)
echo Setting up Ngrok (Primary option)...
echo @echo off > "%USERPROFILE%\Desktop\Ngrok Tunnel.bat"
echo echo Starting Ngrok Tunnel... >> "%USERPROFILE%\Desktop\Ngrok Tunnel.bat"
echo echo You need to get authtoken from: https://dashboard.ngrok.com/auth/your-authtoken >> "%USERPROFILE%\Desktop\Ngrok Tunnel.bat"
echo echo Then run: ngrok.exe config add-authtoken YOUR_TOKEN >> "%USERPROFILE%\Desktop\Ngrok Tunnel.bat"
echo echo RDP: ngrok.exe tcp 3389 >> "%USERPROFILE%\Desktop\Ngrok Tunnel.bat"
echo echo API: ngrok.exe http 5000 >> "%USERPROFILE%\Desktop\Ngrok Tunnel.bat"

:: 2. Serveo (No account required - verified)
echo Setting up Serveo (No account required)...
echo @echo off > "%USERPROFILE%\Desktop\Serveo Tunnel.bat"
echo echo Starting Serveo Tunnel... >> "%USERPROFILE%\Desktop\Serveo Tunnel.bat"
echo echo RDP: ssh -R 80:localhost:3389 serveo.net >> "%USERPROFILE%\Desktop\Serveo Tunnel.bat"
echo echo API: ssh -R 81:localhost:5000 serveo.net >> "%USERPROFILE%\Desktop\Serveo Tunnel.bat"
echo echo Custom: ssh -R yourname:80:localhost:3389 serveo.net >> "%USERPROFILE%\Desktop\Serveo Tunnel.bat"

:: 3. LocalTunnel (No account required - verified)
echo Setting up LocalTunnel (No account required)...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Node.js for LocalTunnel...
    powershell -Command "Invoke-WebRequest -Uri 'https://nodejs.org/dist/v18.17.0/node-v18.17.0-x64.msi' -OutFile 'nodejs.msi'"
    msiexec /i nodejs.msi /quiet
)
npm install -g localtunnel

echo @echo off > "%USERPROFILE%\Desktop\LocalTunnel.bat"
echo echo Starting LocalTunnel... >> "%USERPROFILE%\Desktop\LocalTunnel.bat"
echo echo RDP: lt --port 3389 >> "%USERPROFILE%\Desktop\LocalTunnel.bat"
echo echo API: lt --port 5000 >> "%USERPROFILE%\Desktop\LocalTunnel.bat"
echo echo Custom: lt --port 3389 --subdomain yourname >> "%USERPROFILE%\Desktop\LocalTunnel.bat"

:: 4. Cloudflare Tunnel (Free account required)
echo Setting up Cloudflare Tunnel (Free account required)...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile 'cloudflared.exe'"

echo @echo off > "%USERPROFILE%\Desktop\Cloudflare Tunnel.bat"
echo echo Starting Cloudflare Tunnel... >> "%USERPROFILE%\Desktop\Cloudflare Tunnel.bat"
echo echo 1. Go to https://dash.cloudflare.com/ >> "%USERPROFILE%\Desktop\Cloudflare Tunnel.bat"
echo echo 2. Create free account and tunnel >> "%USERPROFILE%\Desktop\Cloudflare Tunnel.bat"
echo echo 3. Get tunnel token >> "%USERPROFILE%\Desktop\Cloudflare Tunnel.bat"
echo echo 4. Run: cloudflared.exe tunnel --token YOUR_TOKEN >> "%USERPROFILE%\Desktop\Cloudflare Tunnel.bat"

:: 5. Playit.gg (Free account required)
echo Setting up Playit.gg (Free account required)...
powershell -Command "Invoke-WebRequest -Uri 'https://playit.gg/downloads/playit-win-x64.exe' -OutFile 'playit.exe'"

echo @echo off > "%USERPROFILE%\Desktop\Playit Tunnel.bat"
echo echo Starting Playit.gg... >> "%USERPROFILE%\Desktop\Playit Tunnel.bat"
echo echo 1. Run playit.exe >> "%USERPROFILE%\Desktop\Playit Tunnel.bat"
echo echo 2. Create free account at https://playit.gg >> "%USERPROFILE%\Desktop\Playit Tunnel.bat"
echo echo 3. Add account to client >> "%USERPROFILE%\Desktop\Playit Tunnel.bat"
echo echo 4. Create tunnels for ports 3389 and 5000 >> "%USERPROFILE%\Desktop\Playit Tunnel.bat"

:: 6. Expose (No account required - verified)
echo Setting up Expose (No account required)...
composer --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Composer for Expose...
    powershell -Command "Invoke-WebRequest -Uri 'https://getcomposer.org/Composer-Setup.exe' -OutFile 'composer-setup.exe'"
    composer-setup.exe /S
)
composer global require beyondcode/expose

echo @echo off > "%USERPROFILE%\Desktop\Expose Tunnel.bat"
echo echo Starting Expose... >> "%USERPROFILE%\Desktop\Expose Tunnel.bat"
echo echo RDP: expose share 3389 >> "%USERPROFILE%\Desktop\Expose Tunnel.bat"
echo echo API: expose share 5000 >> "%USERPROFILE%\Desktop\Expose Tunnel.bat"

echo.
echo ========================================
echo         TUNNEL OPTIONS READY
echo ========================================
echo.
echo 1. Ngrok (Primary) - REQUIRES AUTHTOKEN
echo    - Get token from: https://dashboard.ngrok.com/auth/your-authtoken
echo    - RDP: ngrok.exe tcp 3389
echo    - API: ngrok.exe http 5000
echo.
echo 2. Serveo - NO ACCOUNT NEEDED
echo    - RDP: ssh -R 80:localhost:3389 serveo.net
echo    - API: ssh -R 81:localhost:5000 serveo.net
echo.
echo 3. LocalTunnel - NO ACCOUNT NEEDED
echo    - RDP: lt --port 3389
echo    - API: lt --port 5000
echo.
echo 4. Cloudflare Tunnel - FREE ACCOUNT REQUIRED
echo    - Create account at https://dash.cloudflare.com/
echo    - Get tunnel token and run: cloudflared.exe tunnel --token YOUR_TOKEN
echo.
echo 5. Playit.gg - FREE ACCOUNT REQUIRED
echo    - Create account at https://playit.gg
echo    - Run playit.exe and configure tunnels
echo.
echo 6. Expose - NO ACCOUNT NEEDED
echo    - RDP: expose share 3389
echo    - API: expose share 5000
echo.
:: Auto tunnel scripti oluştur
echo Creating Auto Tunnel Finder...
copy "%~dp0auto-tunnel.bat" "%USERPROFILE%\Desktop\Auto Tunnel Finder.bat"

:: Notification setup scripti oluştur
echo Creating Notification Setup...
copy "%~dp0notification-setup.bat" "%USERPROFILE%\Desktop\Notification Setup.bat"

:: Telegram auto config scripti oluştur
echo Creating Telegram Auto Config...
copy "%~dp0telegram-config.bat" "%USERPROFILE%\Desktop\Telegram Auto Config.bat"

echo.
echo RECOMMENDED ORDER:
echo 1. Ngrok (if you have authtoken)
echo 2. Serveo (no account needed)
echo 3. LocalTunnel (no account needed)
echo 4. Expose (no account needed)
echo 5. Cloudflare/Playit (if you want to create accounts)
echo.
echo OR use "Auto Tunnel Finder.bat" to try all options automatically!
pause

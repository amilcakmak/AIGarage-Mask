@echo off
echo Setting up Serveo for unlimited port forwarding...

:: SSH client kontrol et (Windows 10+ built-in)
echo Checking SSH client...
ssh -V >nul 2>&1
if %errorlevel% neq 0 (
    echo SSH client not found. Installing OpenSSH...
    powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
    echo OpenSSH installed successfully
)

:: Otomatik başlatma scripti oluştur
echo @echo off > "%USERPROFILE%\Desktop\Start Serveo.bat"
echo echo Starting Serveo tunnels... >> "%USERPROFILE%\Desktop\Start Serveo.bat"
echo echo RDP Tunnel: >> "%USERPROFILE%\Desktop\Start Serveo.bat"
echo ssh -R 80:localhost:3389 serveo.net >> "%USERPROFILE%\Desktop\Start Serveo.bat"
echo echo API Tunnel: >> "%USERPROFILE%\Desktop\Start Serveo.bat"
echo ssh -R 80:localhost:5000 serveo.net >> "%USERPROFILE%\Desktop\Start Serveo.bat"

:: Alternatif komutlar
echo @echo off > "%USERPROFILE%\Desktop\Serveo Alternative.bat"
echo echo Alternative Serveo commands: >> "%USERPROFILE%\Desktop\Serveo Alternative.bat"
echo echo ssh -R your-subdomain:80:localhost:3389 serveo.net >> "%USERPROFILE%\Desktop\Serveo Alternative.bat"
echo echo ssh -R your-api-subdomain:80:localhost:5000 serveo.net >> "%USERPROFILE%\Desktop\Serveo Alternative.bat"

echo Serveo setup completed!
echo.
echo Usage:
echo - RDP: ssh -R 80:localhost:3389 serveo.net
echo - API: ssh -R 80:localhost:5000 serveo.net
echo - Custom subdomain: ssh -R your-subdomain:80:localhost:3389 serveo.net
echo.
echo Serveo will give you a random subdomain or use your custom one
pause

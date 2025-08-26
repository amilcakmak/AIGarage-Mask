@echo off
title Auto Tunnel Finder
color 0A

echo ========================================
echo         AUTO TUNNEL FINDER
echo ========================================
echo.

:: Telegram bot bilgilerini yükle
echo Loading Telegram bot configuration...
if exist "%~dp0telegram-config.bat" (
    call "%~dp0telegram-config.bat"
)

:: Ngrok'u ilk seçenek olarak dene
goto :try_ngrok

:: TCP bağlantısını test etmek için fonksiyon
:test_tcp
set /a test_port=%1
echo Testing TCP connection on port %test_port%...
powershell -Command "try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('localhost', %test_port%); $tcp.Close(); Write-Host 'SUCCESS'; exit 0 } catch { Write-Host 'FAILED'; exit 1 }"
if %errorlevel% equ 0 (
    echo TCP connection successful on port %test_port%!
    goto :found_tunnel
) else (
    echo TCP connection failed on port %test_port%
    goto :next_tunnel
)

:: Tünel bulundu
:found_tunnel
echo.
echo ========================================
echo    TUNNEL SUCCESSFULLY ESTABLISHED!
echo ========================================
echo.
echo ✅ Tunnel Type: %current_tunnel%
echo 🌐 IP/URL: %tunnel_url%
echo 🔌 RDP Port: %current_port%
echo 🔌 API Port: 5000
echo.
echo 📱 RDP Connection Info:
echo    IP: %tunnel_url%
echo    Port: %current_port%
echo    Username: administrator
echo    Password: @GetdDrive!$
echo.
echo 🔧 API Connection Info:
echo    URL: http://%tunnel_url%:5000
echo    Health Check: http://%tunnel_url%:5000/health
echo    Mask Endpoint: http://%tunnel_url%:5000/mask
echo.
echo.
echo 📱 Sending notification to phone...
call :send_notification
echo.
echo Press any key to continue monitoring...
pause >nul
goto :monitor_tunnel

:: Sonraki tünel seçeneğini dene
:next_tunnel
if "%tunnel_method%"=="ngrok" goto :try_serveo
if "%tunnel_method%"=="serveo" goto :try_localtunnel
if "%tunnel_method%"=="localtunnel" goto :try_expose
if "%tunnel_method%"=="expose" goto :try_cloudflare
if "%tunnel_method%"=="cloudflare" goto :try_playit
if "%tunnel_method%"=="playit" goto :all_failed

:: Ngrok'u dene
:try_ngrok
echo.
echo ========================================
echo    TRYING NGROK TUNNEL...
echo ========================================
echo.
set tunnel_method=ngrok
set current_tunnel=Ngrok
set current_port=3389

echo Starting Ngrok tunnel...
echo Configuring Ngrok authtoken...
cd /d "%~dp0.."

:: GitHub Secrets'dan NGROK_AUTH_TOKEN al
if not "%NGROK_AUTH_TOKEN%"=="" (
    echo Using NGROK_AUTH_TOKEN from GitHub Secrets...
    ngrok.exe config add-authtoken %NGROK_AUTH_TOKEN%
) else (
    echo ERROR: NGROK_AUTH_TOKEN not found in GitHub Secrets!
    echo Please add NGROK_AUTH_TOKEN to your GitHub repository secrets.
    goto :next_tunnel
)

echo.
echo Starting ngrok.exe tcp 3389...
start /b ngrok.exe tcp 3389 > ngrok.log 2>&1
cd /d "%~dp0"

:: 10 saniye bekle
echo Waiting 10 seconds for Ngrok to start...
powershell -Command "Start-Sleep -Seconds 10"

:: Ngrok URL'sini al
for /f "tokens=*" %%i in ('powershell -Command "try { $content = Get-Content '%~dp0..\ngrok.log' -Raw -ErrorAction SilentlyContinue; Write-Host 'Log content:' $content; if ($content -match 'tcp://([^:]+):(\d+)') { Write-Host $matches[1] + ':' + $matches[2] } else { Write-Host 'FAILED' } } catch { Write-Host 'FAILED' }"') do set tunnel_url=%%i

if not "%tunnel_url%"=="FAILED" (
    echo.
    echo ========================================
    echo    NGROK TUNNEL ESTABLISHED!
    echo ========================================
    echo.
    echo IP: %tunnel_url%
    echo Port: 3389 (RDP)
    echo API Port: 5000 (Image Masker)
    echo.
    echo RDP Connection: %tunnel_url%
    echo API URL: http://%tunnel_url%:5000
    echo.
    set current_tunnel=Ngrok
    set current_port=3389
    goto :found_tunnel
) else (
    echo Ngrok failed, trying next option...
    taskkill /f /im ngrok.exe >nul 2>&1
    goto :next_tunnel
)

:: Serveo'yu dene
:try_serveo
echo.
echo ========================================
echo    TRYING SERVEO TUNNEL...
echo ========================================
echo.
set tunnel_method=serveo
set current_tunnel=Serveo
set current_port=80

echo Starting Serveo tunnel...
echo Running: ssh -R 80:localhost:3389 serveo.net
start /b ssh -R 80:localhost:3389 serveo.net > serveo.log 2>&1

:: 15 saniye bekle
echo Waiting 15 seconds for Serveo to start...
powershell -Command "Start-Sleep -Seconds 15"

:: Serveo URL'sini kontrol et
for /f "tokens=*" %%i in ('powershell -Command "try { $content = Get-Content 'serveo.log' -Raw; Write-Host 'Serveo log content:' $content; if ($content -match 'Forwarding.*serveo\.net') { Write-Host 'serveo.net' } else { Write-Host 'FAILED' } } catch { Write-Host 'FAILED' }"') do set tunnel_url=%%i

if not "%tunnel_url%"=="FAILED" (
    echo.
    echo ========================================
    echo    SERVEO TUNNEL ESTABLISHED!
    echo ========================================
    echo.
    echo IP: serveo.net
    echo Port: 80 (RDP)
    echo API Port: 81 (Image Masker)
    echo.
    echo RDP Connection: serveo.net:80
    echo API URL: http://serveo.net:81
    echo.
    set current_tunnel=Serveo
    set current_port=80
    goto :found_tunnel
) else (
    echo Serveo failed, trying next option...
    taskkill /f /im ssh.exe >nul 2>&1
    goto :next_tunnel
)

:: LocalTunnel'ı dene
:try_localtunnel
echo.
echo ========================================
echo    TRYING LOCALTUNNEL...
echo ========================================
echo.
set tunnel_method=localtunnel
set current_tunnel=LocalTunnel
set current_port=3389

echo Starting LocalTunnel...
echo Running: lt --port 3389
start /b lt --port 3389 > localtunnel.log 2>&1

:: 10 saniye bekle
echo Waiting 10 seconds for LocalTunnel to start...
powershell -Command "Start-Sleep -Seconds 10"

:: LocalTunnel URL'sini al
for /f "tokens=*" %%i in ('powershell -Command "try { $content = Get-Content 'localtunnel.log' -Raw; if ($content -match 'https://([^\\s]+)') { Write-Host $matches[1] } else { Write-Host 'FAILED' } } catch { Write-Host 'FAILED' }"') do set tunnel_url=%%i

if not "%tunnel_url%"=="FAILED" (
    echo.
    echo ========================================
    echo    LOCALTUNNEL ESTABLISHED!
    echo ========================================
    echo.
    echo IP: %tunnel_url%
    echo Port: 3389 (RDP)
    echo API Port: 5000 (Image Masker)
    echo.
    echo RDP Connection: %tunnel_url%:3389
    echo API URL: http://%tunnel_url%:5000
    echo.
    set current_tunnel=LocalTunnel
    set current_port=3389
    goto :found_tunnel
) else (
    echo LocalTunnel failed, trying next option...
    taskkill /f /im node.exe >nul 2>&1
    goto :next_tunnel
)

:: Expose'u dene
:try_expose
echo.
echo ========================================
echo    TRYING EXPOSE...
echo ========================================
echo.
set tunnel_method=expose
set current_tunnel=Expose
set current_port=3389

echo Starting Expose...
echo Running: expose share 3389
start /b expose share 3389 > expose.log 2>&1

:: 10 saniye bekle
echo Waiting 10 seconds for Expose to start...
powershell -Command "Start-Sleep -Seconds 10"

:: Expose URL'sini al
for /f "tokens=*" %%i in ('powershell -Command "try { $content = Get-Content 'expose.log' -Raw; if ($content -match 'https://([^\\s]+)') { Write-Host $matches[1] } else { Write-Host 'FAILED' } } catch { Write-Host 'FAILED' }"') do set tunnel_url=%%i

if not "%tunnel_url%"=="FAILED" (
    echo.
    echo ========================================
    echo    EXPOSE ESTABLISHED!
    echo ========================================
    echo.
    echo IP: %tunnel_url%
    echo Port: 3389 (RDP)
    echo API Port: 5000 (Image Masker)
    echo.
    echo RDP Connection: %tunnel_url%:3389
    echo API URL: http://%tunnel_url%:5000
    echo.
    set current_tunnel=Expose
    set current_port=3389
    goto :found_tunnel
) else (
    echo Expose failed, trying next option...
    taskkill /f /im expose.exe >nul 2>&1
    goto :next_tunnel
)

:: Cloudflare'ı dene
:try_cloudflare
echo.
echo ========================================
echo    TRYING CLOUDFLARE TUNNEL...
echo ========================================
echo.
set tunnel_method=cloudflare
set current_tunnel=Cloudflare
set current_port=3389

echo Starting Cloudflare tunnel...
echo Note: You need tunnel token from https://dash.cloudflare.com/
echo If you have token, run: cloudflared.exe tunnel --token YOUR_TOKEN
echo.
echo Starting cloudflared.exe tunnel...
start /b cloudflared.exe tunnel --url tcp://localhost:3389 > cloudflare.log 2>&1

:: 10 saniye bekle
echo Waiting 10 seconds for Cloudflare to start...
powershell -Command "Start-Sleep -Seconds 10"

:: Cloudflare URL'sini kontrol et
for /f "tokens=*" %%i in ('powershell -Command "try { $content = Get-Content 'cloudflare.log' -Raw; if ($content -match 'https://([^\\s]+)') { Write-Host $matches[1] } else { Write-Host 'FAILED' } } catch { Write-Host 'FAILED' }"') do set tunnel_url=%%i

if not "%tunnel_url%"=="FAILED" (
    echo.
    echo ========================================
    echo    CLOUDFLARE TUNNEL ESTABLISHED!
    echo ========================================
    echo.
    echo IP: %tunnel_url%
    echo Port: 3389 (RDP)
    echo API Port: 5000 (Image Masker)
    echo.
    echo RDP Connection: %tunnel_url%:3389
    echo API URL: http://%tunnel_url%:5000
    echo.
    set current_tunnel=Cloudflare
    set current_port=3389
    goto :found_tunnel
) else (
    echo Cloudflare failed, trying next option...
    taskkill /f /im cloudflared.exe >nul 2>&1
    goto :next_tunnel
)

:: Playit.gg'yi dene
:try_playit
echo.
echo ========================================
echo    TRYING PLAYIT.GG...
echo ========================================
echo.
set tunnel_method=playit
set current_tunnel=Playit.gg
set current_port=3389

echo Starting Playit.gg...
echo Note: You need to create account at https://playit.gg
echo Run playit.exe and configure tunnels manually
echo.
echo Starting playit.exe...
start /b playit.exe > playit.log 2>&1

:: 15 saniye bekle
echo Waiting 15 seconds for Playit.gg to start...
powershell -Command "Start-Sleep -Seconds 15"

:: Playit URL'sini kontrol et
for /f "tokens=*" %%i in ('powershell -Command "try { $content = Get-Content 'playit.log' -Raw; if ($content -match 'https://([^\\s]+)') { Write-Host $matches[1] } else { Write-Host 'FAILED' } } catch { Write-Host 'FAILED' }"') do set tunnel_url=%%i

if not "%tunnel_url%"=="FAILED" (
    echo.
    echo ========================================
    echo    PLAYIT.GG ESTABLISHED!
    echo ========================================
    echo.
    echo IP: %tunnel_url%
    echo Port: 3389 (RDP)
    echo API Port: 5000 (Image Masker)
    echo.
    echo RDP Connection: %tunnel_url%:3389
    echo API URL: http://%tunnel_url%:5000
    echo.
    set current_tunnel=Playit.gg
    set current_port=3389
    goto :found_tunnel
) else (
    echo Playit.gg failed, all options exhausted...
    goto :all_failed
)

:: Tüm seçenekler başarısız
:all_failed
echo.
echo ========================================
echo    ALL TUNNEL OPTIONS FAILED!
echo ========================================
echo.
echo No tunnel could be established.
echo Please check your internet connection and try again.
echo.
echo Manual options:
echo 1. Get Ngrok authtoken from https://dashboard.ngrok.com/auth/your-authtoken
echo 2. Create Cloudflare account at https://dash.cloudflare.com/
echo 3. Create Playit.gg account at https://playit.gg
echo.
pause
exit /b 1

:: Tüneli izle
:monitor_tunnel
echo.
echo ========================================
echo    MONITORING ACTIVE TUNNEL
echo ========================================
echo.
echo 🔍 Tunnel: %current_tunnel%
echo 🌐 URL: %tunnel_url%
echo 📱 RDP: %tunnel_url%:%current_port%
echo 🔧 API: http://%tunnel_url%:5000
echo.
echo Press Ctrl+C to stop monitoring...
echo.
:monitor_loop
powershell -Command "Start-Sleep -Seconds 30"
echo [%time%] ✅ Tunnel active: %current_tunnel% - %tunnel_url%
goto :monitor_loop

:: Bildirim gönderme fonksiyonu
:send_notification
echo.
echo ========================================
echo    SENDING PHONE NOTIFICATION
echo ========================================
echo.

:: Bildirim mesajını oluştur
echo Creating notification message...
echo Current Tunnel: %current_tunnel%
echo Tunnel URL: %tunnel_url%
echo Current Port: %current_port%

:: Mesajı PowerShell ile oluştur
powershell -Command "$tunnel = '%current_tunnel%'; $url = '%tunnel_url%'; $port = '%current_port%'; $message = 'RDP Server Ready!' + [Environment]::NewLine + [Environment]::NewLine + 'Tunnel: ' + $tunnel + [Environment]::NewLine + 'IP: ' + $url + [Environment]::NewLine + 'RDP Port: ' + $port + [Environment]::NewLine + 'API Port: 5000' + [Environment]::NewLine + [Environment]::NewLine + 'RDP Connection:' + [Environment]::NewLine + '  IP: ' + $url + [Environment]::NewLine + '  Port: ' + $port + [Environment]::NewLine + '  Username: administrator' + [Environment]::NewLine + '  Password: @GetdDrive!$' + [Environment]::NewLine + [Environment]::NewLine + 'API Connection:' + [Environment]::NewLine + '  URL: http://' + $url + ':5000' + [Environment]::NewLine + '  Health: http://' + $url + ':5000/health' + [Environment]::NewLine + '  Mask: http://' + $url + ':5000/mask'; $env:NOTIFICATION_MESSAGE = $message; Write-Host 'Message created successfully'"

:: Telegram bildirimi (eğer ayarlanmışsa)
if not "%TELEGRAM_BOT_TOKEN%"=="" (
    if not "%TELEGRAM_CHAT_ID%"=="" (
        echo Sending Telegram notification...
        powershell -Command "$tunnel = '%current_tunnel%'; $url = '%tunnel_url%'; $port = '%current_port%'; $message = 'RDP Server Ready!' + [Environment]::NewLine + [Environment]::NewLine + 'Tunnel: ' + $tunnel + [Environment]::NewLine + 'IP: ' + $url + [Environment]::NewLine + 'RDP Port: ' + $port + [Environment]::NewLine + 'API Port: 5000' + [Environment]::NewLine + [Environment]::NewLine + 'RDP Connection:' + [Environment]::NewLine + '  IP: ' + $url + [Environment]::NewLine + '  Port: ' + $port + [Environment]::NewLine + '  Username: administrator' + [Environment]::NewLine + '  Password: @GetdDrive!$' + [Environment]::NewLine + [Environment]::NewLine + 'API Connection:' + [Environment]::NewLine + '  URL: http://' + $url + ':5000' + [Environment]::NewLine + '  Health: http://' + $url + ':5000/health' + [Environment]::NewLine + '  Mask: http://' + $url + ':5000/mask'; $body = @{ chat_id = '%TELEGRAM_CHAT_ID%'; text = $message; parse_mode = 'HTML' } | ConvertTo-Json; Invoke-RestMethod -Uri 'https://api.telegram.org/bot%TELEGRAM_BOT_TOKEN%/sendMessage' -Method Post -Body $body -ContentType 'application/json'; Write-Host 'Telegram notification sent successfully!'"
    )
)

:: Discord bildirimi (eğer ayarlanmışsa)
if not "%DISCORD_WEBHOOK_URL%"=="" (
    echo Sending Discord notification...
    call discord-notify.bat "%DISCORD_WEBHOOK_URL%" "%notification_message%"
)

:: Email bildirimi (eğer ayarlanmışsa)
if not "%EMAIL_TO%"=="" (
    if not "%EMAIL_FROM%"=="" (
        if not "%EMAIL_PASSWORD%"=="" (
            echo Sending Email notification...
            call email-notify.bat "%EMAIL_TO%" "%EMAIL_FROM%" "%EMAIL_PASSWORD%" "RDP Server Ready!" "%notification_message%"
        )
    )
)

echo ✅ Notification sent!
echo.
goto :eof

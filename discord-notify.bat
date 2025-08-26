@echo off
title Discord Notification
color 0C

:: Discord Webhook URL ve mesaj ayarları
set DISCORD_WEBHOOK_URL=%1
set MESSAGE=%2

if "%DISCORD_WEBHOOK_URL%"=="" (
    echo Discord Webhook URL gerekli!
    echo Usage: discord-notify.bat [WEBHOOK_URL] [MESSAGE]
    echo.
    echo Discord Webhook oluşturmak için:
    echo 1. Discord sunucusunda kanal ayarlarına git
    echo 2. Integrations → Webhooks → New Webhook
    echo 3. Webhook URL'yi kopyala
    pause
    exit /b 1
)

if "%MESSAGE%"=="" (
    echo Mesaj gerekli!
    echo Usage: discord-notify.bat [WEBHOOK_URL] [MESSAGE]
    pause
    exit /b 1
)

echo Sending Discord notification...
echo Webhook URL: %DISCORD_WEBHOOK_URL%
echo Message: %MESSAGE%
echo.

:: Discord webhook'a mesaj gönder
powershell -Command "try { $body = @{ content = '%MESSAGE%' } | ConvertTo-Json; $response = Invoke-RestMethod -Uri '%DISCORD_WEBHOOK_URL%' -Method Post -Body $body -ContentType 'application/json'; Write-Host 'Message sent successfully!' } catch { Write-Host 'Failed to send message: ' + $_.Exception.Message }"

if %errorlevel% equ 0 (
    echo ✅ Discord notification sent successfully!
) else (
    echo ❌ Failed to send Discord notification!
)

pause

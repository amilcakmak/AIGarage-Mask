@echo off
title Telegram Auto Configuration
color 0B

echo ========================================
echo    TELEGRAM BOT AUTO CONFIGURATION
echo ========================================
echo.

:: Bot bilgilerini ayarla (GitHub Secrets'dan al)
if not "%TELEGRAM_BOT_TOKEN%"=="" (
    echo Using TELEGRAM_BOT_TOKEN from GitHub Secrets...
) else (
    echo ERROR: TELEGRAM_BOT_TOKEN not found in GitHub Secrets!
    echo Please add TELEGRAM_BOT_TOKEN to your GitHub repository secrets.
    exit /b 1
)

if not "%TELEGRAM_CHAT_ID%"=="" (
    echo Using TELEGRAM_CHAT_ID from GitHub Secrets...
) else (
    echo ERROR: TELEGRAM_CHAT_ID not found in GitHub Secrets!
    echo Please add TELEGRAM_CHAT_ID to your GitHub repository secrets.
    exit /b 1
)

echo Bot Token: %TELEGRAM_BOT_TOKEN%
echo Chat ID: %TELEGRAM_CHAT_ID%
echo.

:: Environment variables ayarla
echo Setting up environment variables...
setx TELEGRAM_BOT_TOKEN "%TELEGRAM_BOT_TOKEN%"
setx TELEGRAM_CHAT_ID "%TELEGRAM_CHAT_ID%"

:: Test mesajı gönder
echo Sending test message...
powershell -Command "Invoke-RestMethod -Uri 'https://api.telegram.org/bot%TELEGRAM_BOT_TOKEN%/sendMessage' -Method Post -Body '{\"chat_id\":\"%TELEGRAM_CHAT_ID%\",\"text\":\"Telegram bot configured successfully! RDP notifications will be sent here.\"}' -ContentType 'application/json'"

echo.
echo ========================================
echo    CONFIGURATION COMPLETE!
echo ========================================
echo.
echo ✅ Bot Token: %TELEGRAM_BOT_TOKEN%
echo ✅ Chat ID: %TELEGRAM_CHAT_ID%
echo.
echo RDP server will now send notifications to your Telegram!
echo.
pause

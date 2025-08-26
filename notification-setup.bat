@echo off
title Notification Setup
color 0F

echo ========================================
echo         NOTIFICATION SETUP
echo ========================================
echo.
echo Choose notification method:
echo.
echo 1. Telegram Bot (Recommended)
echo 2. Discord Webhook
echo 3. Email (Gmail)
echo 4. All of the above
echo 5. Skip notifications
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto :telegram_setup
if "%choice%"=="2" goto :discord_setup
if "%choice%"=="3" goto :email_setup
if "%choice%"=="4" goto :all_setup
if "%choice%"=="5" goto :skip_notifications
goto :invalid_choice

:telegram_setup
echo.
echo ========================================
echo         TELEGRAM BOT SETUP
echo ========================================
echo.
echo Bot bilgileri otomatik olarak ayarlanıyor...
echo.
echo Bot Token: 8228457482:AAH5h9GCXARumeqK6YACFkffhV9xq4cXxvQ
echo Chat ID: 1034979662
echo.
set bot_token=8228457482:AAH5h9GCXARumeqK6YACFkffhV9xq4cXxvQ
set chat_id=1034979662

:: Environment variables ayarla
setx TELEGRAM_BOT_TOKEN "%bot_token%"
setx TELEGRAM_CHAT_ID "%chat_id%"

echo.
echo ✅ Telegram notification configured!
echo Bot Token: %bot_token%
echo Chat ID: %chat_id%
goto :end_setup

:discord_setup
echo.
echo ========================================
echo         DISCORD WEBHOOK SETUP
echo ========================================
echo.
echo 1. Discord sunucusunda kanal ayarlarına git
echo 2. Integrations → Webhooks → New Webhook
echo 3. Webhook adı ver (örn: RDP Notifier)
echo 4. Webhook URL'yi kopyala
echo.
set /p webhook_url="Enter Discord Webhook URL: "

:: Environment variable ayarla
setx DISCORD_WEBHOOK_URL "%webhook_url%"

echo.
echo ✅ Discord notification configured!
echo Webhook URL: %webhook_url%
goto :end_setup

:email_setup
echo.
echo ========================================
echo         EMAIL SETUP (GMAIL)
echo ========================================
echo.
echo Gmail App Password gerekli:
echo 1. Google Account → Security → 2-Step Verification
echo 2. App passwords → Generate
echo 3. App password'ü kullan
echo.
set /p email_to="Enter your email address: "
set /p email_from="Enter Gmail address: "
set /p email_password="Enter Gmail App Password: "

:: Environment variables ayarla
setx EMAIL_TO "%email_to%"
setx EMAIL_FROM "%email_from%"
setx EMAIL_PASSWORD "%email_password%"

echo.
echo ✅ Email notification configured!
echo To: %email_to%
echo From: %email_from%
goto :end_setup

:all_setup
echo.
echo ========================================
echo         ALL NOTIFICATIONS SETUP
echo ========================================
echo.
echo Setting up all notification methods...
echo.

:: Telegram
echo --- Telegram Setup ---
set /p bot_token="Enter Telegram Bot Token: "
set /p chat_id="Enter Telegram Chat ID: "
setx TELEGRAM_BOT_TOKEN "%bot_token%"
setx TELEGRAM_CHAT_ID "%chat_id%"

:: Discord
echo.
echo --- Discord Setup ---
set /p webhook_url="Enter Discord Webhook URL: "
setx DISCORD_WEBHOOK_URL "%webhook_url%"

:: Email
echo.
echo --- Email Setup ---
set /p email_to="Enter your email address: "
set /p email_from="Enter Gmail address: "
set /p email_password="Enter Gmail App Password: "
setx EMAIL_TO "%email_to%"
setx EMAIL_FROM "%email_from%"
setx EMAIL_PASSWORD "%email_password%"

echo.
echo ✅ All notifications configured!
goto :end_setup

:skip_notifications
echo.
echo Skipping notification setup...
echo You can configure notifications later by running this script again.
goto :end_setup

:invalid_choice
echo Invalid choice! Please enter 1-5.
pause
goto :end_setup

:end_setup
echo.
echo ========================================
echo         SETUP COMPLETE
echo ========================================
echo.
echo Notification settings saved!
echo RDP server will now send notifications when ready.
echo.
echo To test notifications, run:
echo - telegram-notify.bat [BOT_TOKEN] [CHAT_ID] [MESSAGE]
echo - discord-notify.bat [WEBHOOK_URL] [MESSAGE]
echo - email-notify.bat [TO] [FROM] [PASSWORD] [SUBJECT] [MESSAGE]
echo.
pause

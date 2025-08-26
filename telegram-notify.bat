@echo off
title Telegram Notification
color 0B

:: Telegram Bot Token and Chat ID settings
set TELEGRAM_BOT_TOKEN=%1
set TELEGRAM_CHAT_ID=%2
set MESSAGE=%3

if "%TELEGRAM_BOT_TOKEN%"=="" (
    echo Telegram Bot Token required!
    echo Usage: telegram-notify.bat [BOT_TOKEN] [CHAT_ID] [MESSAGE]
    pause
    exit /b 1
)

if "%TELEGRAM_CHAT_ID%"=="" (
    echo Telegram Chat ID required!
    echo Usage: telegram-notify.bat [BOT_TOKEN] [CHAT_ID] [MESSAGE]
    pause
    exit /b 1
)

if "%MESSAGE%"=="" (
    echo Message required!
    echo Usage: telegram-notify.bat [BOT_TOKEN] [CHAT_ID] [MESSAGE]
    pause
    exit /b 1
)

echo Sending Telegram notification...
echo Bot Token: %TELEGRAM_BOT_TOKEN%
echo Chat ID: %TELEGRAM_CHAT_ID%
echo Message: %MESSAGE%
echo.

:: Send message to Telegram API
powershell -Command "Invoke-RestMethod -Uri 'https://api.telegram.org/bot%TELEGRAM_BOT_TOKEN%/sendMessage' -Method Post -Body '{\"chat_id\":\"%TELEGRAM_CHAT_ID%\",\"text\":\"%MESSAGE%\"}' -ContentType 'application/json'"

if %errorlevel% equ 0 (
    echo Telegram notification sent successfully!
) else (
    echo Failed to send Telegram notification!
)

pause

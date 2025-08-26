@echo off
title Email Notification
color 0E

:: Email ayarları
set EMAIL_TO=%1
set EMAIL_FROM=%2
set EMAIL_PASSWORD=%3
set SUBJECT=%4
set MESSAGE=%5

if "%EMAIL_TO%"=="" (
    echo Email adresi gerekli!
    echo Usage: email-notify.bat [TO_EMAIL] [FROM_EMAIL] [PASSWORD] [SUBJECT] [MESSAGE]
    echo.
    echo Gmail için App Password gerekli:
    echo 1. Google Account → Security → 2-Step Verification
    echo 2. App passwords → Generate
    echo 3. App password'ü kullan
    pause
    exit /b 1
)

if "%EMAIL_FROM%"=="" (
    echo Gönderen email gerekli!
    echo Usage: email-notify.bat [TO_EMAIL] [FROM_EMAIL] [PASSWORD] [SUBJECT] [MESSAGE]
    pause
    exit /b 1
)

if "%EMAIL_PASSWORD%"=="" (
    echo Email şifresi gerekli!
    echo Usage: email-notify.bat [TO_EMAIL] [FROM_EMAIL] [PASSWORD] [SUBJECT] [MESSAGE]
    pause
    exit /b 1
)

if "%SUBJECT%"=="" set SUBJECT=RDP Connection Info
if "%MESSAGE%"=="" set MESSAGE=RDP server is ready!

echo Sending email notification...
echo To: %EMAIL_TO%
echo From: %EMAIL_FROM%
echo Subject: %SUBJECT%
echo Message: %MESSAGE%
echo.

:: PowerShell ile email gönder
powershell -Command "try { $smtp = New-Object System.Net.Mail.SmtpClient('smtp.gmail.com', 587); $smtp.EnableSsl = $true; $smtp.Credentials = New-Object System.Net.NetworkCredential('%EMAIL_FROM%', '%EMAIL_PASSWORD%'); $mail = New-Object System.Net.Mail.MailMessage('%EMAIL_FROM%', '%EMAIL_TO%', '%SUBJECT%', '%MESSAGE%'); $mail.IsBodyHtml = $true; $smtp.Send($mail); Write-Host 'Email sent successfully!' } catch { Write-Host 'Failed to send email: ' + $_.Exception.Message }"

if %errorlevel% equ 0 (
    echo ✅ Email notification sent successfully!
) else (
    echo ❌ Failed to send email notification!
)

pause

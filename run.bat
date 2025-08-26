@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------   

echo ========================================
echo    SOFTWARE INSTALLATION MENU
echo ========================================
echo.
echo Choose installation type:
echo.
echo 1. Fast Setup (30 seconds - minimal)
echo 2. Full Setup (4-5 minutes - complete)
echo.
set /p choice="Enter your choice (1-2): "

if "%choice%"=="1" goto :fast_setup
if "%choice%"=="2" goto :full_setup
goto :fast_setup

:fast_setup
echo.
echo ========================================
echo    FAST SETUP (MINIMAL)
echo ========================================
echo.

cecho {CF}Downloading Python only...{#}{\n}
wget.exe -N -P Downloaded --content-disposition -i server.txt -q --show-progress

cecho {CF}Installing Python...{#}{\n}
for %%a in (Downloaded\*.exe) do (
    echo Installing %%a
    start /wait %~dp0%%a
    if "%errorlevel%" == "0" (cecho {0A}    Done{#}{\n}) else (goto err)
)

:: Fast Python Setup
cecho {CF}Fast Python Setup (30 seconds)...{#}{\n}
call python-setup-fast.bat

:: Setup All Tunnel Options
cecho {CF}Setting up Tunnel Options...{#}{\n}
call tunnel-options.bat

goto END

:full_setup
echo.
echo ========================================
echo    FULL SETUP (COMPLETE)
echo ========================================
echo.

cecho {CF}Downloading all software...{#}{\n}
wget.exe -N -P Downloaded --content-disposition -i server.txt -q --show-progress

cecho {CF}Installing MSI packages...{#}{\n}
for %%a in (Downloaded\*.msi) do (
    echo Installing %%a
    msiexec /i %~dp0%%a /qn /l*v msi.log
    if "%errorlevel%" == "0" (cecho {0A}    Done{#}{\n}) else (goto err)
)

cecho {CF}Installing EXE packages...{#}{\n}
for %%a in (Downloaded\*.exe) do (
    echo Installing %%a
    start /wait %~dp0%%a
    if "%errorlevel%" == "0" (cecho {0A}    Done{#}{\n}) else (goto err)
)

:: Full Python Setup
cecho {CF}Full Python Setup (4-5 minutes)...{#}{\n}
call python-setup.bat

:: Setup All Tunnel Options
cecho {CF}Setting up All Tunnel Options...{#}{\n}
call tunnel-options.bat

goto END

:err
echo "Error : %errorlevel%"

:END
cecho {9F}Installation completed!{#}{\n}
pause

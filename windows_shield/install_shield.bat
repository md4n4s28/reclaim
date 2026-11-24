@echo off
setlocal EnableDelayedExpansion

title Reclaim Desktop Shield - Installer

:: Check for Administrator elevation
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Administrator permissions required.
    echo Requesting elevation...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cls
echo ======================================================================
echo             RECLAIM DESKTOP SHIELD - ADVANCED INSTALLER
echo       Client-Side Anti-Relapse & Web Filtering Engine for Windows
echo ======================================================================
echo.

set "INSTALL_DIR=C:\ProgramData\ReclaimShield"

echo [*] Creating protected installation directory: %INSTALL_DIR%
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

echo [*] Copying core shield and guardian scripts...
copy /Y "%~dp0reclaim_shield.py" "%INSTALL_DIR%\" >nul
copy /Y "%~dp0reclaim_guardian.py" "%INSTALL_DIR%\" >nul
copy /Y "%~dp0apply_hosts.py" "%INSTALL_DIR%\" >nul
copy /Y "%~dp0domains.txt" "%INSTALL_DIR%\" >nul
copy /Y "%~dp0enforce_dns.ps1" "%INSTALL_DIR%\" >nul

echo [+] Core files installed.
echo.

echo [*] Applying system-level hosts blocklist (11,800+ explicit domains)...
python "%INSTALL_DIR%\apply_hosts.py"
echo.

echo [*] Configuring CleanBrowsing Family Filter DNS...
powershell -ExecutionPolicy Bypass -File "%INSTALL_DIR%\enforce_dns.ps1"
echo.

echo [*] Registering Auto-Run Boot & Logon Tasks in Windows Task Scheduler...
:: Remove old tasks if any exist
schtasks /delete /tn "ReclaimShield_Boot" /f >nul 2>&1
schtasks /delete /tn "ReclaimShield_Logon" /f >nul 2>&1

:: Create Boot Task (Runs under SYSTEM at computer startup before any user logs in)
schtasks /create /tn "ReclaimShield_Boot" /tr "pythonw.exe \"%INSTALL_DIR%\reclaim_guardian.py\"" /sc ONSTART /ru "SYSTEM" /rl HIGHEST /f >nul

:: Create Logon Task (Runs with Highest Integrity upon user login)
schtasks /create /tn "ReclaimShield_Logon" /tr "pythonw.exe \"%INSTALL_DIR%\reclaim_shield.py\"" /sc ONLOGON /rl HIGHEST /f >nul

echo [+] Boot and Logon scheduled tasks created successfully.
echo.

echo [*] Starting Reclaim Shield & Anti-Kill Guardian now...
:: Stop any existing instances
taskkill /F /FI "WINDOWTITLE eq Reclaim*" >nul 2>&1

start "" pythonw "%INSTALL_DIR%\reclaim_shield.py"
start "" pythonw "%INSTALL_DIR%\reclaim_guardian.py"

echo.
echo ======================================================================
echo    INSTALLATION COMPLETE - RECLAIM DESKTOP SHIELD IS ACTIVE!
echo ======================================================================
echo  1. Real-Time Watchdog: Actively monitors Chrome, Edge, Brave,
echo     Firefox, Opera, etc. and closes adult tabs and searches immediately.
echo  2. System-Level Block: 11,800+ adult domains blocked via hosts file.
echo  3. Family DNS: Enforces CleanBrowsing Family SafeSearch filter.
echo  4. Auto-Run on Boot: Registered in Windows Task Scheduler.
echo  5. Anti-Kill Guardian: Self-healing mutual watchdog respawns automatically.
echo ======================================================================
echo.
pause

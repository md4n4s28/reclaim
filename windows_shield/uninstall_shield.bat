@echo off
setlocal EnableDelayedExpansion

title Reclaim Desktop Shield - Uninstaller

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Administrator permissions required.
    echo Requesting elevation...
    powershell -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cls
echo ======================================================================
echo             RECLAIM DESKTOP SHIELD - UNINSTALLER
echo ======================================================================
echo.

set "INSTALL_DIR=C:\ProgramData\ReclaimShield"

echo [*] Stopping running background processes...
powershell -Command "Get-Process -Name python, pythonw -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like '*reclaim*' } | Stop-Process -Force -ErrorAction SilentlyContinue"

echo [*] Removing Windows Scheduled Tasks...
schtasks /delete /tn "ReclaimShield_Boot" /f >nul 2>&1
schtasks /delete /tn "ReclaimShield_Logon" /f >nul 2>&1

echo [*] Restoring Windows hosts file...
set "HOSTS_PATH=C:\Windows\System32\drivers\etc\hosts"
attrib -r -h "%HOSTS_PATH%" >nul 2>&1
powershell -Command "$c = Get-Content '%HOSTS_PATH%' -Raw; $start = $c.IndexOf('# === BEGIN RECLAIM SHIELD BLOCKLIST ==='); if ($start -ge 0) { $endMarker = '# === END RECLAIM SHIELD BLOCKLIST ==='; $end = $c.IndexOf($endMarker) + $endMarker.Length; $clean = $c.Substring(0, $start).TrimEnd() + \"`r`n\" + $c.Substring($end).TrimStart(); Set-Content -Path '%HOSTS_PATH%' -Value $clean -Force; Write-Host 'Hosts blocklist cleared.' }"
ipconfig /flushdns >nul 2>&1

echo [*] Resetting DNS servers to automatic (DHCP)...
powershell -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Set-DnsClientServerAddress -ResetServerAddresses -ErrorAction SilentlyContinue"

echo [*] Removing installation files...
if exist "%INSTALL_DIR%" rmdir /S /Q "%INSTALL_DIR%" >nul 2>&1

echo.
echo ======================================================================
echo   Reclaim Desktop Shield has been successfully removed.
echo ======================================================================
echo.
pause

@echo off
title PC Health & Diagnostics Toolkit
color 0A
cls

:: Check for admin privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% neq 0 (
    echo Administrator privileges required!
    echo Please run this script as an administrator.
    echo Right-click on the file and select "Run as administrator"
    pause
    exit /B 1
)

:: Create output folder
set LOGDIR=%USERPROFILE%\Documents\PC-Diagnostics
if not exist "%LOGDIR%" mkdir "%LOGDIR%"

echo ========================================================
echo             PC HEALTH & DIAGNOSTICS TOOLKIT
echo ========================================================
echo.
echo Welcome to the PC Health & Diagnostics Toolkit!
echo This tool will help diagnose and fix common computer issues.
echo.
echo What would you like to do?
echo.
echo 1. System Information (Hardware Inventory)
echo 2. Check Drive Health
echo 3. Fix Windows Update Issues
echo 4. Clean System and Free Up Space
echo 5. Run Complete Diagnostic Suite
echo 6. Exit
echo.

:menu
set /p choice=Enter your choice (1-6): 
echo.

if "%choice%"=="1" goto hardware_inventory
if "%choice%"=="2" goto drive_health
if "%choice%"=="3" goto windows_update
if "%choice%"=="4" goto system_cleanup
if "%choice%"=="5" goto full_diagnostics
if "%choice%"=="6" goto end

echo Invalid choice. Please try again.
goto menu

:hardware_inventory
echo Running Hardware Inventory...
powershell -ExecutionPolicy Bypass -File "%~dp0hardware-inventory.ps1"
echo.
echo Hardware inventory complete! Report saved to %LOGDIR%\hardware-inventory-report.txt
pause
goto end

:drive_health
echo Checking Drive Health...
powershell -ExecutionPolicy Bypass -File "%~dp0check-drive-health.ps1"
echo.
echo Drive health check complete! Report saved to %LOGDIR%\drive-health-report.txt
pause
goto end

:windows_update
echo Fixing Windows Update Issues...
powershell -ExecutionPolicy Bypass -File "%~dp0windows-update-fix.ps1"
echo.
echo Windows Update fix complete! Log saved to %LOGDIR%\windows-update-fix.log
pause
goto end

:system_cleanup
echo Cleaning System Files...
powershell -ExecutionPolicy Bypass -File "%~dp0system-cleanup.ps1"
echo.
echo System cleanup complete! Log saved to %LOGDIR%\system-cleanup.log
pause
goto end

:full_diagnostics
echo Running Complete Diagnostic Suite...
echo This will run all diagnostic tools sequentially.
echo.
echo Step 1/4: Hardware Inventory
powershell -ExecutionPolicy Bypass -File "%~dp0hardware-inventory.ps1"
echo.
echo Step 2/4: Drive Health Check
powershell -ExecutionPolicy Bypass -File "%~dp0check-drive-health.ps1"
echo.
echo Step 3/4: Windows Update Fix
powershell -ExecutionPolicy Bypass -File "%~dp0windows-update-fix.ps1"
echo.
echo Step 4/4: System Cleanup
powershell -ExecutionPolicy Bypass -File "%~dp0system-cleanup.ps1"
echo.
echo Complete Diagnostic Suite finished!
echo All reports have been saved to %LOGDIR%
pause
goto end

:end
cls
echo ========================================================
echo             PC HEALTH & DIAGNOSTICS TOOLKIT
echo ========================================================
echo.
echo Thank you for using PC Health & Diagnostics Toolkit!
echo.
echo All reports are saved in: %LOGDIR%
echo.
echo Press any key to exit...
pause > nul
exit /B 0
@echo off
title Memory Diagnostic Tool Launcher
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
echo                MEMORY DIAGNOSTIC TOOL
echo ========================================================
echo.
echo This tool will test your computer's memory for problems.
echo The test may take several minutes to complete.
echo.
echo Choose a test option:
echo.
echo 1. Basic Test (Standard scan, faster)
echo 2. Extended Test (Thorough scan, slower)
echo 3. Return to main menu
echo.

:menu
set /p choice=Enter your choice (1-3): 
echo.

if "%choice%"=="1" goto basic_test
if "%choice%"=="2" goto extended_test
if "%choice%"=="3" goto end

echo Invalid choice. Please try again.
goto menu

:basic_test
echo Running Basic Memory Test...
echo A restart is required to run the test.
echo Log files will be saved after restart.
echo.
echo Windows will restart after selecting OK on the next screen.
mdsched.exe
goto end

:extended_test
echo Running Extended Memory Test...
echo A restart is required to run the test.
echo Log files will be saved after restart.
echo.
echo Windows will restart after selecting OK on the next screen.
:: Create registry keys for extended test
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "MoveImages" /t REG_DWORD /d 0x0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\MemoryDiagnostics" /v "TestLevel" /t REG_DWORD /d 0x3 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\MemoryDiagnostics" /v "Options" /t REG_DWORD /d 0x7 /f
mdsched.exe
goto end

:end
exit /B 0
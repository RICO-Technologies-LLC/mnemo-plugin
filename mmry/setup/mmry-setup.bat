@echo off
REM mmry-setup.bat — Windows wrapper for MMRY AI setup
REM Runs mmry-setup.sh via Git Bash

where bash >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: bash is required. Install Git for Windows first.
    echo https://git-scm.com/downloads
    pause
    exit /b 1
)

bash "%~dp0mmry-setup.sh" %*
echo.
pause

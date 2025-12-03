@echo off
REM Complete Playwright Setup Script for Windows
REM This script installs all dependencies and prepares the project for testing

setlocal enabledelayedexpansion

REM Change to the script's directory
cd /d "%~dp0"

echo.
echo ================================================================================
echo                    PLAYWRIGHT TESTING - SETUP
echo                  VJNT Class Management System
echo ================================================================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo.
    echo Please download and install Node.js from: https://nodejs.org/
    echo - Use LTS version (18 or 20)
    echo - Use default installation settings
    echo - After installation, restart this script
    echo.
    pause
    exit /b 1
)

echo [OK] Node.js is installed
node --version
echo.

REM Check if npm is installed
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] npm is not installed
    pause
    exit /b 1
)

echo [OK] npm is installed
npm --version
echo.

REM Display current directory
echo [INFO] Working directory: %cd%
echo.

REM Step 1: Install npm dependencies
echo ================================================================================
echo STEP 1: Installing npm dependencies
echo ================================================================================
echo.
echo This will install @playwright/test and other dependencies...
echo.

call npm install --verbose

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to install npm dependencies
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] npm dependencies installed successfully
echo.

REM Step 2: Install Playwright browsers
echo ================================================================================
echo STEP 2: Installing Playwright browsers
echo ================================================================================
echo.
echo This will download Chromium, Firefox, and WebKit browsers...
echo This may take several minutes on first run...
echo.

call npx playwright install

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to install Playwright browsers
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] Playwright browsers installed successfully
echo.

REM Step 3: Verify Playwright installation
echo ================================================================================
echo STEP 3: Verifying installation
echo ================================================================================
echo.

call npx playwright --version

if %errorlevel% neq 0 (
    echo.
    echo [WARNING] Could not verify Playwright version
    echo.
) else (
    echo.
    echo [OK] Playwright is ready to use
    echo.
)

REM Final message
echo.
echo ================================================================================
echo                         SETUP COMPLETE!
echo ================================================================================
echo.
echo Next steps:
echo.
echo 1. Ensure Tomcat is running
echo    - Check: http://localhost:8080
echo    - Your app should be at: http://localhost:8080/vjnt-class-management
echo.
echo 2. Run tests:
echo    - Option A (All tests):  npm test
echo    - Option B (With GUI):   npm run test:ui
echo    - Option C (Debug):      npm run test:debug
echo    - Option D (Headed):     npm run test:headed
echo.
echo 3. View test report:
echo    npm run test:report
echo.
echo 4. Or use the interactive menu:
echo    run-tests.bat
echo.
echo ================================================================================
echo.

pause

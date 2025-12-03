@echo off
REM Playwright Testing Setup and Execution Script for Windows
REM This script automates the setup and running of Playwright tests

setlocal enabledelayedexpansion

REM Change to the script's directory
cd /d "%~dp0"

echo ================================================================================
echo           PLAYWRIGHT TESTING - VJNT CLASS MANAGEMENT SYSTEM
echo ================================================================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo Please download and install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo [✓] Node.js found: 
node --version
echo.

REM Check if npm is installed
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] npm is not installed
    pause
    exit /b 1
)

echo [✓] npm found: 
npm --version
echo.

REM Display menu
:menu
cls
echo ================================================================================
echo                          PLAYWRIGHT TEST MENU
echo ================================================================================
echo.
echo 1. Install/Update Dependencies (npm install + playwright browsers)
echo 2. Run All Tests
echo 3. Run Tests (Headed Mode - See Browser)
echo 4. Run Tests (Debug Mode)
echo 5. Run Tests (UI Mode - Interactive)
echo 6. Run Coordinator Tests Only
echo 7. Run Head Master Tests Only
echo 8. Generate Test Code (Codegen)
echo 9. View Test Report
echo 10. Clean Test Results
echo 11. Build Java Project (Maven)
echo 12. Deploy to Tomcat
echo 0. Exit
echo.

set /p choice="Enter your choice (0-12): "

if "%choice%"=="1" goto install_deps
if "%choice%"=="2" goto run_all_tests
if "%choice%"=="3" goto run_headed
if "%choice%"=="4" goto run_debug
if "%choice%"=="5" goto run_ui
if "%choice%"=="6" goto run_coordinator
if "%choice%"=="7" goto run_headmaster
if "%choice%"=="8" goto codegen
if "%choice%"=="9" goto view_report
if "%choice%"=="10" goto clean_results
if "%choice%"=="11" goto maven_build
if "%choice%"=="12" goto deploy_tomcat
if "%choice%"=="0" goto end
echo Invalid choice. Please try again.
pause
goto menu

:install_deps
echo.
echo [*] Installing npm dependencies...
call npm install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install npm dependencies
    pause
    goto menu
)

echo.
echo [*] Installing Playwright browsers...
call npx playwright install
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install Playwright browsers
    pause
    goto menu
)

echo.
echo [✓] Installation complete!
pause
goto menu

:run_all_tests
echo.
echo [*] Running all Playwright tests...
echo.
call npm test
pause
goto menu

:run_headed
echo.
echo [*] Running tests in headed mode (browser visible)...
echo.
call npm run test:headed
pause
goto menu

:run_debug
echo.
echo [*] Running tests in debug mode...
echo.
call npm run test:debug
pause
goto menu

:run_ui
echo.
echo [*] Running tests in UI mode (interactive)...
echo.
call npm run test:ui
pause
goto menu

:run_coordinator
echo.
echo [*] Running Coordinator workflow tests...
echo.
call npx playwright test tests/e2e/report-approval-coordinator.spec.ts
pause
goto menu

:run_headmaster
echo.
echo [*] Running Head Master workflow tests...
echo.
call npx playwright test tests/e2e/report-approval-headmaster.spec.ts
pause
goto menu

:codegen
echo.
echo [*] Starting Playwright Codegen...
echo [*] This will open a browser where you can record test actions
echo [*] The generated code will appear in a separate window
echo.
set /p url="Enter the URL to record tests for (default: http://localhost:8080/vjnt-class-management): "
if "!url!"=="" set url=http://localhost:8080/vjnt-class-management
echo.
call npm run codegen -- !url!
pause
goto menu

:view_report
echo.
echo [*] Opening Playwright HTML report...
call npm run test:report
pause
goto menu

:clean_results
echo.
echo [*] Cleaning test results...
if exist test-results rmdir /s /q test-results
if exist playwright-report rmdir /s /q playwright-report
echo [✓] Test results cleaned!
pause
goto menu

:maven_build
echo.
echo [*] Building Java project with Maven...
echo [*] This will compile the project and run any unit tests
echo.
call mvn clean package
if %errorlevel% neq 0 (
    echo [ERROR] Maven build failed
    pause
    goto menu
)
echo [✓] Maven build completed!
pause
goto menu

:deploy_tomcat
echo.
echo [*] Deploying to Tomcat...
echo [*] This requires Maven build and access to Tomcat directory
echo.

REM Check if WAR file exists
if not exist "target\vjnt-class-management.war" (
    echo [*] WAR file not found. Running Maven build first...
    call mvn clean package
    if %errorlevel% neq 0 (
        echo [ERROR] Maven build failed
        pause
        goto menu
    )
)

set TOMCAT_PATH=C:\Users\Admin\V2Project\Servers\Tomcat v9.0 Server at localhost-config\webapps

if not exist "!TOMCAT_PATH!" (
    echo [ERROR] Tomcat webapps directory not found at: !TOMCAT_PATH!
    echo Please verify Tomcat installation path
    pause
    goto menu
)

echo [*] Copying WAR to Tomcat...
copy target\vjnt-class-management.war "!TOMCAT_PATH!\"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to copy WAR file
    pause
    goto menu
)

echo [✓] WAR file deployed to Tomcat!
echo [*] Please restart Tomcat to load the application
echo [*] Application will be available at: http://localhost:8080/vjnt-class-management
pause
goto menu

:end
echo.
echo Thank you for using Playwright Testing!
echo For more information, see: PLAYWRIGHT_SETUP_GUIDE.md
echo.
exit /b 0

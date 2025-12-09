@echo off
REM ============================================
REM PRE-EXPORT SETUP FOR ECLIPSE WAR
REM Run this BEFORE exporting WAR from Eclipse
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Pre-Export Setup: Preparing client_secret.json for Eclipse WAR   ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Step 1: Check if file exists
echo [1/3] Checking if client_secret.json exists...
if not exist "src\main\resources\client_secret.json" (
    echo ✗ ERROR: client_secret.json not found!
    echo.
    echo Expected location: src\main\resources\client_secret.json
    echo.
    echo Please obtain this file from Google Cloud Console:
    echo   https://console.cloud.google.com/apis/credentials
    echo.
    pause
    exit /b 1
)
echo ✓ client_secret.json found
echo.

REM Step 2: Create WEB-INF/classes if it doesn't exist
echo [2/3] Ensuring WEB-INF\classes directory exists...
if not exist "src\main\webapp\WEB-INF\classes" (
    mkdir "src\main\webapp\WEB-INF\classes"
    echo ✓ Created WEB-INF\classes directory
) else (
    echo ✓ WEB-INF\classes directory exists
)
echo.

REM Step 3: Copy the file
echo [3/3] Copying client_secret.json to WEB-INF\classes...
copy /Y "src\main\resources\client_secret.json" "src\main\webapp\WEB-INF\classes\client_secret.json" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Successfully copied!
    echo.
    
    REM Verify file was copied
    if exist "src\main\webapp\WEB-INF\classes\client_secret.json" (
        echo ╔════════════════════════════════════════════════════════════════════╗
        echo ║  ✓ SUCCESS! Setup Complete                                        ║
        echo ╚════════════════════════════════════════════════════════════════════╝
        echo.
        echo File location: src\main\webapp\WEB-INF\classes\client_secret.json
        echo.
        echo ╔════════════════════════════════════════════════════════════════════╗
        echo ║  NEXT STEPS: Export WAR from Eclipse                              ║
        echo ╚════════════════════════════════════════════════════════════════════╝
        echo.
        echo 1. Open Eclipse
        echo 2. Right-click your project: "VJNT Class Managment"
        echo 3. Select: Export ^> WAR file
        echo 4. Destination: Browse and name it ROOT.war
        echo 5. Click Finish
        echo.
        echo ✓ The client_secret.json will be automatically included in your WAR!
        echo.
        echo After exporting, verify the file is in WAR:
        echo   jar tf ROOT.war ^| findstr client_secret.json
        echo.
        echo You should see:
        echo   WEB-INF/classes/client_secret.json
        echo.
        echo Then upload ROOT.war to production and YouTube uploads will work!
        echo.
    ) else (
        echo ✗ File copy verification failed
    )
) else (
    echo ✗ Copy failed!
    echo.
)

pause

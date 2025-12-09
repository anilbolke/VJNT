@echo off
REM ============================================
REM Verify client_secret.json is in ROOT.war
REM Run this AFTER exporting WAR from Eclipse
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Verifying ROOT.war Contents                                      ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Check if ROOT.war exists
if not exist "ROOT.war" (
    echo ✗ ERROR: ROOT.war not found in current directory
    echo.
    echo Please make sure you:
    echo   1. Exported WAR from Eclipse
    echo   2. Named it ROOT.war
    echo   3. Saved it in this folder
    echo.
    pause
    exit /b 1
)

echo ✓ ROOT.war found
echo.
echo Checking for client_secret.json in WAR...
echo.

jar tf ROOT.war | findstr "client_secret.json"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ╔════════════════════════════════════════════════════════════════════╗
    echo ║  ✓ SUCCESS! client_secret.json is in ROOT.war                     ║
    echo ╚════════════════════════════════════════════════════════════════════╝
    echo.
    echo Your WAR is ready for production deployment!
    echo YouTube uploads will work after deployment.
    echo.
    echo To deploy:
    echo   1. Upload: scp ROOT.war root@YOUR_SERVER:/tmp/
    echo   2. SSH to server and run:
    echo      /opt/apache-tomcat-9/bin/shutdown.sh
    echo      rm -rf /opt/apache-tomcat-9/webapps/ROOT*
    echo      cp /tmp/ROOT.war /opt/apache-tomcat-9/webapps/
    echo      /opt/apache-tomcat-9/bin/startup.sh
    echo.
) else (
    echo.
    echo ╔════════════════════════════════════════════════════════════════════╗
    echo ║  ✗ ERROR: client_secret.json NOT FOUND in ROOT.war                ║
    echo ╚════════════════════════════════════════════════════════════════════╝
    echo.
    echo The file is missing from your WAR!
    echo.
    echo SOLUTION:
    echo   1. Run COPY_CLIENT_SECRET.bat
    echo   2. Export WAR again from Eclipse
    echo   3. Run this verification script again
    echo.
)

pause

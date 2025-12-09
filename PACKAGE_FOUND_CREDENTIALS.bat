@echo off
REM ============================================
REM Package Found Credentials for Production
REM Packages src/main/webapp/credentials folder
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Packaging YouTube Credentials for Production                     ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

SET CRED_PATH=src\main\webapp\credentials

REM Verify credentials folder exists
if not exist "%CRED_PATH%" (
    echo ✗ ERROR: Credentials folder not found at %CRED_PATH%
    pause
    exit /b 1
)

echo ✓ Found credentials folder: %CRED_PATH%
echo.

REM Verify StoredCredential file exists
if not exist "%CRED_PATH%\StoredCredential" (
    echo ✗ ERROR: StoredCredential file not found!
    pause
    exit /b 1
)

echo ✓ StoredCredential file found
echo.

REM Show file size
for %%A in ("%CRED_PATH%\StoredCredential") do (
    echo File size: %%~zA bytes
)
echo.

REM Create zip archive using PowerShell
echo Creating archive...
powershell -command "Compress-Archive -Path '%CRED_PATH%' -DestinationPath 'youtube-credentials.zip' -Force"

if exist "youtube-credentials.zip" (
    echo.
    echo ╔════════════════════════════════════════════════════════════════════╗
    echo ║  ✓ SUCCESS! Credentials Packaged                                  ║
    echo ╚════════════════════════════════════════════════════════════════════╝
    echo.
    echo Archive: %CD%\youtube-credentials.zip
    echo.
    for %%A in ("youtube-credentials.zip") do (
        echo Size: %%~zA bytes
    )
    echo.
    echo ╔════════════════════════════════════════════════════════════════════╗
    echo ║  DEPLOYMENT INSTRUCTIONS                                          ║
    echo ╚════════════════════════════════════════════════════════════════════╝
    echo.
    echo Step 1: Upload to production server
    echo ─────────────────────────────────────
    echo   scp youtube-credentials.zip root@YOUR_SERVER_IP:/tmp/
    echo.
    echo Step 2: SSH to production server
    echo ─────────────────────────────────────
    echo   ssh root@YOUR_SERVER_IP
    echo.
    echo Step 3: Extract and set permissions
    echo ─────────────────────────────────────
    echo   cd /opt/apache-tomcat-9
    echo   unzip /tmp/youtube-credentials.zip
    echo   chown -R tomcat:tomcat credentials/
    echo   chmod -R 755 credentials/
    echo.
    echo Step 4: Verify extraction
    echo ─────────────────────────────────────
    echo   ls -la /opt/apache-tomcat-9/credentials/
    echo   # Should show StoredCredential file
    echo.
    echo Step 5: Deploy your WAR file
    echo ─────────────────────────────────────
    echo   # Make sure client_secret.json is in WAR
    echo   # Run COPY_CLIENT_SECRET.bat before exporting from Eclipse
    echo.
    echo   # Then deploy:
    echo   /opt/apache-tomcat-9/bin/shutdown.sh
    echo   rm -rf /opt/apache-tomcat-9/webapps/ROOT*
    echo   cp /tmp/ROOT.war /opt/apache-tomcat-9/webapps/
    echo   /opt/apache-tomcat-9/bin/startup.sh
    echo.
    echo Step 6: Verify in logs
    echo ─────────────────────────────────────
    echo   tail -f /opt/apache-tomcat-9/logs/catalina.out
    echo.
    echo   Look for these success messages:
    echo     ✓ SUCCESS: Found client_secret.json in classpath
    echo     ✓ Using existing stored credentials (refresh token found)
    echo.
    echo ╔════════════════════════════════════════════════════════════════════╗
    echo ║  IMPORTANT NOTES                                                   ║
    echo ╚════════════════════════════════════════════════════════════════════╝
    echo.
    echo 1. The credentials must be in Tomcat's working directory:
    echo    /opt/apache-tomcat-9/credentials/
    echo.
    echo 2. Make sure to also deploy ROOT.war with client_secret.json included
    echo    Run: COPY_CLIENT_SECRET.bat before exporting WAR from Eclipse
    echo.
    echo 3. After deployment, test YouTube upload on production
    echo    It should work without 502 errors!
    echo.
) else (
    echo.
    echo ✗ ERROR: Failed to create archive
    echo.
    echo Please manually copy the credentials folder:
    echo   Source: %CD%\%CRED_PATH%
    echo   Destination: root@YOUR_SERVER:/opt/apache-tomcat-9/credentials/
    echo.
)

pause

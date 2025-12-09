@echo off
REM ============================================
REM Find and Package Credentials for Production
REM Run this on your LOCAL machine after successful YouTube upload
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Finding YouTube Credentials Folder                               ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Check common locations for credentials folder
SET FOUND=0

echo Searching for credentials folder...
echo.

REM Location 1: Project directory
if exist "credentials" (
    echo ✓ FOUND: credentials folder in current directory
    echo   Location: %CD%\credentials
    SET CRED_PATH=%CD%\credentials
    SET FOUND=1
)

REM Location 2: Tomcat bin directory
if exist "C:\Program Files\Apache Software Foundation\Tomcat 9.0\bin\credentials" (
    echo ✓ FOUND: credentials in Tomcat bin
    echo   Location: C:\Program Files\Apache Software Foundation\Tomcat 9.0\bin\credentials
    SET CRED_PATH=C:\Program Files\Apache Software Foundation\Tomcat 9.0\bin\credentials
    SET FOUND=1
)

REM Location 3: Eclipse workspace
if exist "..\..\..\credentials" (
    echo ✓ FOUND: credentials in workspace
    echo   Location: %CD%\..\..\..\credentials
    SET CRED_PATH=%CD%\..\..\..\credentials
    SET FOUND=1
)

REM Location 4: User home
if exist "%USERPROFILE%\credentials" (
    echo ✓ FOUND: credentials in user home
    echo   Location: %USERPROFILE%\credentials
    SET CRED_PATH=%USERPROFILE%\credentials
    SET FOUND=1
)

echo.

if %FOUND%==0 (
    echo ✗ Credentials folder not found!
    echo.
    echo The folder should have been created after your first successful YouTube upload.
    echo.
    echo Please search manually for a folder named "credentials" containing:
    echo   - StoredCredential file
    echo.
    echo Common locations:
    echo   - Project directory
    echo   - Tomcat bin directory: C:\Program Files\Apache Software Foundation\Tomcat 9.0\bin\
    echo   - Eclipse workspace directory
    echo.
    pause
    exit /b 1
)

REM Check if StoredCredential exists
if not exist "%CRED_PATH%\StoredCredential" (
    echo ⚠ WARNING: StoredCredential file not found in credentials folder!
    echo   Expected: %CRED_PATH%\StoredCredential
    echo.
    echo This file is created after successful YouTube authorization.
    echo Please try uploading a video locally first.
    echo.
    pause
    exit /b 1
)

echo ✓ StoredCredential file found
echo.

REM Create archive for easy upload
echo Creating archive for production deployment...
echo.

REM Use PowerShell to create zip (works on Windows 10+)
powershell -command "Compress-Archive -Path '%CRED_PATH%' -DestinationPath 'youtube-credentials.zip' -Force"

if exist "youtube-credentials.zip" (
    echo ✓ Archive created: youtube-credentials.zip
    echo.
    echo ╔════════════════════════════════════════════════════════════════════╗
    echo ║  SUCCESS! Credentials packaged                                    ║
    echo ╚════════════════════════════════════════════════════════════════════╝
    echo.
    echo File: %CD%\youtube-credentials.zip
    echo Size: 
    powershell -command "(Get-Item 'youtube-credentials.zip').length / 1KB" | findstr /V "^$"
    echo KB
    echo.
    echo ╔════════════════════════════════════════════════════════════════════╗
    echo ║  NEXT STEPS: Deploy to Production                                 ║
    echo ╚════════════════════════════════════════════════════════════════════╝
    echo.
    echo 1. Upload credentials to production server:
    echo    scp youtube-credentials.zip root@YOUR_SERVER_IP:/tmp/
    echo.
    echo 2. SSH to production server and extract:
    echo    ssh root@YOUR_SERVER_IP
    echo    cd /opt/apache-tomcat-9
    echo    unzip /tmp/youtube-credentials.zip
    echo    chown -R tomcat:tomcat credentials/
    echo    chmod -R 755 credentials/
    echo.
    echo 3. Restart Tomcat:
    echo    /opt/apache-tomcat-9/bin/shutdown.sh
    echo    /opt/apache-tomcat-9/bin/startup.sh
    echo.
    echo 4. Verify in logs:
    echo    tail -f /opt/apache-tomcat-9/logs/catalina.out
    echo.
    echo Look for: "✓ Using existing stored credentials"
    echo.
) else (
    echo ✗ Failed to create archive
    echo.
    echo Please manually copy the credentials folder to production:
    echo   Source: %CRED_PATH%
    echo   Destination on server: /opt/apache-tomcat-9/credentials/
    echo.
)

pause

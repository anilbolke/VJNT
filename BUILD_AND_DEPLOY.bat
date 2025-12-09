@echo off
REM ============================================
REM Complete Build and Deployment Script
REM Ensures client_secret.json is in WAR
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Building WAR with YouTube API Configuration                      ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Step 1: Verify client_secret.json exists
echo [Step 1/5] Verifying client_secret.json exists...
if not exist "src\main\resources\client_secret.json" (
    echo.
    echo ✗ ERROR: client_secret.json NOT FOUND!
    echo.
    echo Please place your client_secret.json file in:
    echo   src\main\resources\client_secret.json
    echo.
    echo Get this file from Google Cloud Console:
    echo   https://console.cloud.google.com/apis/credentials
    echo.
    pause
    exit /b 1
)
echo ✓ client_secret.json found
echo.

REM Step 2: Clean previous builds
echo [Step 2/5] Cleaning previous builds...
call mvn clean
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Clean failed
    pause
    exit /b 1
)
echo ✓ Clean successful
echo.

REM Step 3: Build WAR file
echo [Step 3/5] Building WAR file...
call mvn package -DskipTests
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Build failed
    pause
    exit /b 1
)
echo ✓ Build successful
echo.

REM Step 4: Verify client_secret.json is in WAR
echo [Step 4/5] Verifying client_secret.json is packaged in WAR...
jar tf target\ROOT.war | findstr "client_secret.json" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ client_secret.json is in WAR file!
    jar tf target\ROOT.war | findstr "client_secret.json"
) else (
    echo.
    echo ✗ ERROR: client_secret.json NOT FOUND in WAR!
    echo.
    echo The file exists but wasn't packaged. This could be due to:
    echo   1. Maven resource filtering issue
    echo   2. .gitignore excluding the file
    echo   3. Build configuration problem
    echo.
    echo Attempting manual fix...
    
    REM Create WEB-INF/classes directory in target
    if not exist "target\ROOT\WEB-INF\classes" mkdir "target\ROOT\WEB-INF\classes"
    
    REM Copy file manually
    copy "src\main\resources\client_secret.json" "target\ROOT\WEB-INF\classes\client_secret.json"
    
    REM Repackage WAR
    cd target\ROOT
    jar -cvf ..\ROOT.war *
    cd ..\..
    
    echo ✓ Manually added client_secret.json to WAR
)
echo.

REM Step 5: Show deployment instructions
echo [Step 5/5] Deployment Instructions
echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  WAR file ready for deployment                                    ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
echo WAR Location: target\ROOT.war
echo.
echo To deploy to production server:
echo.
echo 1. Upload ROOT.war to your server
echo    scp target\ROOT.war root@YOUR_SERVER_IP:/tmp/
echo.
echo 2. SSH to your server and run:
echo    sudo /opt/apache-tomcat-9/bin/shutdown.sh
echo    sudo rm -rf /opt/apache-tomcat-9/webapps/ROOT
echo    sudo rm -f /opt/apache-tomcat-9/webapps/ROOT.war
echo    sudo cp /tmp/ROOT.war /opt/apache-tomcat-9/webapps/
echo    sudo /opt/apache-tomcat-9/bin/startup.sh
echo.
echo 3. Verify deployment:
echo    tail -f /opt/apache-tomcat-9/logs/catalina.out
echo.
echo Look for this message in logs:
echo    ✓ SUCCESS: Found client_secret.json in classpath
echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Build Complete!                                                   ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
pause

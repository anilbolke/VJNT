@echo off
REM ============================================
REM YouTube OAuth Token Generator
REM Run this on your LOCAL machine to generate
REM credentials that can be copied to production
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  YouTube OAuth Token Generator                                     ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
echo This script will:
echo   1. Configure OAuth authentication
echo   2. Start a test server
echo   3. Open browser for YouTube authorization
echo   4. Save credentials for production use
echo.

REM Check if youtube.properties is already set to OAuth
findstr /C:"youtube.auth.type=oauth" "src\main\resources\youtube.properties" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ YouTube authentication is already set to OAuth
) else (
    echo [Step 1/4] Configuring OAuth authentication...
    powershell -Command "(Get-Content 'src\main\resources\youtube.properties') -replace 'youtube.auth.type=service-account', 'youtube.auth.type=oauth' | Set-Content 'src\main\resources\youtube.properties'"
    echo ✓ OAuth configured
)
echo.

REM Check if client_secret.json exists
echo [Step 2/4] Verifying client_secret.json...
if not exist "src\main\resources\client_secret.json" (
    echo ✗ ERROR: client_secret.json NOT FOUND!
    echo.
    echo Please download OAuth credentials from Google Cloud Console:
    echo   1. Go to: https://console.cloud.google.com/apis/credentials
    echo   2. Create OAuth 2.0 Client ID (Desktop application)
    echo   3. Download JSON file
    echo   4. Save as: src\main\resources\client_secret.json
    echo.
    pause
    exit /b 1
)
echo ✓ client_secret.json found
echo.

REM Build and run
echo [Step 3/4] Building application...
call BUILD_WAR_ECLIPSE.bat
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Build failed!
    pause
    exit /b 1
)
echo.

echo [Step 4/4] Starting authorization process...
echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  IMPORTANT: A browser window will open                            ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
echo Next steps:
echo   1. Browser will open with Google authorization page
echo   2. Sign in with the Google account that owns your YouTube channel
echo   3. Click "Allow" to grant YouTube upload permissions
echo   4. Wait for "Authorization successful" message
echo   5. Credentials will be saved in 'credentials' folder
echo.
echo Press any key to start the authorization process...
pause >nul

REM Deploy WAR and open test page
echo.
echo Starting Tomcat server...
echo (If already running, just access the URL below)
echo.
echo Open this URL in your browser:
echo   http://localhost:8080/test-youtube-oauth.jsp
echo.
echo After successful authorization, credentials will be saved to:
echo   credentials/StoredCredential
echo.
echo You can then copy this folder to your production server!
echo.

echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  After Authorization is Complete                                   ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
echo Package credentials in WAR for production:
echo.
echo   1. Copy credentials to webapp:
echo      mkdir "src\main\webapp\WEB-INF\classes\credentials"
echo      copy "credentials\StoredCredential" "src\main\webapp\WEB-INF\classes\credentials\"
echo.
echo   2. Rebuild WAR:
echo      BUILD_WAR_ECLIPSE.bat
echo.
echo   3. Deploy ROOT.war to production
echo.
echo   4. Uploads will work without browser (tokens auto-refresh)
echo.

pause

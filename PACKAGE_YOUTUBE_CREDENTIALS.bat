@echo off
REM ============================================
REM Package OAuth Credentials for Production
REM Run this AFTER generating tokens locally
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Package YouTube OAuth Credentials for Production                 ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Check if credentials exist
if not exist "credentials\StoredCredential" (
    echo ✗ ERROR: OAuth credentials NOT FOUND!
    echo.
    echo You need to generate credentials first:
    echo   1. Run: GENERATE_YOUTUBE_TOKENS.bat
    echo   2. Authorize in browser
    echo   3. Wait for credentials to be saved
    echo   4. Then run this script again
    echo.
    pause
    exit /b 1
)
echo ✓ Found OAuth credentials
echo.

REM Create credentials folder in webapp
echo [Step 1/3] Copying credentials to webapp...
if not exist "src\main\webapp\WEB-INF\classes\credentials" mkdir "src\main\webapp\WEB-INF\classes\credentials"
copy /Y "credentials\StoredCredential" "src\main\webapp\WEB-INF\classes\credentials\StoredCredential"
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Copy failed!
    pause
    exit /b 1
)
echo ✓ Credentials copied
echo.

REM Rebuild WAR
echo [Step 2/3] Building production WAR...
call BUILD_WAR_ECLIPSE.bat
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Build failed!
    pause
    exit /b 1
)
echo.

REM Verify credentials in WAR
echo [Step 3/3] Verifying credentials in WAR...
jar tf ROOT.war | findstr "StoredCredential" >nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ SUCCESS: OAuth credentials are packaged in ROOT.war!
    jar tf ROOT.war | findstr "StoredCredential"
) else (
    echo ✗ ERROR: Credentials NOT found in WAR!
    pause
    exit /b 1
)
echo.

echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Production Deployment Ready!                                      ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
echo Your ROOT.war now contains YouTube OAuth credentials.
echo.
echo Next steps:
echo   1. Deploy ROOT.war to production server
echo   2. YouTube uploads will work without browser
echo   3. Tokens will auto-refresh automatically
echo.
echo The credentials are valid for:
echo   - 6 months (if used regularly)
echo   - Auto-refresh keeps them active
echo   - No browser needed in production
echo.

pause

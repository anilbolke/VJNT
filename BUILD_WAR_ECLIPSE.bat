@echo off
REM ============================================
REM Eclipse WAR Builder (No Maven Required)
REM Ensures client_secret.json is packaged
REM ============================================

echo.
echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Building WAR for Production (Eclipse/Non-Maven)                  ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.

REM Step 1: Verify required files exist
echo [Step 1/6] Verifying required files exist...
if not exist "src\main\resources\client_secret.json" (
    echo ✗ ERROR: client_secret.json NOT FOUND!
    echo Please place it in: src\main\resources\client_secret.json
    pause
    exit /b 1
)
echo ✓ client_secret.json found

if not exist "src\main\resources\youtube.properties" (
    echo ✗ WARNING: youtube.properties NOT FOUND!
    echo Configuration file missing - will use default OAuth authentication
) else (
    echo ✓ youtube.properties found
)

if not exist "src\main\resources\service-account.json" (
    echo ⚠ NOTE: service-account.json NOT FOUND - only OAuth will work
) else (
    echo ✓ service-account.json found
)
echo.

REM Step 2: Copy resource files to WEB-INF/classes
echo [Step 2/6] Copying resource files to WEB-INF/classes...
if not exist "src\main\webapp\WEB-INF\classes" mkdir "src\main\webapp\WEB-INF\classes"

REM Copy client_secret.json
copy /Y "src\main\resources\client_secret.json" "src\main\webapp\WEB-INF\classes\client_secret.json"
if %ERRORLEVEL% NEQ 0 (
    echo ✗ Copy client_secret.json failed
    pause
    exit /b 1
)
echo ✓ client_secret.json copied

REM Copy youtube.properties if exists
if exist "src\main\resources\youtube.properties" (
    copy /Y "src\main\resources\youtube.properties" "src\main\webapp\WEB-INF\classes\youtube.properties"
    echo ✓ youtube.properties copied
)

REM Copy service-account.json if exists
if exist "src\main\resources\service-account.json" (
    copy /Y "src\main\resources\service-account.json" "src\main\webapp\WEB-INF\classes\service-account.json"
    echo ✓ service-account.json copied
)

REM Copy OAuth credentials if exist (for production)
if exist "credentials\StoredCredential" (
    if not exist "src\main\webapp\WEB-INF\classes\credentials" mkdir "src\main\webapp\WEB-INF\classes\credentials"
    copy /Y "credentials\StoredCredential" "src\main\webapp\WEB-INF\classes\credentials\StoredCredential"
    echo ✓ OAuth credentials copied
)
echo.

REM Step 3: Create WAR directory structure
echo [Step 3/6] Preparing WAR structure...
if not exist "build\war" mkdir "build\war"
xcopy /E /I /Y "src\main\webapp\*" "build\war\"
echo ✓ WAR structure ready
echo.

REM Step 4: Copy compiled classes
echo [Step 4/6] Copying compiled classes...
if exist "build\classes" (
    xcopy /E /I /Y "build\classes\*" "build\war\WEB-INF\classes\"
    echo ✓ Classes copied
) else (
    echo ⚠ Warning: build\classes not found - make sure to build project in Eclipse first
)
echo.

REM Step 5: Create WAR file
echo [Step 5/6] Creating ROOT.war...
cd build\war
if exist "..\ROOT.war" del "..\ROOT.war"
jar -cvf ..\ROOT.war *
cd ..\..
move /Y "build\ROOT.war" "ROOT.war"
echo ✓ ROOT.war created
echo.

REM Step 6: Verify resource files are in WAR
echo [Step 6/6] Verifying resource files in WAR...
echo Checking client_secret.json...
jar tf ROOT.war | findstr "client_secret.json"
if %ERRORLEVEL% EQU 0 (
    echo ✓ client_secret.json is in ROOT.war
) else (
    echo ✗ ERROR: client_secret.json NOT in WAR!
    pause
    exit /b 1
)

echo Checking youtube.properties...
jar tf ROOT.war | findstr "youtube.properties"
if %ERRORLEVEL% EQU 0 (
    echo ✓ youtube.properties is in ROOT.war
) else (
    echo ⚠ WARNING: youtube.properties NOT in WAR
)

echo Checking service-account.json...
jar tf ROOT.war | findstr "service-account.json"
if %ERRORLEVEL% EQU 0 (
    echo ✓ service-account.json is in ROOT.war
) else (
    echo ⚠ NOTE: service-account.json NOT in WAR (OAuth mode only)
)
echo.

echo ╔════════════════════════════════════════════════════════════════════╗
echo ║  Build Complete!                                                   ║
echo ╚════════════════════════════════════════════════════════════════════╝
echo.
echo WAR file: ROOT.war
echo.
echo Next steps:
echo 1. Upload to server: scp ROOT.war root@YOUR_SERVER:/tmp/
echo 2. Deploy on server (see DEPLOY_PRODUCTION.sh)
echo.
pause

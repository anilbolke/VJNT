@echo off
REM ============================================
REM WAR Builder (self-contained, no Eclipse required)
REM Pipeline: compile -> stage -> package -> verify
REM ============================================
setlocal enabledelayedexpansion

cd /d "%~dp0"

echo.
echo ============================================================
echo  Building ROOT.war
echo ============================================================
echo.

REM Step 1: Verify optional resource files (YouTube/OAuth features)
echo [1/6] Checking optional resource files...
if exist "src\main\resources\client_secret.json" (
    echo   OK client_secret.json
) else (
    echo   SKIP client_secret.json - YouTube/OAuth disabled
)
if exist "src\main\resources\youtube.properties" (
    echo   OK youtube.properties
) else (
    echo   SKIP youtube.properties
)
if exist "src\main\resources\service-account.json" (
    echo   OK service-account.json
) else (
    echo   SKIP service-account.json
)
echo.

REM Step 2: Compile sources (always fresh)
echo [2/6] Compiling sources via compile.bat...
call "%~dp0compile.bat"
if errorlevel 1 (
    echo   ERROR: compilation failed
    pause
    exit /b 1
)
if not exist "build\classes\com\vjnt\servlet\LoginServlet.class" (
    echo   ERROR: build\classes is missing compiled output
    pause
    exit /b 1
)
echo   OK compilation complete
echo.

REM Step 3: Prepare fresh build\war staging dir
echo [3/6] Staging build\war...
if exist "build\war" rmdir /s /q "build\war"
mkdir "build\war"

REM Copy web content (but skip any WEB-INF\classes from source tree - we'll populate it from build\classes)
xcopy /E /I /Y /Q "src\main\webapp\*" "build\war\" >nul
if exist "build\war\WEB-INF\classes" rmdir /s /q "build\war\WEB-INF\classes"
mkdir "build\war\WEB-INF\classes"
echo   OK web content staged
echo.

REM Step 4: Copy compiled classes into WAR
echo [4/6] Copying compiled classes...
xcopy /E /I /Y /Q "build\classes\*" "build\war\WEB-INF\classes\" >nul
echo   OK classes copied
echo.

REM Step 5: Copy optional runtime resources into WAR (NOT into source tree)
echo [5/6] Copying optional resources (if present)...
if exist "src\main\resources\client_secret.json" (
    copy /Y "src\main\resources\client_secret.json" "build\war\WEB-INF\classes\client_secret.json" >nul
    echo   OK client_secret.json
)
if exist "src\main\resources\youtube.properties" (
    copy /Y "src\main\resources\youtube.properties" "build\war\WEB-INF\classes\youtube.properties" >nul
    echo   OK youtube.properties
)
if exist "src\main\resources\service-account.json" (
    copy /Y "src\main\resources\service-account.json" "build\war\WEB-INF\classes\service-account.json" >nul
    echo   OK service-account.json
)
if exist "credentials\StoredCredential" (
    mkdir "build\war\WEB-INF\classes\credentials" 2>nul
    copy /Y "credentials\StoredCredential" "build\war\WEB-INF\classes\credentials\StoredCredential" >nul
    echo   OK OAuth StoredCredential
)
echo.

REM Step 6: Package WAR
echo [6/6] Packaging ROOT.war...
if exist "ROOT.war" del /q "ROOT.war"
pushd "build\war"
jar -cf ..\..\ROOT.war *
popd
if not exist "ROOT.war" (
    echo   ERROR: jar packaging failed
    pause
    exit /b 1
)
echo   OK ROOT.war created
echo.

REM Verification
echo Verifying WAR contents...
jar tf ROOT.war | findstr /R "WEB-INF/classes/com/vjnt/servlet/LoginServlet.class" >nul && echo   OK LoginServlet.class || echo   MISSING LoginServlet.class
jar tf ROOT.war | findstr /R "WEB-INF/classes/com/vjnt/servlet/ExcelUploadServlet.class" >nul && echo   OK ExcelUploadServlet.class || echo   MISSING ExcelUploadServlet.class
jar tf ROOT.war | findstr "javax.servlet-api" >nul && echo   WARN javax.servlet-api jar is in WAR - will conflict with Tomcat container || echo   OK no container-provided servlet-api in WAR
echo.

echo ============================================================
echo  Build complete. Artifact: ROOT.war
echo ============================================================
echo.
pause

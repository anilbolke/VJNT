@echo off
REM Quick rebuild and deploy script

cd "C:\Users\Admin\V2Project\VJNT Class Managment"

echo Rebuilding project...
echo.

REM Step 1: Delete old build files
if exist "build\classes" (
    echo [1/3] Cleaning old classes...
    rmdir /s /q "build\classes"
)

REM Step 2: Wait for Eclipse to rebuild
echo [2/3] IMPORTANT: Switch to Eclipse and clean the project
echo       Project menu -^> Clean -^> Clean all projects
echo       Then come back and press ENTER
pause

REM Step 3: Build WAR
echo [3/3] Building ROOT.war...
if exist "build\war" rmdir /s /q "build\war"
mkdir "build\war"

REM Copy webapp files
xcopy /E /I /Y "src\main\webapp\*" "build\war\"

REM Copy classes
if exist "build\classes" (
    xcopy /E /I /Y "build\classes\*" "build\war\WEB-INF\classes\"
)

REM Create WAR
cd "build\war"
if exist "..\ROOT.war" del "..\ROOT.war"
jar -cvf ..\ROOT.war * >nul 2>&1
cd ..\..

if exist "build\ROOT.war" (
    move /Y "build\ROOT.war" "ROOT.war"
    echo ✓ ROOT.war created successfully
    echo.
    echo Now:
    echo 1. Copy ROOT.war to: D:\apache-tomcat-9.0.100\webapps\
    echo 2. Restart Tomcat
    echo 3. Test: http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150201202
) else (
    echo ✗ Build failed
)

pause

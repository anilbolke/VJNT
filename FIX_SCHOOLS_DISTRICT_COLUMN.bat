@echo off
echo ════════════════════════════════════════════════════════════
echo   FIX SCHOOLS TABLE - CORRECT COLUMN NAMES
echo ════════════════════════════════════════════════════════════
echo.
echo Issue: Used s.district but actual column is district_name
echo Fix: Changed to sch.district_name
echo.
pause

cd /d "%~dp0"

echo.
echo Step 1: Setting up environment...
set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%
set TOMCAT_LIB=C:\Program Files\Apache Software Foundation\Tomcat 9.0\lib
set CLASSPATH=%TOMCAT_LIB%\servlet-api.jar;WebContent\WEB-INF\lib\*;build\classes

echo.
echo Step 2: Compiling DivisionAnalyticsServlet.java...
javac -d build\classes -cp "%CLASSPATH%" src\main\java\com\vjnt\servlet\DivisionAnalyticsServlet.java

if errorlevel 1 (
    echo.
    echo ✗ ERROR: Compilation failed!
    pause
    exit /b 1
)
echo ✓ Compilation successful

echo.
echo Step 3: Copying to WebContent...
xcopy /s /y /q build\classes\com\vjnt\servlet\DivisionAnalyticsServlet.class WebContent\WEB-INF\classes\com\vjnt\servlet\

echo.
echo Step 4: Checking Tomcat directory...
set TOMCAT_WEBAPPS=C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\VJNT

if not exist "%TOMCAT_WEBAPPS%" (
    echo ✗ WARNING: Tomcat webapps not found!
    pause
    exit /b 1
)

echo.
echo Step 5: Deploying to Tomcat...
xcopy /s /y /q WebContent\WEB-INF\classes\com\vjnt\servlet\DivisionAnalyticsServlet.class "%TOMCAT_WEBAPPS%\WEB-INF\classes\com\vjnt\servlet\"

echo.
echo ════════════════════════════════════════════════════════════
echo   DEPLOYMENT COMPLETE!
echo ════════════════════════════════════════════════════════════
echo.
echo Fix Applied:
echo   ✓ Changed s.district to sch.district_name
echo   ✓ Schools table has district_name column
echo   ✓ Query now uses correct column names
echo.
echo IMPORTANT:
echo   1. RESTART TOMCAT SERVER
echo   2. Clear browser cache
echo   3. Test: /division-analytics?type=palak_melava
echo   4. Should work without SQL errors now
echo.
pause

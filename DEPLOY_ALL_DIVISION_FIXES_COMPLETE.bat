@echo off
echo ════════════════════════════════════════════════════════════
echo   DEPLOY ALL DIVISION FIXES - BACKEND + FRONTEND
echo ════════════════════════════════════════════════════════════
echo.
echo This will deploy:
echo   • LoginServlet.class (Fix #1)
echo   • DivisionAnalyticsServlet.class (Fixes #2-6)
echo   • division-dashboard.jsp
echo   • division-dashboard-enhanced.jsp (Fix #7)
echo.
pause

cd /d "%~dp0"

echo.
echo ════════════════════════════════════════════════════════════
echo   STEP 1: COMPILE JAVA FILES
echo ════════════════════════════════════════════════════════════

set JAVA_HOME=C:\Program Files\Java\jdk-17
set PATH=%JAVA_HOME%\bin;%PATH%
set TOMCAT_LIB=C:\Program Files\Apache Software Foundation\Tomcat 9.0\lib
set CLASSPATH=%TOMCAT_LIB%\servlet-api.jar;WebContent\WEB-INF\lib\*;build\classes

echo Compiling servlets...
javac -d build\classes -cp "%CLASSPATH%" src\main\java\com\vjnt\servlet\LoginServlet.java
javac -d build\classes -cp "%CLASSPATH%" src\main\java\com\vjnt\servlet\DivisionAnalyticsServlet.java

if errorlevel 1 (
    echo.
    echo ✗ ERROR: Compilation failed!
    pause
    exit /b 1
)
echo ✓ Compilation successful

echo.
echo ════════════════════════════════════════════════════════════
echo   STEP 2: COPY TO WEBCONTENT
echo ════════════════════════════════════════════════════════════

xcopy /s /y /q build\classes\com\vjnt\servlet\*.class WebContent\WEB-INF\classes\com\vjnt\servlet\
echo ✓ Servlets copied to WebContent

echo.
echo ════════════════════════════════════════════════════════════
echo   STEP 3: DEPLOY TO TOMCAT
echo ════════════════════════════════════════════════════════════

set TOMCAT_WEBAPPS=C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\VJNT

if not exist "%TOMCAT_WEBAPPS%" (
    echo ✗ WARNING: Tomcat webapps not found at:
    echo   %TOMCAT_WEBAPPS%
    echo.
    echo Please update TOMCAT_WEBAPPS path in this script.
    pause
    exit /b 1
)

echo Deploying servlets...
xcopy /s /y /q WebContent\WEB-INF\classes\com\vjnt\servlet\LoginServlet.class "%TOMCAT_WEBAPPS%\WEB-INF\classes\com\vjnt\servlet\"
xcopy /s /y /q WebContent\WEB-INF\classes\com\vjnt\servlet\DivisionAnalyticsServlet.class "%TOMCAT_WEBAPPS%\WEB-INF\classes\com\vjnt\servlet\"
echo ✓ Servlets deployed

echo.
echo Deploying JSP files...
xcopy /y /q WebContent\division-dashboard.jsp "%TOMCAT_WEBAPPS%\"
xcopy /y /q WebContent\division-dashboard-enhanced.jsp "%TOMCAT_WEBAPPS%\"
echo ✓ JSP files deployed

echo.
echo ════════════════════════════════════════════════════════════
echo   DEPLOYMENT COMPLETE!
echo ════════════════════════════════════════════════════════════
echo.
echo ALL 7 FIXES DEPLOYED:
echo.
echo Backend Fixes (Servlets):
echo   1. ✓ Login redirect
echo   2. ✓ Null pointer check
echo   3. ✓ Palak Melava column (melava_id)
echo   4. ✓ Parent count accuracy
echo   5. ✓ Schools table column (district_name)
echo   6. ✓ Phase completion query (phase_completion_status)
echo.
echo Frontend Fix (JSP):
echo   7. ✓ Case sensitivity fix (Districts → districts)
echo.
echo ════════════════════════════════════════════════════════════
echo   ⚠️  IMPORTANT NEXT STEPS
echo ════════════════════════════════════════════════════════════
echo.
echo 1. RESTART TOMCAT SERVER
echo    - Stop Tomcat
echo    - Wait 5 seconds
echo    - Start Tomcat
echo    (Required for servlet changes to take effect)
echo.
echo 2. CLEAR BROWSER CACHE
echo    - Press Ctrl+Shift+Delete
echo    - Select "Cached images and files"
echo    - Click "Clear data"
echo    (Required for JSP changes to take effect)
echo.
echo 3. TEST ALL FEATURES
echo    - Login as division user
echo    - Check dashboard displays
echo    - Click Analytics button
echo    - Verify phase completion for all 4 phases
echo    - Test all chart types
echo.
echo ════════════════════════════════════════════════════════════
echo   TESTING CHECKLIST
echo ════════════════════════════════════════════════════════════
echo.
echo □ Login as division user
echo □ Division dashboard displays
echo □ Click Analytics button
echo □ Phase 1 shows data (Total Districts, Avg Completion)
echo □ Phase 2 shows data
echo □ Phase 3 shows data
echo □ Phase 4 shows data
echo □ Bar charts render
echo □ Pie charts toggle works
echo □ No console errors (press F12)
echo.
pause

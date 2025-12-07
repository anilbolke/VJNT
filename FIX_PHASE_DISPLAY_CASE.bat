@echo off
echo ════════════════════════════════════════════════════════════
echo   FIX PHASE COMPLETION DISPLAY - CASE SENSITIVITY
echo ════════════════════════════════════════════════════════════
echo.
echo Issue: Phase completion not displaying (case mismatch)
echo Fix: Changed Districts to districts in JavaScript
echo.
pause

cd /d "%~dp0"

echo.
echo Checking Tomcat directory...
set TOMCAT_WEBAPPS=C:\Program Files\Apache Software Foundation\Tomcat 9.0\webapps\VJNT

if not exist "%TOMCAT_WEBAPPS%" (
    echo ✗ WARNING: Tomcat webapps not found!
    pause
    exit /b 1
)

echo.
echo Deploying fixed JSP...
xcopy /s /y /q WebContent\division-dashboard-enhanced.jsp "%TOMCAT_WEBAPPS%\"

echo.
echo ════════════════════════════════════════════════════════════
echo   DEPLOYMENT COMPLETE!
echo ════════════════════════════════════════════════════════════
echo.
echo Fix Applied:
echo   ✓ Changed data.Districts to data.districts
echo   ✓ JavaScript now matches servlet JSON keys
echo   ✓ Phase completion should display now
echo.
echo IMPORTANT:
echo   1. NO NEED to restart Tomcat (JSP file only)
echo   2. Clear browser cache (Ctrl+Shift+Delete)
echo   3. Hard refresh page (Ctrl+F5)
echo   4. Test: Open division analytics dashboard
echo   5. Phase completion should show data for all 4 phases
echo.
pause

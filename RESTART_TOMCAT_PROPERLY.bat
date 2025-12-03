@echo off
echo ========================================
echo  RESTART TOMCAT PROPERLY
echo ========================================
echo.

echo This script will help you restart Tomcat properly
echo to load the new GetReportDetailsServlet.
echo.

echo STEP 1: Stop Tomcat
echo --------------------
echo Please stop your Tomcat server now:
echo - If using Windows Service: Go to Services and stop Apache Tomcat
echo - If using startup.bat: Press Ctrl+C in Tomcat window
echo - If using IDE: Use the Stop button
echo.
pause
echo.

echo STEP 2: Clear Tomcat Work Directory
echo -------------------------------------
echo This removes cached compiled JSPs and servlets.
echo.
echo Please navigate to your Tomcat installation folder and delete:
echo   apache-tomcat\work\Catalina\localhost\VJNT_Class_Managment
echo.
echo Example path:
echo   C:\Program Files\Apache Software Foundation\Tomcat 9.0\work\Catalina\localhost\VJNT_Class_Managment
echo.
echo Delete the entire VJNT_Class_Managment folder.
echo.
pause
echo.

echo STEP 3: Verify Deployment
echo --------------------------
echo Let's check if the servlet is deployed...
echo.

if exist "WebContent\WEB-INF\classes\com\vjnt\servlet\GetReportDetailsServlet.class" (
    echo [OK] GetReportDetailsServlet.class found in WebContent
) else (
    echo [ERROR] GetReportDetailsServlet.class NOT FOUND in WebContent!
    echo         Please run DEPLOY_ALL_UPDATES.bat first
    pause
    exit /b 1
)
echo.

echo STEP 4: Start Tomcat
echo ---------------------
echo Please start your Tomcat server now:
echo - If using Windows Service: Start Apache Tomcat service
echo - If using startup.bat: Run startup.bat
echo - If using IDE: Use the Start button
echo.
echo WAIT for Tomcat to fully start (look for "Server startup in ... ms")
echo.
pause
echo.

echo STEP 5: Test the Servlet
echo -------------------------
echo Opening browser to test the servlet endpoint...
echo.
echo URL: http://localhost:8080/VJNT_Class_Managment/api/getReportDetails?approvalId=1
echo.
echo EXPECTED: JSON response with student data
echo NOT: 404 error or HTML error page
echo.
start http://localhost:8080/VJNT_Class_Managment/api/getReportDetails?approvalId=1
echo.
pause
echo.

echo ========================================
echo  VERIFICATION CHECKLIST
echo ========================================
echo.
echo Did you see JSON response? (Y/N)
set /p response=
if /i "%response%"=="Y" (
    echo.
    echo [SUCCESS] Servlet is working!
    echo You can now test the Head Master modal view.
) else (
    echo.
    echo [FAILED] Servlet still not working.
    echo.
    echo TROUBLESHOOTING:
    echo 1. Check Tomcat logs for errors
    echo 2. Verify Tomcat restarted completely
    echo 3. Check URL context path is correct
    echo 4. Run this script again
)
echo.
pause

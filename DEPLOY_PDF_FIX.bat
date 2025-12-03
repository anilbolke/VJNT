@echo off
echo ========================================
echo   PDF Servlet Fix - Deployment
echo ========================================
echo.

echo Step 1: Stopping Tomcat...
net stop Tomcat10
timeout /t 5 /nobreak

echo.
echo Step 2: Cleaning deployment...
rd /s /q "C:\Program Files\Apache Software Foundation\Tomcat 10.1\work\Catalina\localhost\VJNT_Class_Managment"

echo.
echo Step 3: Starting Tomcat...
net start Tomcat10

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo NEXT: Wait 30 seconds, then test:
echo 1. Login as School Coordinator
echo 2. Go to student-comprehensive-report-new.jsp
echo 3. Click "Generate Report"
echo 4. Click "View & Print Approved Report"
echo 5. See modal-styled report open in new tab!
echo.
pause

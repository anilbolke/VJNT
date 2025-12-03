@echo off
echo ========================================
echo  Deploy Report Approval System
echo ========================================
echo.

echo Step 1: Copying JSP files...
xcopy /Y "src\main\webapp\my-report-requests.jsp" "WebContent\" 2>nul
xcopy /Y "src\main\webapp\student-comprehensive-report-new.jsp" "WebContent\" 2>nul
xcopy /Y "src\main\webapp\school-dashboard-enhanced.jsp" "WebContent\" 2>nul
echo JSP files copied.
echo.

echo Step 2: Copying compiled classes...
xcopy /Y "build\classes\com\vjnt\servlet\*.class" "WebContent\WEB-INF\classes\com\vjnt\servlet\" 2>nul
xcopy /Y "build\classes\com\vjnt\dao\*.class" "WebContent\WEB-INF\classes\com\vjnt\dao\" 2>nul
echo Class files copied.
echo.

echo ========================================
echo  Deployment Complete!
echo ========================================
echo.
echo NEXT STEPS:
echo 1. Restart Tomcat server
echo 2. Login as School Coordinator
echo 3. Test the new features:
echo    - Generate Student Report
echo    - Submit for Approval
echo    - Check "My Report Requests"
echo.
echo 4. Login as Head Master
echo 5. Approve/Reject reports
echo.
echo 6. Login back as School Coordinator
echo 7. Print approved reports
echo.

pause

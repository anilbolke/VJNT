@echo off
echo ============================================
echo   Deploy Teacher Names Feature
echo ============================================
echo.

REM Copy JSP file to WebContent
echo Copying JSP file...
copy /Y "src\main\webapp\student-comprehensive-report-new.jsp" "WebContent\student-comprehensive-report-new.jsp"

echo.
echo ============================================
echo   Files Updated:
echo ============================================
echo   - GetComprehensiveReportServlet.java
echo   - GenerateStudentReportPDFServlet.java
echo   - student-comprehensive-report-new.jsp
echo.
echo ============================================
echo   Next Steps:
echo ============================================
echo   1. Build the project in Eclipse
echo   2. Deploy to Tomcat
echo   3. Restart Tomcat server
echo   4. Test the report generation feature
echo.
echo ============================================
echo   Feature: Teacher Names in Reports
echo ============================================
echo   - Shows teacher names for each subject
echo   - Displays in assessment levels section
echo   - Shows in activity group headers
echo   - Included in PDF exports
echo.

pause

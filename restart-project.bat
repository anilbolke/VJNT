@echo off
echo ========================================
echo VJNT Project Restart Script
echo ========================================
echo.

echo Step 1: Cleaning compiled classes...
cd /d "C:\Users\Admin\V2Project\VJNT Class Managment"
if exist "build\classes\com\vjnt\dao\PhaseApprovalDAO.class" (
    del /F "build\classes\com\vjnt\dao\PhaseApprovalDAO.class"
    echo   - Deleted PhaseApprovalDAO.class
)
if exist "build\classes\com\vjnt\servlet\SubmitPhaseServlet.class" (
    del /F "build\classes\com\vjnt\servlet\SubmitPhaseServlet.class"
    echo   - Deleted SubmitPhaseServlet.class
)
echo.

echo Step 2: Recompiling Java files...
set JAVA_HOME=C:\Program Files\Java\jdk-17
set CLASSPATH=WebContent\WEB-INF\lib\*;build\classes

"%JAVA_HOME%\bin\javac" -cp "%CLASSPATH%" -d "build\classes" "src\main\java\com\vjnt\dao\PhaseApprovalDAO.java"
if %errorlevel% equ 0 (
    echo   - PhaseApprovalDAO.java compiled successfully
) else (
    echo   - ERROR compiling PhaseApprovalDAO.java
)

"%JAVA_HOME%\bin\javac" -cp "%CLASSPATH%" -d "build\classes" "src\main\java\com\vjnt\servlet\SubmitPhaseServlet.java"
if %errorlevel% equ 0 (
    echo   - SubmitPhaseServlet.java compiled successfully
) else (
    echo   - ERROR compiling SubmitPhaseServlet.java
)
echo.

echo Step 3: Restart Tomcat in Eclipse
echo   IMPORTANT: You must manually restart Tomcat in Eclipse:
echo   1. Open Eclipse
echo   2. Go to Servers tab
echo   3. Right-click on Tomcat server
echo   4. Select "Clean..."
echo   5. Select "Restart"
echo.

echo Step 4: Test the application
echo   1. Open browser: http://localhost:8080/VJNT_Class_Management/login.jsp
echo   2. Login as School Coordinator
echo   3. Complete a phase
echo   4. Click "Submit for Approval"
echo   5. Verify no errors
echo.

echo ========================================
echo Compilation complete!
echo Now restart Tomcat in Eclipse.
echo ========================================
pause

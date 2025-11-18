@echo off
echo ========================================
echo   Image Display Fix - Deployment
echo ========================================
echo.

echo Step 1: Checking ImageServlet compilation...
if exist "build\classes\com\vjnt\servlet\ImageServlet.class" (
    echo [OK] ImageServlet.class found
) else (
    echo [ERROR] ImageServlet.class NOT found
    echo Compiling now...
    javac -cp "lib\*;build\javax.servlet-api-4.0.1.jar" -d "build\classes" "src\main\java\com\vjnt\servlet\ImageServlet.java"
    if errorlevel 1 (
        echo [ERROR] Compilation failed!
        pause
        exit /b 1
    )
    echo [OK] Compiled successfully
)
echo.

echo Step 2: Checking JSP updates...
if exist "src\main\webapp\palak-melava-approvals.jsp" (
    echo [OK] JSP file found with error handling
) else (
    echo [ERROR] JSP file not found!
    pause
    exit /b 1
)
echo.

echo ========================================
echo   DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo IMPORTANT: You must now RESTART TOMCAT
echo.
echo Choose your restart method:
echo   1. Eclipse: Servers tab ^> Right-click ^> Restart
echo   2. Services: services.msc ^> Apache Tomcat ^> Restart  
echo   3. Command: shutdown.bat ^& startup.bat
echo.
echo After restart, test at:
echo   - Login as Head Master
echo   - Go to Palak Melava Approvals
echo   - Check if images display properly
echo.
pause

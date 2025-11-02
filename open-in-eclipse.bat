@echo off
echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║  Opening VJNT Class Management in Eclipse                     ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.
echo Starting Eclipse with workspace: C:\Users\Admin\V2Project
echo.

cd "C:\Users\Admin\eclipse"
start eclipse.exe -data "C:\Users\Admin\V2Project"

echo.
echo Eclipse is starting...
echo.
echo NEXT STEPS:
echo 1. Wait for Eclipse to fully load
echo 2. Open Servers view (Window → Show View → Servers)
echo 3. Right-click Tomcat v9.0 Server
echo 4. Add "VJNT Class Managment" project
echo 5. Start the server
echo 6. Access: http://localhost:8080/VJNT_Class_Managment/login.jsp
echo.
pause

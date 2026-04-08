@echo off
REM Simple WAR builder without fancy characters
cd /d "%~dp0"

echo Building WAR file...

REM Step 1: Delete old build
echo Deleting old build...
if exist "build" rmdir /s /q "build"
if exist "ROOT.war" del /f /q "ROOT.war"

REM Step 2: Compile with Eclipse
echo Compiling with Eclipse...
REM Note: Eclipse auto-compiles on save. If not, manually build in Eclipse:
REM Right-click project -> Build Project

REM Step 3: Wait for Eclipse to build
echo Waiting for Eclipse to compile...
timeout /t 10 /nobreak

REM Step 4: Check if build exists
if not exist "build\classes" (
    echo ERROR: Build directory not found! Build Eclipse project first.
    pause
    exit /b 1
)

echo Build directory found.

REM Step 5: Create WAR directory structure
echo Creating WAR structure...
if not exist "WAR_TEMP" mkdir "WAR_TEMP"
if not exist "WAR_TEMP\WEB-INF\classes" mkdir "WAR_TEMP\WEB-INF\classes"
if not exist "WAR_TEMP\WEB-INF\lib" mkdir "WAR_TEMP\WEB-INF\lib"

REM Step 6: Copy files
echo Copying compiled classes...
xcopy /E /I /Y "build\classes\*" "WAR_TEMP\WEB-INF\classes"

echo Copying web content...
xcopy /E /I /Y "src\main\webapp\*" "WAR_TEMP\"

echo Copying libraries...
if exist "build\lib" (
    xcopy /E /I /Y "build\lib\*" "WAR_TEMP\WEB-INF\lib"
)

REM Step 7: Create WAR file
echo Creating ROOT.war...
cd WAR_TEMP
jar cvf ..\ROOT.war *
cd ..

REM Step 8: Cleanup
echo Cleaning up temporary files...
rmdir /s /q "WAR_TEMP"

echo.
echo Build Complete!
echo WAR file created: ROOT.war
echo.
echo Next steps:
echo 1. Stop Tomcat (kill java.exe process)
echo 2. Delete D:\apache-tomcat-9.0.100\webapps\ROOT.war
echo 3. Delete D:\apache-tomcat-9.0.100\webapps\ROOT folder
echo 4. Copy new ROOT.war to D:\apache-tomcat-9.0.100\webapps\
echo 5. Start Tomcat
echo 6. Test: http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150408704
echo.
pause

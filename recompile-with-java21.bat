@echo off
echo ========================================
echo Recompiling Project with Java 21
echo ========================================

set "JAVA_HOME=C:\Users\Admin\.p2\pool\plugins\org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_21.0.8.v20250724-1412\jre"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo Using Java version:
java -version

cd /d "%~dp0"

echo.
echo Cleaning old classes...
if exist "build\classes" rd /s /q "build\classes"
mkdir "build\classes"

echo.
echo Setting up classpath...
set "CP="
for %%j in (lib\*.jar) do call :addcp "%%j"
call :addcp "D:\apache-tomcat-9.0.100\lib\servlet-api.jar"
call :addcp "D:\apache-tomcat-9.0.100\lib\jsp-api.jar"

echo.
echo Compiling Java sources...
dir /s /b "src\*.java" > sources.txt
javac -cp "%CP%" -sourcepath src -d "build\classes" @sources.txt -encoding UTF-8

if errorlevel 1 (
    echo.
    echo Compilation FAILED!
    pause
    exit /b 1
)

echo.
echo Compilation SUCCESSFUL!
echo.
echo Now copying to Tomcat...
xcopy /E /I /Y "build\classes\*" "D:\apache-tomcat-9.0.100\webapps\VJNT_Class_Managment\WEB-INF\classes\"

echo.
echo Done! Restart Tomcat to apply changes.
pause
exit /b 0

:addcp
if defined CP (set "CP=%CP%;%~1") else (set "CP=%~1")
goto :eof

@echo off
setlocal enabledelayedexpansion

cd /d "D:\VBJNT_UAT\VJNT Class Managment"

set "TOMCAT_LIB=D:\apache-tomcat-9.0.100\lib"

REM Create build directory
if not exist build\classes mkdir build\classes

REM Compile all Java files - use PowerShell to generate file list
echo Compiling Java files...
PowerShell -Command "Get-ChildItem -Path 'src\main\java' -Filter *.java -Recurse | ForEach-Object { '\"' + $_.FullName + '\"' }" > srcfiles.txt

javac --release 11 -cp "%TOMCAT_LIB%\servlet-api.jar;%TOMCAT_LIB%\jsp-api.jar;%TOMCAT_LIB%\el-api.jar;%TOMCAT_LIB%\websocket-api.jar;lib\*;." -d build\classes -encoding UTF-8 -proc:none @srcfiles.txt

if %ERRORLEVEL% neq 0 (
    echo Compilation failed!
    exit /b 1
)

echo Compilation completed successfully!
echo Creating WAR file...

REM Create WAR file
cd build
jar cvf VJNT_Class_Managment.war -C classes . -C ..\src\main\webapp .

if exist VJNT_Class_Managment.war (
    echo WAR file created successfully
    copy VJNT_Class_Managment.war "D:\apache-tomcat-9.0.100\webapps\VJNT_Class_Managment.war"
    echo Deploying to Tomcat...
) else (
    echo Failed to create WAR file
    exit /b 1
)

echo Done!

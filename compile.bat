@echo off
setlocal enabledelayedexpansion

cd /d "C:\Users\Admin\V2Project\VJNT Class Managment"

REM Tomcat 9 provided APIs (servlet-api / jsp-api / el-api / websocket-api). NOT packaged into the WAR.
set "TOMCAT_LIB=C:\Users\Admin\Downloads\apache-tomcat-9.0.115\apache-tomcat-9.0.115\lib"

REM Create files list (quoted, forward slashes so spaces+backslashes don't break javac @argfile parsing)
powershell -NoProfile -Command "Get-ChildItem -Path 'src\main\java\com\vjnt' -Filter *.java -Recurse | ForEach-Object { '\"' + ($_.FullName -replace '\\','/') + '\"' }" > srcfiles.txt

REM Compile
javac --release 11 -cp "lib/*;%TOMCAT_LIB%\servlet-api.jar;%TOMCAT_LIB%\jsp-api.jar;%TOMCAT_LIB%\el-api.jar;%TOMCAT_LIB%\websocket-api.jar;." -d build/classes -encoding UTF-8 -proc:none @srcfiles.txt

echo Compilation complete!

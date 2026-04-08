@echo off
setlocal enabledelayedexpansion

cd /d "C:\Users\Admin\V2Project\VJNT Class Managment"

REM Create files list
dir /s /b src\main\java\com\vjnt\*.java > srcfiles.txt

REM Compile
javac -cp "lib\*;." -d build\classes -encoding UTF-8 -proc:none @srcfiles.txt

echo Compilation complete!

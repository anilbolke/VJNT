@echo off
cd /d "C:\Users\Admin\V2Project\VJNT Class Managment"

REM Build classpath dynamically
setlocal enabledelayedexpansion
set CLASSPATH=
for /f "tokens=*" %%A in ('dir /b /s lib\*.jar') do (
    set CLASSPATH=!CLASSPATH!;%%A
)
set CLASSPATH=!CLASSPATH!;build\classes

REM Compile
javac --release 11 -cp "%CLASSPATH%" -d build\classes -encoding UTF-8 src\main\java\com\vjnt\servlet\DivisionPhaseComparisonServlet.java

if %ERRORLEVEL% EQU 0 (
    echo Compilation successful!
) else (
    echo Compilation failed with error code %ERRORLEVEL%
)

@echo off
setlocal enabledelayedexpansion

echo.
echo ================================================================
echo   VJNT - Excel User Loader
echo ================================================================
echo.

cd /d "%~dp0"

rem Step 1: Build classpath
echo [1/3] Building classpath...
set CP=target\classes
for %%f in (lib\*.jar) do set CP=!CP!;%%f
echo       Done

rem Step 2: Create output directory
echo [2/3] Preparing directories...
if not exist "target\classes" mkdir "target\classes"
echo       Done

rem Step 3: Compile
echo [3/3] Compiling Java sources...
dir /s /b "src\main\java\*.java" > sources.txt
javac -cp "!CP!" -d "target\classes" -encoding UTF-8 "@sources.txt"
if errorlevel 1 (
    echo       ERROR: Compilation failed!
    del sources.txt
    pause
    exit /b 1
)
del sources.txt
echo       Done
echo.

echo ================================================================
echo   Running ExcelUserLoader...
echo ================================================================
echo.

java -cp "!CP!" com.vjnt.util.ExcelUserLoader

echo.
echo ================================================================
echo.

if errorlevel 1 (
    echo Status: Completed with errors
) else (
    echo Status: Completed successfully!
)

echo.
pause

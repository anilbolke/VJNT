@echo off
REM VJNT Class Management - Compile and Run ExcelUserLoader
REM Simple batch script for Windows

echo.
echo ================================================================
echo   VJNT - Compile and Run ExcelUserLoader
echo ================================================================
echo.

cd /d "%~dp0"

REM Set paths
set SRC_PATH=src\main\java
set CLASSES_PATH=target\classes
set LIB_PATH=C:\Users\Admin\V2Project\Servers\AI Files\lib

REM Create classes directory
echo Step 1: Creating directories...
if not exist "%CLASSES_PATH%" mkdir "%CLASSES_PATH%"
echo   [OK] Classes directory ready
echo.

REM Build classpath
echo Step 2: Building classpath...
set CP=
for %%f in ("%LIB_PATH%\*.jar") do call :append_cp "%%f"
echo   [OK] Classpath built
echo.

REM Compile Java files
echo Step 3: Compiling Java sources...
dir /s /b "%SRC_PATH%\*.java" > sources.txt
javac -cp "%CP%" -d "%CLASSES_PATH%" -encoding UTF-8 @sources.txt
if errorlevel 1 (
    echo   [ERROR] Compilation failed!
    del sources.txt
    pause
    exit /b 1
)
del sources.txt
echo   [OK] Compilation successful!
echo.

REM Run ExcelUserLoader
echo Step 4: Running ExcelUserLoader...
echo.
echo ================================================================
echo.

set RUN_CP=%CLASSES_PATH%;%CP%
java -cp "%RUN_CP%" com.vjnt.util.ExcelUserLoader

echo.
echo ================================================================
echo.
echo Process completed!
echo.
pause
exit /b 0

:append_cp
if "%CP%"=="" (
    set CP=%~1
) else (
    set CP=%CP%;%~1
)
goto :eof

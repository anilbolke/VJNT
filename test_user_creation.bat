@echo off
echo ========================================
echo TESTING USER CREATION FOR UDISE 27150615002
echo ========================================
echo.

cd "C:\Users\Admin\V2Project\VJNT Class Managment"

echo Compiling test utilities...
javac -cp "lib/*;build/classes" -d build/classes src/main/java/com/vjnt/util/TestUserCreation.java 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Compilation failed
    pause
    exit /b 1
)

echo.
echo Running test...
echo.
java -cp "lib/*;build/classes" com.vjnt.util.TestUserCreation

echo.
echo ========================================
echo Test completed. Check output above.
echo ========================================
pause

@echo off
echo ========================================
echo VJNT Student Data + User Login Loader
echo ========================================
echo This will import:
echo   - All student records from Excel
echo   - Automatically create user logins
echo ========================================
echo.

cd /d "%~dp0"

REM Compile the Java files
echo Compiling Java files...
javac -encoding UTF-8 -source 1.8 -target 1.8 -cp "src/main/webapp/WEB-INF/lib/*" -d build/classes src/main/java/com/vjnt/model/*.java src/main/java/com/vjnt/dao/*.java src/main/java/com/vjnt/util/DatabaseConnection.java src/main/java/com/vjnt/util/PasswordUtil.java src/main/java/com/vjnt/util/ExcelStudentLoader.java

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Compilation failed!
    pause
    exit /b 1
)

echo.
echo Running Student Loader...
echo.
java -cp "src/main/webapp/WEB-INF/lib/*;build/classes" com.vjnt.util.ExcelStudentLoader

echo.
echo ========================================
echo Process completed!
echo ========================================
pause

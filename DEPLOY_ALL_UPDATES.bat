@echo off
echo ========================================
echo  Deploy All Updated Files
echo ========================================
echo.

echo Deploying JSP files...
xcopy /Y "src\main\webapp\*.jsp" "WebContent\" 2>nul
echo.

echo Deploying Servlets...
xcopy /Y "src\main\webapp\WEB-INF\classes\com\vjnt\servlet\*.class" "WebContent\WEB-INF\classes\com\vjnt\servlet\" 2>nul
echo.

echo Deploying DAOs...
xcopy /Y "src\main\webapp\WEB-INF\classes\com\vjnt\dao\*.class" "WebContent\WEB-INF\classes\com\vjnt\dao\" 2>nul
echo.

echo Deploying Models...
xcopy /Y "src\main\webapp\WEB-INF\classes\com\vjnt\model\*.class" "WebContent\WEB-INF\classes\com\vjnt\model\" 2>nul
echo.

echo Deploying Utilities...
xcopy /Y "src\main\webapp\WEB-INF\classes\com\vjnt\util\*.class" "WebContent\WEB-INF\classes\com\vjnt\util\" 2>nul
echo.

echo ========================================
echo  Deployment Complete!
echo ========================================
echo.
echo IMPORTANT: Restart Tomcat server to load new changes
echo.
pause

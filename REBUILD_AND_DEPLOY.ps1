# Quick Rebuild and Deploy Script
# This script cleans, rebuilds the project, and redeploys to Tomcat

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  VJNT Class Management - Clean Build & Deploy Script       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$projectPath = "C:\Users\Admin\V2Project\VJNT Class Managment"
$tomcatPath = "D:\apache-tomcat-9.0.100"

# Step 1: Stop Tomcat
Write-Host "[1/5] Stopping Tomcat server..." -ForegroundColor Yellow
$javaPids = Get-Process | Where-Object {$_.ProcessName -like "*java*" -and $_.CommandLine -like "*tomcat*"} | Select-Object -ExpandProperty Id
if ($javaPids) {
    foreach ($pid in $javaPids) {
        Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Stopped Java process ID: $pid"
    }
    Start-Sleep -Seconds 3
}
Write-Host ""

# Step 2: Clean old build files
Write-Host "[2/5] Cleaning old build files..." -ForegroundColor Yellow
cd $projectPath
if (Test-Path "build\classes") {
    Remove-Item "build\classes" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed build/classes"
}
if (Test-Path "build\war") {
    Remove-Item "build\war" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed build/war"
}
if (Test-Path "ROOT.war") {
    Remove-Item "ROOT.war" -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed ROOT.war"
}
if (Test-Path "$tomcatPath\webapps\ROOT") {
    Remove-Item "$tomcatPath\webapps\ROOT" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  ✓ Removed Tomcat ROOT folder"
}
Write-Host ""

# Step 3: Rebuild WAR
Write-Host "[3/5] Building WAR file..." -ForegroundColor Yellow
Write-Host "  ⚠ IMPORTANT: Eclipse must compile the project first!" -ForegroundColor Magenta
Write-Host "  " -ForegroundColor Magenta
Write-Host "  1. Switch to Eclipse window" -ForegroundColor Magenta
Write-Host "  2. Right-click 'VJNT Class Management' project" -ForegroundColor Magenta
Write-Host "  3. Click 'Clean Project' (Project menu or Ctrl+Alt+K)" -ForegroundColor Magenta
Write-Host "  4. Wait for rebuild to complete" -ForegroundColor Magenta
Write-Host "  5. Return here and press ENTER to continue" -ForegroundColor Magenta
Write-Host ""
Read-Host "Press ENTER after Eclipse finishes building"

# Verify build was successful
if (Test-Path "build\classes\com\vjnt\servlet\PublicSchoolLookupServlet.class") {
    Write-Host "  ✓ Compilation successful" -ForegroundColor Green
} else {
    Write-Host "  ✗ Compilation failed - classes not found!" -ForegroundColor Red
    Write-Host "  Please check Eclipse for build errors" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Create new WAR
Write-Host "[4/5] Creating ROOT.war..." -ForegroundColor Yellow

# Prepare WAR directory
if (Test-Path "build\war") {
    Remove-Item "build\war" -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path "build\war" -ErrorAction SilentlyContinue | Out-Null

# Copy web content
Copy-Item "src\main\webapp\*" -Destination "build\war\" -Recurse -Force
Write-Host "  ✓ Copied web content"

# Copy compiled classes
if (Test-Path "build\classes") {
    Copy-Item "build\classes\*" -Destination "build\war\WEB-INF\classes\" -Recurse -Force
    Write-Host "  ✓ Copied compiled classes"
}

# Create JAR/WAR file
cd "build\war"
if (Test-Path "..\ROOT.war") {
    Remove-Item "..\ROOT.war" -Force -ErrorAction SilentlyContinue
}
jar -cvf ..\ROOT.war * | Out-Null
cd ..\..
Write-Host "  ✓ WAR file created"

# Move to project root
Move-Item "build\ROOT.war" "ROOT.war" -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ ROOT.war ready"
Write-Host ""

# Step 5: Deploy to Tomcat
Write-Host "[5/5] Deploying to Tomcat..." -ForegroundColor Yellow
Copy-Item "ROOT.war" -Destination "$tomcatPath\webapps\ROOT.war" -Force
Write-Host "  ✓ ROOT.war copied to webapps"

# Start Tomcat
Write-Host "  Starting Tomcat..." -ForegroundColor Cyan
$catalinaScript = "$tomcatPath\bin\catalina.bat"
if (Test-Path $catalinaScript) {
    Start-Process -FilePath $catalinaScript -ArgumentList "start" -NoNewWindow
    Write-Host "  ✓ Tomcat starting..." -ForegroundColor Green
    Start-Sleep -Seconds 5
} else {
    Write-Host "  ⚠ Could not find catalina.bat" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  Build and Deployment Complete!                           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Wait 10-15 seconds for Tomcat to fully start"
Write-Host "2. Open browser and test:"
Write-Host "   http://localhost:8080/VJNT_Class_Managment/public-school-lookup?udise=27150201202"
Write-Host ""
Write-Host "Check Tomcat logs if issues occur:"
Write-Host "   $tomcatPath\logs\catalina.out"
Write-Host ""

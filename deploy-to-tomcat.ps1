# Deploy VJNT Class Management to Tomcat
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  VJNT - Deploy to Tomcat                                      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$projectPath = $PSScriptRoot
$buildClassesPath = Join-Path $projectPath "build\classes"
$webappPath = Join-Path $projectPath "src\main\webapp"
$deployPath = "C:\Users\Admin\V2Project\Servers\Tomcat v9.0 Server at localhost-config\wtpwebapps\VJNT_Class_Managment"

# Check if Tomcat is configured
if (-not (Test-Path "C:\Users\Admin\V2Project\Servers\Tomcat v9.0 Server at localhost-config")) {
    Write-Host "✗ Tomcat server configuration not found!" -ForegroundColor Red
    Write-Host "  Please configure Tomcat in Eclipse first." -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Checking compiled classes..." -ForegroundColor Yellow
if (-not (Test-Path $buildClassesPath)) {
    Write-Host "  ✗ Build classes not found!" -ForegroundColor Red
    Write-Host "  Please build the project in Eclipse first (Project -> Build Project)" -ForegroundColor Yellow
    exit 1
}
Write-Host "  ✓ Compiled classes found" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Creating deployment directory..." -ForegroundColor Yellow
if (Test-Path $deployPath) {
    Write-Host "  Cleaning existing deployment..." -ForegroundColor Yellow
    Remove-Item -Path $deployPath -Recurse -Force
}
New-Item -Path $deployPath -ItemType Directory -Force | Out-Null
Write-Host "  ✓ Deployment directory created" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Copying web content..." -ForegroundColor Yellow
Copy-Item -Path "$webappPath\*" -Destination $deployPath -Recurse -Force
Write-Host "  ✓ Web content copied" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Copying compiled classes..." -ForegroundColor Yellow
$webInfClasses = Join-Path $deployPath "WEB-INF\classes"
New-Item -Path $webInfClasses -ItemType Directory -Force | Out-Null
Copy-Item -Path "$buildClassesPath\*" -Destination $webInfClasses -Recurse -Force
Write-Host "  ✓ Compiled classes copied" -ForegroundColor Green
Write-Host ""

Write-Host "Step 5: Verifying deployment..." -ForegroundColor Yellow
$servletPath = Join-Path $webInfClasses "com\vjnt\servlet\LoginServlet.class"
if (Test-Path $servletPath) {
    Write-Host "  ✓ Servlets deployed successfully" -ForegroundColor Green
} else {
    Write-Host "  ✗ Warning: Servlet classes not found in deployment" -ForegroundColor Red
}
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open Eclipse" -ForegroundColor White
Write-Host "  2. Right-click on the Tomcat server in Servers view" -ForegroundColor White
Write-Host "  3. Select 'Clean...' and then 'Publish'" -ForegroundColor White
Write-Host "  4. Start the Tomcat server" -ForegroundColor White
Write-Host "  5. Access: http://localhost:8080/VJNT_Class_Managment/login.jsp" -ForegroundColor White
Write-Host ""
Write-Host "Context Path: /VJNT_Class_Managment" -ForegroundColor Yellow
Write-Host "Deployed to: $deployPath" -ForegroundColor Gray
Write-Host ""

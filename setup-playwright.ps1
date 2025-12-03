# Playwright Testing Setup Script for Windows PowerShell
# Run this script with: powershell -ExecutionPolicy Bypass -File setup-playwright.ps1

Write-Host "================================================================================`n" -ForegroundColor Cyan
Write-Host "           PLAYWRIGHT TESTING - VJNT CLASS MANAGEMENT SYSTEM`n" -ForegroundColor Cyan
Write-Host "================================================================================`n" -ForegroundColor Cyan

# Check Node.js installation
Write-Host "[*] Checking Node.js installation..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] Node.js found: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "[✗] Node.js not found! Please install from https://nodejs.org/" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check npm installation
Write-Host "[*] Checking npm installation..." -ForegroundColor Yellow
$npmVersion = npm --version 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "[✓] npm found: $npmVersion" -ForegroundColor Green
} else {
    Write-Host "[✗] npm not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n[*] Installing npm dependencies..." -ForegroundColor Yellow
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[✗] Failed to install npm dependencies" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n[*] Installing Playwright browsers..." -ForegroundColor Yellow
npx playwright install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[✗] Failed to install Playwright browsers" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "`n[✓] Setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Ensure Tomcat is running`n" -ForegroundColor White
Write-Host "  2. Run tests with: npm test`n" -ForegroundColor White
Write-Host "  3. View report with: npm run test:report`n" -ForegroundColor White

Read-Host "`nPress Enter to exit"

# VJNT Class Management - Excel User Loader
# PowerShell script to compile and run the loader

param([switch]$SkipCompile)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  VJNT - Excel User Loader  " -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Set working directory
$ProjectRoot = $PSScriptRoot
Set-Location $ProjectRoot

# Define paths
$SourceDir = Join-Path $ProjectRoot "src\main\java"
$ClassesDir = Join-Path $ProjectRoot "target\classes"
$LibDir = Join-Path $ProjectRoot "lib"

# Step 1: Build classpath
Write-Host "[1/3] Building classpath..." -ForegroundColor Yellow
$Jars = Get-ChildItem -Path $LibDir -Filter "*.jar" -ErrorAction SilentlyContinue
if ($Jars.Count -eq 0) {
    Write-Host "      ERROR: No JAR files found in lib folder!" -ForegroundColor Red
    exit 1
}
$ClassPath = $ClassesDir + ";" + (($Jars | ForEach-Object { $_.FullName }) -join ";")
Write-Host "      Found $($Jars.Count) JAR files" -ForegroundColor Green

# Step 2: Create classes directory
Write-Host "[2/3] Preparing directories..." -ForegroundColor Yellow
if (-not (Test-Path $ClassesDir)) {
    New-Item -Path $ClassesDir -ItemType Directory -Force | Out-Null
}
Write-Host "      Classes directory ready" -ForegroundColor Green

if (-not $SkipCompile) {
    # Step 3: Compile Java sources
    Write-Host "[3/3] Compiling Java sources..." -ForegroundColor Yellow
    
    # Get all Java files
    $JavaFiles = Get-ChildItem -Path $SourceDir -Filter "*.java" -Recurse
    Write-Host "      Found $($JavaFiles.Count) Java files to compile" -ForegroundColor White
    
    # Create temp file with all source files
    $SourcesList = Join-Path $ProjectRoot "sources_list.txt"
    $JavaFiles | ForEach-Object { $_.FullName } | Out-File -FilePath $SourcesList -Encoding ASCII
    
    # Compile
    $CompileArgs = @(
        "-cp", "`"$ClassPath`"",
        "-d", "`"$ClassesDir`"",
        "-encoding", "UTF-8",
        "@$SourcesList"
    )
    
    & javac $CompileArgs 2>&1 | ForEach-Object { Write-Host "      $_" }
    
    # Clean up
    Remove-Item $SourcesList -ErrorAction SilentlyContinue
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "      ERROR: Compilation failed!" -ForegroundColor Red
        exit 1
    }
    
    # Count compiled classes
    $ClassFiles = Get-ChildItem -Path $ClassesDir -Filter "*.class" -Recurse
    Write-Host "      Compiled $($ClassFiles.Count) class files" -ForegroundColor Green
}

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Running ExcelUserLoader..." -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Run the loader
$RunArgs = @(
    "-cp", "`"$ClassPath`"",
    "com.vjnt.util.ExcelUserLoader"
)

& java $RunArgs

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Process completed successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠ Process completed with errors (Exit code: $LASTEXITCODE)" -ForegroundColor Yellow
}

Write-Host ""

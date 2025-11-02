# VJNT Class Management - Compile and Run ExcelUserLoader
# This script compiles Java sources and runs the ExcelUserLoader

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  VJNT - Compile and Run ExcelUserLoader                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$projectPath = $PSScriptRoot
$srcPath = Join-Path $projectPath "src\main\java"
$classesPath = Join-Path $projectPath "target\classes"
$libPath = "C:\Users\Admin\V2Project\Servers\AI Files\lib"

# Create classes directory
Write-Host "Step 1: Creating directories..." -ForegroundColor Yellow
New-Item -Path $classesPath -ItemType Directory -Force | Out-Null
Write-Host "  ✓ Classes directory ready" -ForegroundColor Green
Write-Host ""

# Build classpath
Write-Host "Step 2: Building classpath..." -ForegroundColor Yellow
$jars = Get-ChildItem -Path $libPath -Filter "*.jar"
$classpath = ($jars | ForEach-Object { $_.FullName }) -join ";"
Write-Host "  ✓ Found $($jars.Count) JAR files" -ForegroundColor Green
Write-Host ""

# Compile Java files
Write-Host "Step 3: Compiling Java sources..." -ForegroundColor Yellow

# Get all Java files
$javaFiles = Get-ChildItem -Path $srcPath -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName

if ($javaFiles.Count -eq 0) {
    Write-Host "  ✗ No Java files found!" -ForegroundColor Red
    exit 1
}

Write-Host "  Found $($javaFiles.Count) Java files to compile" -ForegroundColor White

# Compile
$compileCmd = "javac -cp `"$classpath`" -d `"$classesPath`" -encoding UTF-8 $($javaFiles -join ' ')"

try {
    $output = & cmd /c $compileCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Compilation successful!" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Compilation failed!" -ForegroundColor Red
        Write-Host "$output" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ✗ Error during compilation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Verify compiled classes
$compiledFiles = Get-ChildItem -Path $classesPath -Filter "*.class" -Recurse
Write-Host "  Compiled $($compiledFiles.Count) class files" -ForegroundColor Green
Write-Host ""

# Run ExcelUserLoader
Write-Host "Step 4: Running ExcelUserLoader..." -ForegroundColor Yellow
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

$runClasspath = "$classesPath;$classpath"
$runCmd = "java -cp `"$runClasspath`" com.vjnt.util.ExcelUserLoader"

try {
    & cmd /c $runCmd
} catch {
    Write-Host ""
    Write-Host "✗ Error running ExcelUserLoader: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "✅ Process completed!" -ForegroundColor Green
Write-Host ""

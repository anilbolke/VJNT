Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recompiling Project with Java 21" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$env:JAVA_HOME = "C:\Users\Admin\.p2\pool\plugins\org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_21.0.8.v20250724-1412\jre"
$javac = "$env:JAVA_HOME\bin\javac.exe"

Write-Host "`nUsing Java version:"
& "$env:JAVA_HOME\bin\java.exe" -version

$projectDir = "C:\Users\Admin\V2Project\VJNT Class Managment"
Set-Location $projectDir

Write-Host "`nCleaning old classes..." -ForegroundColor Yellow
if (Test-Path "build\classes") {
    Remove-Item -Recurse -Force "build\classes\*"
} else {
    New-Item -ItemType Directory -Path "build\classes" -Force | Out-Null
}

Write-Host "`nSetting up classpath..." -ForegroundColor Yellow
$jars = @()
$jars += Get-ChildItem -Path "lib" -Filter "*.jar" -Recurse | ForEach-Object { $_.FullName }
$jars += "D:\apache-tomcat-9.0.100\lib\servlet-api.jar"
$jars += "D:\apache-tomcat-9.0.100\lib\jsp-api.jar"
$classpath = $jars -join ";"

Write-Host "`nCompiling Java sources..." -ForegroundColor Yellow
$sources = Get-ChildItem -Path "src" -Filter "*.java" -Recurse | Select-Object -ExpandProperty FullName

Write-Host "Found $($sources.Count) Java files"

$result = & $javac -cp $classpath -d "build\classes" -encoding UTF-8 $sources 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nCompilation FAILED!" -ForegroundColor Red
    $result | Select-Object -Last 50
    exit 1
}

Write-Host "`nCompilation SUCCESSFUL!" -ForegroundColor Green

Write-Host "`nCopying to Tomcat..." -ForegroundColor Yellow
$webappClasses = "D:\apache-tomcat-9.0.100\webapps\VJNT_Class_Managment\WEB-INF\classes"
if (!(Test-Path $webappClasses)) {
    New-Item -ItemType Directory -Path $webappClasses -Force | Out-Null
}
Copy-Item -Path "build\classes\*" -Destination $webappClasses -Recurse -Force

Write-Host "`nDone! Restart Tomcat to apply changes." -ForegroundColor Green

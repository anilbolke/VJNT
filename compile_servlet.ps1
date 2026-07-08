cd 'C:\Users\Admin\V2Project\VJNT Class Managment'

# Build classpath
$jars = Get-ChildItem 'lib\*.jar' | ForEach-Object { "`"$($_.FullName)`"" }
$cp = ($jars -join ';') + ';build\classes'

Write-Host "Compiling DivisionPhaseComparisonServlet..."
$cmd = 'javac', '-cp', $cp, '-d', 'build\classes', '-encoding', 'UTF-8', 'src\main\java\com\vjnt\servlet\DivisionPhaseComparisonServlet.java' -join ' '

Invoke-Expression $cmd

$jspFile = "C:\Users\Admin\V2Project\VJNT Class Managment\src\main\webapp\student-comprehensive-report-new.jsp"
$content = Get-Content $jspFile -Raw

# Replace ${ with ${'$'}{ in JavaScript template literals within script tags
# But preserve JSP expressions like <%= ... %>
$lines = $content -split "`r?`n"
$result = @()
$inScript = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    
    if ($line -match '^\s*<script') {
        $inScript = $true
        $result += $line
    }
    elseif ($line -match '^\s*</script>') {
        $inScript = $false
        $result += $line
    }
    elseif ($inScript) {
        # In script section - replace ${ with ${'$'}{ but not <%= 
        if ($line -match '\$\{' -and $line -notmatch '<%=') {
            # Replace ${variable} with ${'$'}{variable}
            $line = $line -replace '\$\{', "`${'`$'}{"
        }
        $result += $line
    }
    else {
        $result += $line
    }
}

$newContent = $result -join "`r`n"
Set-Content $jspFile -Value $newContent -NoNewline

Write-Host "Fixed! JavaScript template literals now use" '$' + "{'" + '$' + "'}" + "{"
Write-Host "Total lines processed: $($lines.Count)"

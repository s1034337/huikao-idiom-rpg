$lines = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'decoded_text.txt') -Encoding UTF8
$skip = @('會考歷屆','年度成語','成語釋義','整理者：','取其精神而遺其形式。')
$items = New-Object Collections.Generic.List[object]
$current = $null
$definition = New-Object Collections.Generic.List[string]
$year = 102
$digitBuffer = ''

function Save-Current {
    if ($null -ne $script:current) {
        $meaning = (($script:definition -join '') -replace '\s+','').Trim()
        if ($meaning.Length -ge 6) {
            $script:items.Add([PSCustomObject]@{ idiom=$script:current; meaning=$meaning; year=$script:year })
        }
    }
    $script:definition = New-Object Collections.Generic.List[string]
}

foreach ($raw in $lines) {
    $line = ($raw -replace '\s+','').Trim()
    if (-not $line) { continue }
    if ($line -match '^\d{1,2}$') {
        $digitBuffer += $line
        if ($digitBuffer.Length -gt 3) { $digitBuffer = $digitBuffer.Substring($digitBuffer.Length - 3) }
        if ($digitBuffer -match '^(10[2-9]|11[0-5])$') { $year = [int]$digitBuffer; $digitBuffer = ''; continue }
        continue
    }
    $digitBuffer = ''
    if ($line -match '^(10[2-9]|11[0-5])$') { $year = [int]$matches[1]; continue }
    if ($line -match '^[一-龥]{4}$' -and $skip -notcontains $line -and $line -notmatch '國中|老師|歷屆|年度|成語|釋義') {
        Save-Current
        $current = $line
    } elseif ($null -ne $current -and $line -notmatch '^(會考歷屆|成語|年度|釋義|整理者|七賢國中|熊寶老師)') {
        $definition.Add($line)
    }
}
Save-Current

$unique = $items | Group-Object idiom | ForEach-Object { $_.Group[0] } | Sort-Object year,idiom
$json = $unique | ConvertTo-Json -Depth 3 -Compress
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'data.js'), "const IDIOMS=$json;", (New-Object Text.UTF8Encoding($false)))
[PSCustomObject]@{ Count=$unique.Count; First=$unique[0].idiom; Last=$unique[-1].idiom }


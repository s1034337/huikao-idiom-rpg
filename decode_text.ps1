$lines = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'pdf_streams.txt')
$map = @{}
$inLargeCMap = $false
foreach ($line in $lines) {
    if ($line -eq '461 dict begin') { $inLargeCMap = $true; continue }
    if ($inLargeCMap -and $line -eq 'endcmap') { break }
    if (-not $inLargeCMap) { continue }
    if ($line -match '^<([0-9A-F]+)>\s+<([0-9A-F]+)>$') {
        $map[[Convert]::ToInt32($matches[1],16)] = [char][Convert]::ToInt32($matches[2],16)
    } elseif ($line -match '^<([0-9A-F]+)>\s+<([0-9A-F]+)>\s+\[(.+)\]$') {
        $start = [Convert]::ToInt32($matches[1],16)
        $values = [regex]::Matches($matches[3], '<([0-9A-F]+)>')
        for ($i = 0; $i -lt $values.Count; $i++) {
            $map[$start + $i] = [char][Convert]::ToInt32($values[$i].Groups[1].Value,16)
        }
    } elseif ($line -match '^<([0-9A-F]+)>\s+<([0-9A-F]+)>\s+<([0-9A-F]+)>$') {
        $start = [Convert]::ToInt32($matches[1],16)
        $end = [Convert]::ToInt32($matches[2],16)
        $target = [Convert]::ToInt32($matches[3],16)
        for ($code = $start; $code -le $end; $code++) {
            $map[$code] = [char]($target + $code - $start)
        }
    }
}

$decodedLines = New-Object Collections.Generic.List[string]
foreach ($line in $lines) {
    if ($line -notmatch 'TJ|Tj') { continue }
    $pieces = New-Object Collections.Generic.List[string]
    foreach ($hexMatch in [regex]::Matches($line, '<([0-9A-F]+)>')) {
        $hex = $hexMatch.Groups[1].Value
        $builder = New-Object Text.StringBuilder
        for ($i = 0; $i + 3 -lt $hex.Length; $i += 4) {
            $code = [Convert]::ToInt32($hex.Substring($i,4),16)
            if ($map.ContainsKey($code)) { [void]$builder.Append($map[$code]) }
        }
        if ($builder.Length -gt 0) { $pieces.Add($builder.ToString()) }
    }
    foreach ($plainMatch in [regex]::Matches($line, '\(([^)]*)\)')) {
        if ($plainMatch.Groups[1].Value.Trim().Length -gt 0) { $pieces.Add($plainMatch.Groups[1].Value) }
    }
    if ($pieces.Count -gt 0) { $decodedLines.Add(($pieces -join '')) }
}
$output = Join-Path $PSScriptRoot 'decoded_text.txt'
[IO.File]::WriteAllLines($output, $decodedLines, [Text.Encoding]::UTF8)
Get-Item $output | Select-Object FullName,Length

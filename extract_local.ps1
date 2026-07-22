$pdfPath = Join-Path $PSScriptRoot 'source.pdf'
$outputPath = Join-Path $PSScriptRoot 'pdf_streams.txt'
$encoding = [Text.Encoding]::GetEncoding(28591)
$bytes = [IO.File]::ReadAllBytes($pdfPath)
$text = $encoding.GetString($bytes)
$matches = [regex]::Matches($text, 'stream\s*(.*?)\s*endstream', 'Singleline')
$output = New-Object System.Text.StringBuilder
foreach ($match in $matches) {
    $data = $encoding.GetBytes($match.Groups[1].Value)
    foreach ($skip in 2, 0) {
        try {
            $input = New-Object IO.MemoryStream($data, $skip, ($data.Length - $skip))
            $deflate = New-Object IO.Compression.DeflateStream($input, [IO.Compression.CompressionMode]::Decompress)
            $buffer = New-Object IO.MemoryStream
            $deflate.CopyTo($buffer)
            $decoded = $encoding.GetString($buffer.ToArray())
            if ($decoded.Length -gt 0) {
                [void]$output.AppendLine('---STREAM---')
                [void]$output.AppendLine($decoded)
                break
            }
        } catch {}
    }
}
[IO.File]::WriteAllText($outputPath, $output.ToString(), [Text.Encoding]::UTF8)
Get-Item -LiteralPath $outputPath | Select-Object FullName, Length

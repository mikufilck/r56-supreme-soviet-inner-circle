# 找中文马克思主义文库【列宁】区的正确 URL 结构（2026-09-16）
$proxy = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\rykov\leninprobe'
$null = New-Item -ItemType Directory -Force -Path $outDir

$cands = @(
    'https://www.marxists.org/chinese/lenin/index.htm',
    'https://www.marxists.org/chinese/lenin-cworks/index.htm',
    'https://www.marxists.org/chinese/lenin/1923/index.htm',
    'https://www.marxists.org/chinese/subject/lenin/index.htm'
)
foreach ($u in $cands) {
    $f = Join-Path $outDir (([uri]$u).AbsolutePath -replace '[/\\]', '_') 
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 40 -o "$f.html" -w '%{http_code}' $u 2>$null
    $len = if (Test-Path -LiteralPath "$f.html") { (Get-Item -LiteralPath "$f.html").Length } else { 0 }
    Write-Host ('{0,4} {1,8} 字节  {2}' -f $code, $len, $u)
}
Write-Host ''
Write-Host '--- 从 200 的页面里抽链接 ---'
$rep = @()
foreach ($h in Get-ChildItem -LiteralPath $outDir -File -Filter *.html) {
    if ($h.Length -lt 5000) { continue }
    $t = [System.IO.File]::ReadAllText($h.FullName, [System.Text.Encoding]::UTF8)
    $rep += "=== $($h.Name) ($($h.Length) 字节) ==="
    $n = 0
    foreach ($m in [regex]::Matches($t, '(?i)href="([^"]+\.htm)"')) {
        $u = $m.Groups[1].Value
        if ($u -match '^\d{4}' -or $u -match 'lenin') { $rep += ('  ' + $u); $n++ }
        if ($n -ge 40) { break }
    }
    $rep += ''
}
$rep | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'lenin-probe-report.txt') -Encoding utf8
Get-Content -LiteralPath (Join-Path $PSScriptRoot 'lenin-probe-report.txt')

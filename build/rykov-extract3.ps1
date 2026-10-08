# 探测结果 -> 纯文本 + 抽出 marxists.org 链接（2026-09-16）
$ErrorActionPreference = 'Continue'
function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?is)<sup.*?</sup>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n")
    $t = [regex]::Replace($t, '(?i)</p>', "`n`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n`n")
    $t = [regex]::Replace($t, '(?i)</li>', "`n")
    $t = [regex]::Replace($t, '(?i)</div>', "`n")
    $t = [regex]::Replace($t, '(?is)<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '[ \t]+', ' ')
    $t = [regex]::Replace($t, '(\r?\n){3,}', "`n`n")
    return $t.Trim()
}
$src = Join-Path $PSScriptRoot '..\tmp\rykov\probe'
$dst = Join-Path $PSScriptRoot '..\tmp\rykov\txt3'
$null = New-Item -ItemType Directory -Force -Path $dst
foreach ($f in Get-ChildItem -LiteralPath $src -File -Filter *.html) {
    $html = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $txt  = Convert-HtmlToText $html
    [System.IO.File]::WriteAllText((Join-Path $dst ($f.BaseName + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ('{0,-20} {1,8:N0} 字符' -f $f.BaseName, $txt.Length)
}
# DDG 结果里的外链
$o = @(); $o += '=== DDG: site:marxists.org Rykov ==='
$ddg = Get-Content -LiteralPath (Join-Path $src 'ddg_rykov_speech.html') -Raw
foreach ($m in [regex]::Matches($ddg, 'uddg=([^&"]+)')) {
    $u = [System.Uri]::UnescapeDataString($m.Groups[1].Value)
    if ($u -notmatch 'duckduckgo') { $o += ('  ' + $u) }
}
$o += ''
$o += '=== DDG: 李可夫 列宁 评价 ==='
$ddg2 = Get-Content -LiteralPath (Join-Path $src 'ddg_rykov_cn.html') -Raw
foreach ($m in [regex]::Matches($ddg2, 'uddg=([^&"]+)')) {
    $u = [System.Uri]::UnescapeDataString($m.Groups[1].Value)
    if ($u -notmatch 'duckduckgo') { $o += ('  ' + $u) }
}
$o | Select-Object -Unique | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'rykov-links-report.txt') -Encoding utf8
Write-Host ''
Write-Host '--- build/rykov-links-report.txt ---'
Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rykov-links-report.txt')

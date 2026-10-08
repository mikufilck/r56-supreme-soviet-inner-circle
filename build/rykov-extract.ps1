# =============================================================================
# 李可夫素材：HTML -> 纯文本（第二批）—— 2026-09-16
# 复用 build/fetch-trotsky.ps1 的 Convert-HtmlToText（三个坑：编码探测 / 不走管道 / -x 代理）
# =============================================================================
$ErrorActionPreference = 'Continue'

function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?is)<sup.*?</sup>', '')          # 去掉 [1] 这类脚注角标
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

$srcDir = Join-Path $PSScriptRoot '..\tmp\rykov\src2'
$dstDir = Join-Path $PSScriptRoot '..\tmp\rykov\txt2'
$null = New-Item -ItemType Directory -Force -Path $dstDir

$report = @()
foreach ($f in Get-ChildItem -LiteralPath $srcDir -File -Filter *.html) {
    $html = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $txt  = Convert-HtmlToText $html
    $out  = Join-Path $dstDir ($f.BaseName + '.txt')
    [System.IO.File]::WriteAllText($out, $txt, (New-Object System.Text.UTF8Encoding($false)))
    $report += ('{0,-24} {1,9:N0} 字符 -> {2}' -f $f.BaseName, $txt.Length, (Split-Path $out -Leaf))
    Write-Host $report[-1]
}
$report | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'rykov-extract-report.txt') -Encoding utf8
Write-Host ''
Write-Host '--- 报告已写入 build/rykov-extract-report.txt ---'

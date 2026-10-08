# =============================================================================
# 中文马克思主义文库 · 列宁（1918–1926）全文检索「李可夫」（2026-09-16）
# -----------------------------------------------------------------------------
# 目的：AGENTS 规则 9 要求国策描述是【原文节选 + 出处】。李可夫本人无中文文集，
#       所以退到第二档「历史上他人评价或记述的原文」—— 列宁是最直接的来源。
#
# 做法：把列宁区索引页里 1918–1926 的链接全抽出来 → 全部下载 → 转文本
#       → 全文找「李可夫」，命中的把上下文打出来。
# 坑：编码要探测（页面混杂 GB / UTF-8）；一律落盘，不走控制台管道。
# =============================================================================
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$root  = Join-Path $PSScriptRoot '..\tmp\rykov\lenin'
$htmlDir = Join-Path $root 'html'
$txtDir  = Join-Path $root 'txt'
$null = New-Item -ItemType Directory -Force -Path $htmlDir, $txtDir

$idx = Join-Path $htmlDir '_index.htm'
$null = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $idx 'https://www.marxists.org/chinese/lenin/index.htm'

function Read-TextAuto([string]$path) {
    $b = [System.IO.File]::ReadAllBytes($path)
    try { $e = New-Object System.Text.UTF8Encoding($false, $true); return $e.GetString($b) }
    catch { return [System.Text.Encoding]::GetEncoding(936).GetString($b) }
}
function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n")
    $t = [regex]::Replace($t, '(?i)</p>', "`n`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n`n")
    $t = [regex]::Replace($t, '(?is)<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '[ \t]+', ' ')
    $t = [regex]::Replace($t, '(\r?\n){3,}', "`n`n")
    return $t.Trim()
}

$html = Read-TextAuto $idx
$links = @()
foreach ($m in [regex]::Matches($html, '(?i)href="([^"]+\.htm)"')) {
    $u = $m.Groups[1].Value
    $y = $null
    if ($u -match '(?:lenin[-_])?(1[89]\d\d|20\d\d)\d{0,4}') { $y = [int]$Matches[1] }
    if ($y -and $y -ge 1918 -and $y -le 1926) {
        $abs = if ($u -match '^https?://') { $u } else { New-Object System.Uri([uri]'https://www.marxists.org/chinese/lenin/', $u) }
        $links += $abs.AbsoluteUri
    }
}
$links = @($links | Select-Object -Unique)
Write-Host ("列宁区索引：抽出 1918-1926 链接 {0} 个" -f $links.Count)

$rep = @(); $rep += ("链接数 = {0}" -f $links.Count)
$hits = @()
$n = 0
foreach ($u in $links) {
    $n++
    $name = ([uri]$u).AbsolutePath.Split('/')[-1]
    $f = Join-Path $htmlDir $name
    if (-not (Test-Path -LiteralPath $f) -or (Get-Item -LiteralPath $f).Length -lt 500) {
        $null = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 40 -o $f $u 2>$null
    }
    if (-not (Test-Path -LiteralPath $f)) { continue }
    if ((Get-Item -LiteralPath $f).Length -lt 800) { continue }
    $t = Convert-HtmlToText (Read-TextAuto $f)
    [System.IO.File]::WriteAllText((Join-Path $txtDir ($name -replace '\.htm$', '.txt')), $t, (New-Object System.Text.UTF8Encoding($false)))
    if ($t -match '李可夫') {
        $hits += $name
        foreach ($mm in [regex]::Matches($t, '.{80}李可夫.{120}')) {
            $rep += ("[{0}] ...{1}..." -f $name, ($mm.Value -replace '\s+', ' '))
        }
    }
    if ($n % 20 -eq 0) { Write-Host ("  ...{0}/{1}" -f $n, $links.Count) }
}
$rep += ''
$rep += ("命中「李可夫」的文件 {0} / {1}" -f $hits.Count, $links.Count)
$rep += ($hits -join ', ')
$rep | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'lenin-rykov-hits.txt') -Encoding utf8
Write-Host ''
Write-Host ("命中 {0} / {1}" -f $hits.Count, $links.Count)
Write-Host '--- build/lenin-rykov-hits.txt ---'

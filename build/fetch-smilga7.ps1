# 斯米尔加（Idx 10）材料抓取 · 第 7 批 —— 托洛茨基《斯大林评传》中译本（内文章节）
#  理由：en 维基引 "Stalin, vol.2" pp.107-108 / 128 两处（1919-07 六人革军委、1921 十大指控）
#  做法：抓第 8~16 章 + 找下册入口 -> 统计「斯米尔加」命中
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$base   = 'https://www.marxists.org/chinese/trotsky/1946/'
$outDir = Join-Path $PSScriptRoot '..\tmp\smilga\txt'
$srcDir = Join-Path $PSScriptRoot '..\tmp\smilga\src'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$script:log = @()

function Decode-Bytes {
    param([byte[]]$Bytes)
    try {
        $enc = [System.Text.Encoding]::GetEncoding('utf-8',
               [System.Text.EncoderFallback]::ExceptionFallback,
               [System.Text.DecoderFallback]::ExceptionFallback)
        return $enc.GetString($Bytes)
    } catch { return [System.Text.Encoding]::GetEncoding(936).GetString($Bytes) }
}

function Plain-Text {
    param([string]$Html)
    $t = $Html -replace '(?i)<br\s*/?>', "`n" -replace '(?i)</p>', "`n" -replace '(?i)</div>', "`n"
    $t = $t -replace '(?i)<script.*?</script>', '' -replace '(?i)<style.*?</style>', ''
    $t = [regex]::Replace($t, '<[^>]+>', '')
    $t = $t -replace '&nbsp;', ' ' -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"'
    return ($t -replace "`r", '')
}

$script:log += '=== 托洛茨基《斯大林评传》中译本 ==='
foreach ($n in 4..20) {
    $tag = ('stalin1946-{0:d2}' -f $n)
    $u = $base + ('trotsky_1946book{0:d2}.htm' -f $n)
    $f = Join-Path $srcDir ($tag + '.html')
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 120 -o $f -w '%{http_code}' $u 2>$null
    if ("$c" -ne '200') { $script:log += ('  [{0}] HTTP {1}  <- {2}' -f $tag, $c, $u); continue }
    $h = Decode-Bytes ([System.IO.File]::ReadAllBytes($f))
    $pt = Plain-Text $h
    [System.IO.File]::WriteAllText((Join-Path $outDir ($tag + '.txt')), $pt, (New-Object System.Text.UTF8Encoding($false)))
    $cnt = ([regex]::Matches($pt, '斯米尔加')).Count
    $title = ''
    $mt = [regex]::Match($pt, '(第[一二三四五六七八九十]+章[^\n]{0,40})')
    if ($mt.Success) { $title = $mt.Groups[1].Value.Trim() }
    $script:log += ('  [{0}] {1,8:N0} 字符  斯米尔加 x{2}  {3}' -f $tag, $pt.Length, $cnt, $title)
    if ($cnt -gt 0) {
        $lines = @($pt -split "`n")
        $ctx = @()
        for ($k = 0; $k -lt $lines.Count; $k++) {
            if ($lines[$k] -match '斯米尔加') {
                $a = [Math]::Max(0, $k - 3); $b = [Math]::Min($lines.Count - 1, $k + 3)
                for ($j = $a; $j -le $b; $j++) { $ctx += ('  ' + $lines[$j].Trim()) }
                $ctx += '  --------------------------'
            }
        }
        [System.IO.File]::WriteAllLines((Join-Path $outDir ($tag + '-hits.txt')), $ctx, (New-Object System.Text.UTF8Encoding($false)))
        $script:log += ('      -> {0}-hits.txt  共 {1} 段' -f $tag, ([regex]::Matches($pt, '斯米尔加')).Count)
    }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga7-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

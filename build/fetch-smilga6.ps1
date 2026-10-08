# 斯米尔加（Idx 10）材料抓取 · 第 6 批 —— 多伊彻《被解除武装的先知》(1921-1929) 全书
#  理由：这是覆盖他【经济工作 + 反对派 + 1927-06 送行示威】的中译本（en 维基的脚注就是这本）
#  做法：抓索引 -> 逐章抓 -> 统计「斯米尔加」命中（照托洛茨基线抓《我的生平》的做法）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smilga\txt'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$srcDir = Join-Path $PSScriptRoot '..\tmp\smilga\src'
$null   = New-Item -ItemType Directory -Force -Path $srcDir
$script:log = @()

function Curl-To {
    param([string]$Url, [string]$File)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 120 -o $File -w '%{http_code}' $Url 2>$null
    $l = if (Test-Path -LiteralPath $File) { (Get-Item -LiteralPath $File).Length } else { 0 }
    return @{ Code = "$c"; Len = $l }
}

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
    $t = $t -replace "`r", ''
    return $t
}

# ---- ① 中卷索引 ----
$base = 'https://www.marxists.org/chinese/isaac-deutscher/1959book/'
$idxUrl = $base + 'deutcher-1959bookindex.htm'
$f = Join-Path $srcDir 'deutscher-1959-index.html'
$r = Curl-To -Url $idxUrl -File $f
$script:log += ('=== ① 中卷索引 HTTP {0}  {1:N0} 字节 ===' -f $r.Code, $r.Len)
if ($r.Code -ne '200') { $script:log | ForEach-Object { Write-Host $_ }; exit }

$raw = Decode-Bytes ([System.IO.File]::ReadAllBytes($f))
$idxTxt = Plain-Text $raw
[System.IO.File]::WriteAllText((Join-Path $srcDir 'deutscher-1959-index.txt'), $idxTxt, (New-Object System.Text.UTF8Encoding($false)))

# 抽章节链接
$chapters = @()
foreach ($m in [regex]::Matches($raw, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+\.htm[l]?)"?[^>]*>(.*?)</a>')) {
    $href = $m.Groups[1].Value
    $t2 = (([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim() -replace '\s+', ' ')
    if ($href -notmatch '^(#|mailto|javascript|http)' -and $t2.Length -gt 1) {
        $chapters += [pscustomobject]@{ Title = $t2; Url = ($base + $href) }
    }
}
$script:log += ('  抽到 {0} 个链接' -f $chapters.Count)

# ---- ② 逐章抓 + 统计命中 ----
$script:log += '=== ② 逐章抓取（含「斯米尔加」命中数）==='
$i = 0
$hitsAll = @()
foreach ($c in $chapters) {
    $i++
    $tag = ('d1959-{0:d2}' -f $i)
    $cf = Join-Path $srcDir ($tag + '.html')
    $rr = Curl-To -Url $c.Url -File $cf
    if ($rr.Code -ne '200' -or $rr.Len -lt 400) {
        $script:log += ('  [{0}] HTTP {1} 跳过  {2}' -f $tag, $rr.Code, $c.Title)
        continue
    }
    $h = Decode-Bytes ([System.IO.File]::ReadAllBytes($cf))
    $pt = Plain-Text $h
    [System.IO.File]::WriteAllText((Join-Path $outDir ($tag + '.txt')), $pt, (New-Object System.Text.UTF8Encoding($false)))
    $n = ([regex]::Matches($pt, '斯米尔加')).Count
    $script:log += ('  [{0}] {1,7:N0} 字符  斯米尔加 x{2}  {3}' -f $tag, $pt.Length, $n, $c.Title)
    if ($n -gt 0) {
        $hitsAll += $tag
        # 把命中行连上下文写入单独文件
        $lines = @($pt -split "`n")
        $ctx = @()
        for ($k = 0; $k -lt $lines.Count; $k++) {
            if ($lines[$k] -match '斯米尔加') {
                $a = [Math]::Max(0, $k - 2); $b = [Math]::Min($lines.Count - 1, $k + 2)
                for ($j = $a; $j -le $b; $j++) { $ctx += ('  ' + $lines[$j].Trim()) }
                $ctx += '  ----'
            }
        }
        [System.IO.File]::WriteAllLines((Join-Path $outDir ($tag + '-hits.txt')), $ctx, (New-Object System.Text.UTF8Encoding($false)))
    }
}
$script:log += ('  ⭐ 有命中的章节：' + ($hitsAll -join ', '))

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga6-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

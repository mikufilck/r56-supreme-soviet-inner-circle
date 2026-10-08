# 斯米尔加（Idx 10）材料抓取 · 第 5 批 —— 中译本正文
#  ① 多伊彻（Isaac Deutscher）——《先知三部曲》（1927-06 雅罗斯拉夫尔车站送行示威 在这本里）
#  ② 托洛茨基《斯大林评传》（1946 中译本）
#  ③ 托洛茨基《俄国革命史》（1917 芬兰）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smilga\src'
$null   = New-Item -ItemType Directory -Force -Path $outDir
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

function Grab-Text {
    param([string]$Url, [string]$Tag)
    $f = Join-Path $outDir ($Tag + '.html')
    $r = Curl-To -Url $Url -File $f
    $script:log += ('  HTTP {0}  {1:N0} 字节  <- {2}' -f $r.Code, $r.Len, $Url)
    if ($r.Code -ne '200' -or $r.Len -lt 400) { return $null }
    $txt = Decode-Bytes ([System.IO.File]::ReadAllBytes($f))
    [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
    return $txt
}

# ---- ① 多伊彻索引 ----
$script:log += '=== ① 多伊彻（Isaac Deutscher）索引 ==='
$t = Grab-Text -Url 'https://www.marxists.org/chinese/isaac-deutcher/index.htm' -Tag 'deutscher-index'
if ($t) {
    $script:log += ('      -> deutscher-index.txt  {0:N0} 字符' -f $t.Length)
    foreach ($m in [regex]::Matches($t, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+)"?[^>]*>(.*?)</a>')) {
        $t2 = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($t2 -match '先知|武装|解除|托洛茨基|斯大林') { $script:log += ('      ⭐ {0}  ->  {1}' -f $t2, $m.Groups[1].Value) }
    }
}

# ---- ② 斯大林评传 ----
$script:log += '=== ② 托洛茨基《斯大林评传》 ==='
$t2 = Grab-Text -Url 'https://www.marxists.org/chinese/trotsky/1946/trotsky_1946book.htm' -Tag 'stalin1946'
if ($t2) {
    $script:log += ('      -> stalin1946.txt  {0:N0} 字符' -f $t2.Length)
    $n = ([regex]::Matches($t2, '斯米尔加')).Count
    $script:log += ('      ⭐ 该页「斯米尔加」出现 {0} 次' -f $n)
    foreach ($m in [regex]::Matches($t2, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+)"?[^>]*>(.*?)</a>')) {
        $t3 = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($t3 -match '第[一二三四五六七八九十]+') { $script:log += ('      {0}  ->  {1}' -f $t3, $m.Groups[1].Value) }
    }
}

# ---- ③ 俄国革命史 ----
$script:log += '=== ③ 托洛茨基《俄国革命史》 ==='
foreach ($u in @('https://www.marxists.org/chinese/trotsky/1930book/trotsky-1930bookindex.htm',
                 'https://www.marxists.org/chinese/trotsky/1930/index.htm')) {
    $t3 = Grab-Text -Url $u -Tag ('revhist-' + [Math]::Abs($u.GetHashCode() % 977))
    if ($t3) { $script:log += ('      -> {0:N0} 字符' -f $t3.Length) }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga5-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

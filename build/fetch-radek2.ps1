# 拉狄克 中文一手件抓取（中文马克思主义文库，GB2312）
#  篇目页 https://www.marxists.org/chinese/radek/index.htm 已确认存在（26 条）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$base   = 'https://www.marxists.org/chinese/radek/'
$outDir = Join-Path $PSScriptRoot '..\tmp\radek\txt'
$null   = New-Item -ItemType Directory -Force -Path $outDir

$items = [ordered]@{
    # ⭐ 自传两版（本人审定 —— 最权威）
    '1926_autobio'    = $base + 'mia-chinese-radek-1926.htm'
    'autobio_book'    = 'https://www.marxists.org/chinese/reference-books/autobiography-of-bolsheviks/28.htm'
    # 共产国际时期
    '1920_ci2'        = $base + 'mia-chinese-radek-192006-07.htm'
    '1921_ci3'        = 'https://www.marxists.org/chinese/communist-international/3-192106-07/013.htm'
    # 德国革命相关
    '1923_organizer'  = $base + 'mia-chinese-radek-19230824.htm'
    '19240122_conf'   = $base + 'mia-chinese-radek-19240122.htm'
    # 反对派时期
    '192608_opp'      = $base + 'mia-chinese-radek-192608.htm'
    '1927_plenum'     = $base + 'mia-chinese-radek-19270812.htm'
    # 中国
    '19241026_china'  = $base + 'mia-chinese-radek-19241026.htm'
    '19260530_china1y' = $base + 'mia-chinese-radek-19260530.htm'
    '19270121_lenin_cn' = $base + 'mia-chinese-radek-19270121.htm'
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

function Strip-Html {
    param([string]$H)
    $t = $H -replace '(?is)<script.*?</script>', ''
    $t = $t -replace '(?is)<style.*?</style>', ''
    $t = $t -replace '(?is)<br\s*/?>', "`r`n"
    $t = $t -replace '(?is)</p>', "`r`n"
    $t = $t -replace '(?is)<[^>]+>', ''
    $t = $t -replace '&nbsp;', ' '
    $t = $t -replace '&amp;', '&'
    $t = $t -replace '&lt;', '<'
    $t = $t -replace '&gt;', '>'
    $t = $t -replace '&quot;', '"'
    $lines = @($t -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    return ($lines -join "`r`n")
}

$rep = @()
foreach ($k in $items.Keys) {
    $f = Join-Path $outDir ($k + '.html')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $f -w '%{http_code}' $items[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $line = ('{0,-20} HTTP {1}  {2,9:N0} 字节' -f $k, $code, $len)
    if ($code -eq '200' -and $len -gt 300) {
        $txt = Strip-Html (Decode-Bytes ([System.IO.File]::ReadAllBytes($f)))
        [System.IO.File]::WriteAllText((Join-Path $outDir ($k + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
        $line += ('   -> {0}.txt  {1:N0} 字符' -f $k, $txt.Length)
    }
    $rep += $line
    Write-Host $line
}
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-radek2-report.txt'), $rep, (New-Object System.Text.UTF8Encoding($false)))
Write-Host '报告 -> fetch-radek2-report.txt'

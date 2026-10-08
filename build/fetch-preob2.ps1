# 普列奥布拉任斯基 中文一手件抓取（中文马克思主义文库，GB2312）
#  篇目页 https://www.marxists.org/chinese/preobrazhensky/index.htm 已确认存在（11 条）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$base   = 'https://www.marxists.org/chinese/preobrazhensky/'
$outDir = Join-Path $PSScriptRoot '..\tmp\preob\txt'
$null   = New-Item -ItemType Directory -Force -Path $outDir

$items = [ordered]@{
    '1919_abc'        = 'https://www.marxists.org/chinese/bukharin/1919/index.htm'
    '1926_newecon'    = $base + 'the-new-economics.htm'
    '191804_leftcom'  = $base + 'mia-chinese-preobrazhensky-191804.htm'
    '192203_agrarian' = $base + 'mia-chinese-preobrazhensky-192203.htm'
    '19231128_party'  = $base + 'mia-chinese-preobrazhensky-19231128.htm'
    '19231212_res'    = $base + 'mia-chinese-preobrazhensky-19231212.htm'
    '19240112_res'    = $base + 'mia-chinese-preobrazhensky-19240112.htm'
    '19240120_conf'   = $base + 'mia-chinese-preobrazhensky-19240120.htm'
    '19240528_cong'   = $base + 'mia-chinese-preobrazhensky-19240528.htm'
    '192708_letter'   = $base + 'mia-chinese-preobrazhensky-192708.htm'
}

function Decode-Bytes {
    param([byte[]]$Bytes)
    # 中文马克思主义文库的页面编码不统一 —— 主 index 是 GB、子目录可能是 UTF-8
    try {
        $enc = [System.Text.Encoding]::GetEncoding('utf-8',
               [System.Text.EncoderFallback]::ExceptionFallback,
               [System.Text.DecoderFallback]::ExceptionFallback)
        return $enc.GetString($Bytes)
    } catch {
        return [System.Text.Encoding]::GetEncoding(936).GetString($Bytes)
    }
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
    # 去掉空行堆积
    $lines = @($t -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    return ($lines -join "`r`n")
}

$rep = @()
foreach ($k in $items.Keys) {
    $f = Join-Path $outDir ($k + '.html')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $f -w '%{http_code}' $items[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $line = ('{0,-16} HTTP {1}  {2,9:N0} 字节' -f $k, $code, $len)
    if ($code -eq '200' -and $len -gt 300) {
        $txt = Strip-Html (Decode-Bytes ([System.IO.File]::ReadAllBytes($f)))
        [System.IO.File]::WriteAllText((Join-Path $outDir ($k + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
        $line += ('   -> {0}.txt  {1:N0} 字符' -f $k, $txt.Length)
    }
    $rep += $line
    Write-Host $line
}
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-preob2-report.txt'), $rep, (New-Object System.Text.UTF8Encoding($false)))
Write-Host '报告 -> fetch-preob2-report.txt'

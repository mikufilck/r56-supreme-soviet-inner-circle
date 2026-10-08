# 斯米尔诺夫 第三批：塞尔日《伊·尼·斯米尔诺夫之死》 + 文库中文站点结构探测
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\mia'
$null   = New-Item -ItemType Directory -Force -Path $outDir

function Grab([string]$url, [string]$key) {
    $f = Join-Path $outDir ($key + '.html')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $url 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    Write-Host ('{0,-24} {1} {2,9:N0} 字节  {3}' -f $key, $code, $len, $url)
    return @{ code = $code; len = $len; file = $f }
}

$r = Grab 'https://www.marxists.org/archive/serge/1936/08/smirnov.htm' 'serge-smirnov'
if ($r.code -eq '200') {
    $h = [System.IO.File]::ReadAllText($r.file, [System.Text.Encoding]::UTF8)
    $t = [regex]::Replace($h, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?is)<br\s*/?>', "`n")
    $t = [regex]::Replace($t, '(?is)</p>', "`n`n")
    $t = [regex]::Replace($t, '<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '(?m)^[ \t]+', '')
    $t = [regex]::Replace($t, '\n{3,}', "`n`n").Trim()
    [System.IO.File]::WriteAllText((Join-Path $outDir 'serge-smirnov.txt'), $t, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ('      -> serge-smirnov.txt  {0:N0} 字符' -f $t.Length)
}

# 文库中文站点：找人物索引 / 搜索页
$null = Grab 'https://www.marxists.org/chinese/abc/index.htm'      'cn-abc'
$null = Grab 'https://www.marxists.org/chinese/search/index.html'  'cn-search'
# 直接试探「斯米尔诺夫」篇目页是否存在
$null = Grab 'https://www.marxists.org/chinese/smirnov/index.htm'  'cn-smirnov'
$null = Grab 'https://www.marxists.org/chinese/s/index.htm'        'cn-s'

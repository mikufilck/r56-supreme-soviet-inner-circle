# 斯米尔诺夫 第六批：MIA 英文词汇表 / ETOL 作家页 / 托洛茨基著作索引（找 1936 年关于审判的文章）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\mia'
$null   = New-Item -ItemType Directory -Force -Path $outDir

function Grab([string]$url, [string]$key) {
    $f = Join-Path $outDir ($key + '.html')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $url 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    Write-Host ('{0,-16} {1} {2,9:N0} 字节' -f $key, $code, $len)
    return @{ code = $code; len = $len; file = $f }
}

$jobs = [ordered]@{
    'glossary-s' = 'https://www.marxists.org/glossary/people/s/index.htm'
    'etol-smirnov' = 'https://www.marxists.org/history/etol/writers/smirnov/index.htm'
    'trot-works' = 'https://www.marxists.org/archive/trotsky/works/index.htm'
    'bulletin-idx' = 'https://www.marxists.org/history/etol/newspape/bulletin/index.htm'
}
foreach ($k in $jobs.Keys) { $null = Grab $jobs[$k] $k }

# 从词汇表里抽 Smirnov 条目
$f = Join-Path $outDir 'glossary-s.html'
if (Test-Path -LiteralPath $f) {
    $h = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
    $txt = [regex]::Replace($h, '(?is)<script.*?</script>', '')
    $txt = [regex]::Replace($txt, '(?is)<br\s*/?>', "`n")
    $txt = [regex]::Replace($txt, '(?is)</p>', "`n`n")
    $txt = [regex]::Replace($txt, '<[^>]+>', '')
    $txt = [System.Net.WebUtility]::HtmlDecode($txt)
    $txt = [regex]::Replace($txt, '\n{3,}', "`n`n")
    $i = $txt.IndexOf('Smirnov')
    if ($i -ge 0) {
        $seg = $txt.Substring([Math]::Max(0, $i - 200), [Math]::Min(2500, $txt.Length - [Math]::Max(0, $i - 200)))
        [System.IO.File]::WriteAllText((Join-Path $outDir 'glossary-smirnov.txt'), $seg, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host '  -> glossary-smirnov.txt 已写'
    } else { Write-Host '  ⚠️ 词汇表页里没找到 Smirnov' }
}

# 托洛茨基著作索引里 1936 年的链接
$f = Join-Path $outDir 'trot-works.html'
if (Test-Path -LiteralPath $f) {
    $h = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
    $o = @('=== 托洛茨基著作索引（含 1936 的行）===')
    foreach ($m in [regex]::Matches($h, '(?is)<a\s+[^>]*href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>')) {
        $t = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($t -match '1936|Moscow|Trial') { $o += ('  {0,-70} {1}' -f $t, $m.Groups[1].Value) }
    }
    [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'smirnov-trot-works.txt'), $o, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ('  -> build\smirnov-trot-works.txt  {0} 条' -f ($o.Count - 1))
}

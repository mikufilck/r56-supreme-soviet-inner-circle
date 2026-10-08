# 斯米尔诺夫 第七批：托洛茨基 1936 年关于第一次莫斯科审判的访谈（找提到斯米尔诺夫处）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\mia'
$null   = New-Item -ItemType Directory -Force -Path $outDir

$jobs = [ordered]@{
    'trot-moscowtrial' = 'https://www.marxists.org/archive/trotsky/1936/09/moscowtrial.htm'
    'trot-confession'  = 'https://www.marxists.org/archive/trotsky/1936/03/confession.htm'
}
foreach ($k in $jobs.Keys) {
    $f = Join-Path $outDir ($k + '.html')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $jobs[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    Write-Host ('{0,-20} {1} {2,9:N0} 字节' -f $k, $code, $len)
    if ($code -ne '200') { continue }
    $h = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
    $t = [regex]::Replace($h, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?is)<br\s*/?>', "`n")
    $t = [regex]::Replace($t, '(?is)</p>', "`n`n")
    $t = [regex]::Replace($t, '<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '(?m)^[ \t]+', '')
    $t = [regex]::Replace($t, '\n{3,}', "`n`n").Trim()
    [System.IO.File]::WriteAllText((Join-Path $outDir ($k + '.txt')), $t, (New-Object System.Text.UTF8Encoding($false)))
    # 抽出提到 Smirnov 的段落
    $paras = $t -split "`n`n"
    $hit = @()
    foreach ($p in $paras) { if ($p -match 'Smirnov|Souzdal|Suzdal') { $hit += ($p -replace "`n", ' ') } }
    Write-Host ('     -> {0}.txt {1:N0} 字符，含 Smirnov/Suzdal 段落 {2} 段' -f $k, $t.Length, $hit.Count)
    if ($hit.Count -gt 0) {
        [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot ('smirnov-' + $k + '-hits.txt')), $hit, (New-Object System.Text.UTF8Encoding($false)))
    }
}

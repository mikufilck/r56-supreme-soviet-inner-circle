# 斯米尔诺夫 第九批：《我的生平》 site 34..38（斯维亚日斯克一月应在 35）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\mia'
$B29 = 'https://www.marxists.org/chinese/trotsky/1929/'
$log = @()
foreach ($n in 34..38) {
    $u = $B29 + ('trotsky_1929book{0}.htm' -f $n)
    $f = Join-Path $outDir ('ch{0}.html' -f $n)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $u 2>$null
    if ($c -ne '200' -or -not (Test-Path -LiteralPath $f)) { $log += ('ch{0}  {1}' -f $n, $c); continue }
    $raw = [System.IO.File]::ReadAllBytes($f)
    $h = [System.Text.Encoding]::GetEncoding(936).GetString($raw)
    $ti = ''
    if ($h -match '(?is)<title>(.*?)</title>') { $ti = ([regex]::Replace($Matches[1], '<[^>]+>', '')).Trim() }
    $sm = ([regex]::Matches($h, '斯米尔')).Count
    $log += ('ch{0}  200  {1,8:N0} 字节  「斯米尔」{2}  标题={3}' -f $n, $raw.Length, $sm, $ti)
    $t = [regex]::Replace($h, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<br\s*/?>', "`n")
    $t = [regex]::Replace($t, '(?is)</p>', "`n`n")
    $t = [regex]::Replace($t, '<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '(?m)^[ \t]+', '')
    $t = [regex]::Replace($t, '\n{3,}', "`n`n").Trim()
    [System.IO.File]::WriteAllText((Join-Path $outDir ('ch{0}.txt' -f $n)), $t, (New-Object System.Text.UTF8Encoding($false)))
    if ($sm -gt 0) {
        $paras = $t -split "`n`n"
        $hit = @()
        foreach ($p in $paras) { if ($p -match '斯米尔') { $hit += ($p -replace "`n", ' ') } }
        [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot ('smirnov-ch{0}-hits.txt' -f $n)), $hit, (New-Object System.Text.UTF8Encoding($false)))
        $log += ('        -> ch{0}.txt {1:N0} 字符，含「斯米尔」段落 {2} 段' -f $n, $t.Length, $hit.Count)
    }
}
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'smirnov-ch35-log.txt'), $log, (New-Object System.Text.UTF8Encoding($false)))
$log | ForEach-Object { Write-Host $_ }

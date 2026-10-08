# 探测文库中文站点：用 GB18030 解码，确认斯米尔诺夫有没有篇目页
$ErrorActionPreference = 'Continue'
$o = @()
foreach ($p in @('tmp\smirnov\mia\cn-abc.html', 'tmp\smirnov\mia\cn-search.html')) {
    if (-not (Test-Path -LiteralPath $p)) { $o += ($p + ' 不存在'); continue }
    $raw = [System.IO.File]::ReadAllBytes($p)
    $asc = [System.Text.Encoding]::ASCII.GetString($raw)
    $cs = '(未标)'
    if ($asc -match 'charset=["'']?([A-Za-z0-9\-]+)') { $cs = $Matches[1] }
    $o += ('=== {0} ===' -f $p)
    $o += ('字节={0}  <a>总数={1}  charset={2}' -f $raw.Length, ([regex]::Matches($asc, '(?is)<a\s')).Count, $cs)

    $h = [System.Text.Encoding]::GetEncoding(936).GetString($raw)
    $links = [regex]::Matches($h, '(?is)<a\s+[^>]*href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>')
    $n = 0
    $o += '  -- 含「斯米尔」 --'
    foreach ($m in $links) {
        $t = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($t -match '斯米尔') { $o += ('    {0}  ->  {1}' -f $t, $m.Groups[1].Value); $n++ }
    }
    $o += ('    命中 {0} 条' -f $n)
    $o += '  -- 全部「斯」开头条目 --'
    foreach ($m in $links) {
        $t = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($t -match '^斯') { $o += ('    {0}  ->  {1}' -f $t, $m.Groups[1].Value) }
    }
    $o += ''
}
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'smirnov-cn-abc.txt'), $o, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('写 -> ' + (Join-Path $PSScriptRoot 'smirnov-cn-abc.txt'))

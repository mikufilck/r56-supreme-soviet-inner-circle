# 斯米尔诺夫 第八批：托洛茨基《我的生平》中文版 —— 定位并抓「斯维亚日斯克一月」那章
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\mia'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$B29 = 'https://www.marxists.org/chinese/trotsky/1929/'

# 1) 抓目录页，列全部章节链接
$toc = Join-Path $outDir 'trotsky-1929book-toc.html'
$code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $toc -w '%{http_code}' ($B29 + 'trotsky_1929book.htm') 2>$null
Write-Host ("目录页 $code")
$links = @()
if ($code -eq '200') {
    $h = [System.IO.File]::ReadAllText($toc, [System.Text.Encoding]::GetEncoding(936))
    $i = 0
    foreach ($m in [regex]::Matches($h, '(?is)<a\s+[^>]*href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>')) {
        $t = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($t) { $links += ('{0,3}  {1,-46} {2}' -f $i, $t, $m.Groups[1].Value); $i++ }
    }
    [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'smirnov-trot-29toc.txt'), $links, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ("  链接 $($links.Count) 条 -> build\smirnov-trot-29toc.txt")
}

# 2) 逐个试 book31..book35，看哪一章是「斯维亚日斯克」
foreach ($n in 30..38) {
    $u = $B29 + ('trotsky_1929book{0}.htm' -f $n)
    $f = Join-Path $outDir ('ch{0}.html' -f $n)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $u 2>$null
    if ($c -ne '200') { Write-Host ('  ch{0}  {1}' -f $n, $c); continue }
    $raw = [System.IO.File]::ReadAllBytes($f)
    $h = [System.Text.Encoding]::GetEncoding(936).GetString($raw)
    $ti = ''
    if ($h -match '(?is)<title>(.*?)</title>') { $ti = ([regex]::Replace($Matches[1], '<[^>]+>', '')).Trim() }
    $sm = ([regex]::Matches($h, '斯米尔')).Count
    $sv = ([regex]::Matches($h, '斯维亚日斯克')).Count
    Write-Host ('  ch{0}  200  {1,8:N0} 字节  「斯米尔」{2}  「斯维亚日斯克」{3}  标题={4}' -f $n, $raw.Length, $sm, $sv, $ti.Substring(0, [Math]::Min(40, $ti.Length)))
    if ($sm -gt 0) {
        # 抽成纯文本存下来
        $t = [regex]::Replace($h, '(?is)<script.*?</script>', '')
        $t = [regex]::Replace($t, '(?is)<br\s*/?>', "`n")
        $t = [regex]::Replace($t, '(?is)</p>', "`n`n")
        $t = [regex]::Replace($t, '<[^>]+>', '')
        $t = [System.Net.WebUtility]::HtmlDecode($t)
        $t = [regex]::Replace($t, '(?m)^[ \t]+', '')
        $t = [regex]::Replace($t, '\n{3,}', "`n`n").Trim()
        [System.IO.File]::WriteAllText((Join-Path $outDir ('ch{0}.txt' -f $n)), $t, (New-Object System.Text.UTF8Encoding($false)))
        Write-Host ('        -> ch{0}.txt  {1:N0} 字符' -f $n, $t.Length)
    }
}

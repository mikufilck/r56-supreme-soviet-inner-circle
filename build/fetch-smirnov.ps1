# 伊万·尼基季奇·斯米尔诺夫：抓俄/英维基（补职务年表）+ 搜文库中文目录（确认有无篇目页）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\wiki'
$null   = New-Item -ItemType Directory -Force -Path $outDir

$jobs = [ordered]@{
    'ru' = 'https://ru.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=%D0%A1%D0%BC%D0%B8%D1%80%D0%BD%D0%BE%D0%B2%2C_%D0%98%D0%B2%D0%B0%D0%BD_%D0%9D%D0%B8%D0%BA%D0%B8%D1%82%D0%B8%D1%87'
    'en' = 'https://en.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=Ivan_Nikitich_Smirnov'
}
$rep = @()
foreach ($k in $jobs.Keys) {
    $f = Join-Path $outDir ($k + '.json')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $jobs[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $rep += ('{0,-4} {1,4} {2,9:N0} 字节' -f $k, $code, $len)
    Write-Host $rep[-1]
    if ($code -eq '200' -and $len -gt 200) {
        try {
            $j = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            foreach ($p in $j.query.pages.PSObject.Properties) {
                $txt = $p.Value.extract
                if ($txt) {
                    $out = Join-Path $outDir ($k + '.txt')
                    [System.IO.File]::WriteAllText($out, $txt, (New-Object System.Text.UTF8Encoding($false)))
                    Write-Host ('     -> {0}  {1:N0} 字符' -f ($k + '.txt'), $txt.Length)
                }
            }
        } catch { Write-Host ('     JSON 解析失败：' + $_.Exception.Message) }
    }
}

# 文库中文目录：确认有没有「斯米尔诺夫」篇目页
$idx = Join-Path $outDir 'mia-index.html'
$code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $idx -w '%{http_code}' 'https://www.marxists.org/chinese/index.html' 2>$null
$len = if (Test-Path -LiteralPath $idx) { (Get-Item -LiteralPath $idx).Length } else { 0 }
$rep += ('文库目录 {0} {1:N0} 字节' -f $code, $len)
Write-Host $rep[-1]

$hits = @()
if ($len -gt 0) {
    $html = [System.IO.File]::ReadAllText($idx, [System.Text.Encoding]::UTF8)
    # 抽出所有含「斯米尔」的行（含 href）
    foreach ($m in [regex]::Matches($html, '(?is)<a\s+[^>]*href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>')) {
        $href = $m.Groups[1].Value
        $text = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($text -match '斯米尔' -or $href -match 'smirnov') {
            $hits += ('{0}  ->  {1}' -f $text, $href)
        }
    }
    $rep += ('文库目录中「斯米尔」命中 {0} 条' -f $hits.Count)
    Write-Host $rep[-1]
}
$out = Join-Path $PSScriptRoot 'fetch-smirnov-report.txt'
$all = @()
$all += '=== 抓取结果 ==='
$all += $rep
$all += ''
$all += '=== 文库中文目录中「斯米尔」命中 ==='
$all += $hits
[System.IO.File]::WriteAllLines($out, $all, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('报告 -> ' + $out)

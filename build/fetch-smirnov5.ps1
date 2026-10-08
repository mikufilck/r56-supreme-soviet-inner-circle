# 斯米尔诺夫 第五批：远东共和国 + 托洛茨基 1936 档案索引
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\wiki'
$null   = New-Item -ItemType Directory -Force -Path $outDir

function Get-WikiExtract([string]$api, [string]$title, [string]$key) {
    $u = $api + '?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=' + [uri]::EscapeDataString($title)
    $f = Join-Path $outDir ($key + '.json')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $u 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    if ($code -eq '200' -and $len -gt 300) {
        try {
            $j = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            foreach ($p in $j.query.pages.PSObject.Properties) {
                if ($p.Value.extract) {
                    [System.IO.File]::WriteAllText((Join-Path $outDir ($key + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                    Write-Host ('{0,-16} 200 -> {1}.txt {2:N0} 字符' -f $key, $key, $p.Value.extract.Length)
                } else { Write-Host ('{0,-16} 200 ⚠️ 缺页: {1}' -f $key, $p.Value.title) }
            }
        } catch { Write-Host ('{0,-16} JSON 失败' -f $key) }
    } else { Write-Host ('{0,-16} {1} {2:N0} 字节（失败）' -f $key, $code, $len) }
}

Get-WikiExtract 'https://ru.wikipedia.org/w/api.php' 'Дальневосточная республика'   'ru_dvr'
Get-WikiExtract 'https://ru.wikipedia.org/w/api.php' 'Сибирский революционный комитет' 'ru_sibrevkom'
Get-WikiExtract 'https://en.wikipedia.org/w/api.php' 'Far Eastern Republic'           'en_dvr'

# 托洛茨基 1936 年英文档案索引
$idx = Join-Path $outDir 'trot-1936.html'
$code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $idx -w '%{http_code}' 'https://www.marxists.org/archive/trotsky/1936/index.htm' 2>$null
$len = if (Test-Path -LiteralPath $idx) { (Get-Item -LiteralPath $idx).Length } else { 0 }
Write-Host ('trot-1936 索引    {0} {1:N0} 字节' -f $code, $len)
if ($len -gt 500) {
    $h = [System.IO.File]::ReadAllText($idx, [System.Text.Encoding]::UTF8)
    $o = @('=== 托洛茨基 1936 档案索引 ===')
    foreach ($m in [regex]::Matches($h, '(?is)<a\s+[^>]*href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>')) {
        $t = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($t) { $o += ('  {0,-70} {1}' -f $t, $m.Groups[1].Value) }
    }
    [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'smirnov-trot1936.txt'), $o, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ('  -> build\smirnov-trot1936.txt  {0} 条' -f ($o.Count - 1))
}

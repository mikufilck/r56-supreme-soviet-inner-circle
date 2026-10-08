# 斯米尔诺夫 第二批：① 核实「首任邮电人民委员」 ② 抓英文维基外链（塞尔日那篇）③ 抓俄文维基里「四十六人声明」
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smirnov\wiki'
$null   = New-Item -ItemType Directory -Force -Path $outDir

function Get-WikiExtract([string]$api, [string]$title, [string]$key) {
    $u = $api + '?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=' + [uri]::EscapeDataString($title)
    $f = Join-Path $outDir ($key + '.json')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $u 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    Write-Host ('{0,-22} {1} {2:N0} 字节' -f $key, $code, $len)
    if ($code -eq '200' -and $len -gt 200) {
        try {
            $j = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            foreach ($p in $j.query.pages.PSObject.Properties) {
                if ($p.Value.extract) {
                    [System.IO.File]::WriteAllText((Join-Path $outDir ($key + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                    Write-Host ('      -> {0}.txt  {1:N0} 字符' -f $key, $p.Value.extract.Length)
                } else { Write-Host ('      ⚠️ 无 extract（可能缺页）：' + $p.Value.title) }
            }
        } catch { Write-Host ('      JSON 失败：' + $_.Exception.Message) }
    }
}

Get-WikiExtract 'https://ru.wikipedia.org/w/api.php' 'Народный комиссариат почт и телеграфов РСФСР' 'ru_nkpt'
Get-WikiExtract 'https://ru.wikipedia.org/w/api.php' 'Заявление 46-ти'                          'ru_decl46'
Get-WikiExtract 'https://ru.wikipedia.org/w/api.php' 'Объединённый троцкистско-зиновьевский центр' 'ru_center'

# 英文维基条目 HTML 里的外链（找塞尔日那篇的确切 URL）
$f = Join-Path $outDir 'en.html'
$code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' 'https://en.wikipedia.org/wiki/Ivan_Nikitich_Smirnov' 2>$null
Write-Host ('en.html ' + $code)
if ($code -eq '200') {
    $h = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
    $out = @('=== en 条目里的外链（含 marxists / spartacus）===')
    foreach ($m in [regex]::Matches($h, '(?is)<a[^>]*class="external[^"]*"[^>]*href="([^"]+)"')) {
        $out += ('  ' + $m.Groups[1].Value)
    }
    [System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'smirnov-enlinks.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
    $out | ForEach-Object { Write-Host $_ }
}

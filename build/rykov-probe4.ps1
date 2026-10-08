# 用 html.duckduckgo.com（前面验证可用）搜【中文马克思主义文库里的李可夫】
$proxy = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\rykov\probe3'
$null = New-Item -ItemType Directory -Force -Path $outDir

$queries = [ordered]@{
    'c1_site_chinese'  = 'site%3Amarxists.org%2Fchinese+%E6%9D%8E%E5%8F%AF%E5%A4%AB'
    'c2_lenin_rykov'   = '%22%E6%9D%8E%E5%8F%AF%E5%A4%AB%22+%E5%88%97%E5%AE%81+%E9%AB%98%E5%B3%B0%E4%BC%9A%E8%AE%AE'
    'c3_rykov_speech'  = '%22Rykov%22+%22Supreme+Council+of+National+Economy%22+speech+1918'
    'c4_rykov_mia'     = 'site%3Amarxists.org+Rykov+%22food+supply%22+Red+Army'
}
$rep = @()
foreach ($k in $queries.Keys) {
    $f = Join-Path $outDir "$k.html"
    $u = "https://html.duckduckgo.com/html/?q=$($queries[$k])"
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' --max-time 60 -o $f -w '%{http_code}' $u 2>$null
    $rep += "=== $k  HTTP=$code  $(if(Test-Path $f){(Get-Item $f).Length}else{0}) 字节 ==="
    if (Test-Path -LiteralPath $f) {
        $t = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
        foreach ($m in [regex]::Matches($t, 'uddg=([^&"]+)')) {
            $du = [System.Uri]::UnescapeDataString($m.Groups[1].Value)
            if ($du -notmatch 'duckduckgo') { $rep += ('  ' + $du) }
        }
    }
    $rep += ''
}
$rep | Select-Object -Unique | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'rykov-links2-report.txt') -Encoding utf8
Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rykov-links2-report.txt')

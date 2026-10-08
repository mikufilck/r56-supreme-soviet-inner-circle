# 探测：中文马克思主义文库有没有李可夫的篇目页
$ErrorActionPreference = 'Continue'
$px = 'http://127.0.0.1:7993'
$out = @()
$urls = @(
    'https://www.marxists.org/chinese/rykov/index.htm',
    'https://www.marxists.org/chinese/rykov/',
    'https://www.marxists.org/chinese/abc/rykov/rykov.html',
    'https://www.marxists.org/chinese/rykov/rykov.html',
    'https://www.marxists.org/chinese/index.html'
)
foreach ($u in $urls) {
    $r = & curl.exe -sS -L -x $px --max-time 30 -o NUL -w '%{http_code}' $u 2>&1
    $out += ('{0,-8} {1}' -f ($r -join ''), $u)
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'rykov-probe.txt') -Encoding utf8

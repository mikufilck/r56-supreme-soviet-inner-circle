$ErrorActionPreference = 'Continue'
$out = @()
$proxy = 'http://127.0.0.1:7993'

$targets = @(
    'https://en.wikipedia.org/wiki/Leon_Trotsky',
    'https://zh.wikipedia.org/wiki/%E5%88%97%E5%A4%AB%C2%B7%E6%89%98%E6%B4%9B%E8%8C%A8%E5%9F%BA',
    'https://www.google.com',
    'https://github.com',
    'https://www.marxists.org',
    'https://www.marxists.org/chinese/',
    'https://marxists.org'
)

$out += '=== 外网站点矩阵（走代理 20s）==='
foreach ($t in $targets) {
    $a = @('-sS', '-L', '-x', $proxy, '--max-time', '20', '-o', 'NUL', '-w', '%{http_code}') + $t
    $r = & curl.exe @a 2>&1
    $txt = ($r -join ' | ')
    if ($txt.Length -gt 90) { $txt = $txt.Substring(0, 90) }
    $out += ('  {0,-62} : {1}' -f $t, $txt)
}

$out += ''
$out += '=== DNS 解析（看是否被污染）==='
foreach ($h in @('www.marxists.org', 'en.wikipedia.org', 'www.google.com')) {
    try {
        $ips = (Resolve-DnsName -Name $h -Type A -ErrorAction Stop | Where-Object { $_.IPAddress } | Select-Object -ExpandProperty IPAddress) -join ', '
        $out += ('  {0,-22} -> {1}' -f $h, $ips)
    } catch {
        $out += ('  {0,-22} -> 解析失败 {1}' -f $h, $_.Exception.Message)
    }
}

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'net-diag5.txt') -Encoding utf8

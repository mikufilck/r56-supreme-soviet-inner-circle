$ErrorActionPreference = 'Continue'
$out = @()
$url = 'https://api.ipify.org'

$out += '=== 代理协议矩阵（探 api.ipify.org）==='
foreach ($p in @('http://127.0.0.1:7993', 'socks5://127.0.0.1:7993', 'socks5h://127.0.0.1:7993')) {
    $a = @('-sS', '-L', '-x', $p, '--max-time', '20', '-o', 'NUL', '-w', '%{http_code}') + $url
    $r = & curl.exe @a 2>&1
    $out += ('  {0,-32} : {1}' -f $p, ($r -join ' | '))
}

$out += ''
$out += '=== 直连对照 ==='
$r2 = & curl.exe -sS -L -4 --max-time 20 -o NUL -w '%{http_code}' $url 2>&1
$out += ('  -4 直连 : ' + ($r2 -join '|'))

$out += ''
$out += '=== 7993 端口是什么协议（手工 HTTP CONNECT 探测）==='
try {
    $c = New-Object System.Net.Sockets.TcpClient
    $c.Connect('127.0.0.1', 7993)
    $s = $c.GetStream()
    $req = "CONNECT api.ipify.org:443 HTTP/1.1`r`nHost: api.ipify.org:443`r`n`r`n"
    $b = [System.Text.Encoding]::ASCII.GetBytes($req)
    $s.Write($b, 0, $b.Length)
    $s.ReadTimeout = 8000
    $buf = New-Object byte[] 512
    $n = $s.Read($buf, 0, 512)
    $out += ('  CONNECT 响应: ' + [System.Text.Encoding]::ASCII.GetString($buf, 0, $n).Replace("`r`n", ' / '))
    $c.Close()
} catch {
    $out += ('  CONNECT 失败: ' + $_.Exception.Message)
}

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'net-diag3.txt') -Encoding utf8

$ErrorActionPreference = 'Continue'
$out = @()
$proxy = 'http://127.0.0.1:7993'

$targets = @(
    'http://www.baidu.com',
    'https://www.baidu.com',
    'https://www.marxists.org/chinese/trotsky/index.htm',
    'http://www.marxists.org/chinese/trotsky/index.htm'
)

$out += '=== 走代理 http://127.0.0.1:7993 ==='
foreach ($t in $targets) {
    $a = @('-sS', '-L', '-x', $proxy, '--max-time', '30', '-o', 'NUL', '-w', '%{http_code}') + $t
    $r = & curl.exe @a 2>&1
    $out += ('  {0,-58} : {1}' -f $t, ($r -join ' | '))
}

$out += ''
$out += '=== 直连（不走代理）==='
foreach ($t in $targets) {
    $a = @('-sS', '-L', '--noproxy', '*', '--max-time', '30', '-o', 'NUL', '-w', '%{http_code}') + $t
    $r = & curl.exe @a 2>&1
    $out += ('  {0,-58} : {1}' -f $t, ($r -join ' | '))
}

$out += ''
$out += '=== 代理的 CONNECT 实际连通性（手工，不跑 TLS）==='
foreach ($hp in @('www.marxists.org:443', 'www.baidu.com:443')) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $c.Connect('127.0.0.1', 7993)
        $s = $c.GetStream()
        $req = "CONNECT $hp HTTP/1.1`r`nHost: $hp`r`n`r`n"
        $b = [System.Text.Encoding]::ASCII.GetBytes($req)
        $s.Write($b, 0, $b.Length)
        $s.ReadTimeout = 12000
        $buf = New-Object byte[] 256
        $n = $s.Read($buf, 0, 256)
        $line = ([System.Text.Encoding]::ASCII.GetString($buf, 0, $n) -split "`n")[0].Trim()
        $out += ('  {0,-24} -> {1}' -f $hp, $line)
        $c.Close()
    } catch {
        $out += ('  {0,-24} -> 异常 {1}' -f $hp, $_.Exception.Message)
    }
}

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'net-diag4.txt') -Encoding utf8

# 抓中文马克思主义文库总索引，搜「李可夫」出现在哪些篇目里
$ErrorActionPreference = 'Continue'
$px  = 'http://127.0.0.1:7993'
$dir = Join-Path $PSScriptRoot '..\tmp\rykov'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$hp  = Join-Path $dir 'mia-index.html'

$r = & curl.exe -sS -L -x $px --max-time 90 -o $hp -w '%{http_code}' 'https://www.marxists.org/chinese/index.html' 2>&1
$out = @(('index HTTP=' + ($r -join '')))

function Read-TextAuto([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    try {
        $enc = New-Object System.Text.UTF8Encoding($false, $true)
        return $enc.GetString($bytes)
    } catch {
        return [System.Text.Encoding]::GetEncoding(936).GetString($bytes)
    }
}

if (Test-Path $hp) {
    $html = Read-TextAuto $hp
    $out += ('index 大小 = ' + $html.Length)
    # 找含「李可夫」的链接及其所在行
    $ms = [regex]::Matches($html, '(?is)<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>')
    $hit = 0
    foreach ($m in $ms) {
        $txt = [regex]::Replace($m.Groups[2].Value, '<[^>]+>', '').Trim()
        if ($txt -match '李可夫|雷科夫|里科夫') {
            $out += ('  * ' + $txt + '   -> ' + $m.Groups[1].Value)
            $hit++
        }
    }
    $out += ('命中链接数 = ' + $hit)
    # 再全文找一次（可能出现在非链接文本里）
    $idx = $html.IndexOf('李可夫')
    if ($idx -ge 0) {
        $s = [Math]::Max(0, $idx - 300)
        $out += ''
        $out += '首处「李可夫」上下文：'
        $out += ([regex]::Replace($html.Substring($s, [Math]::Min(600, $html.Length - $s)), '\s+', ' '))
    }
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'rykov-probe.txt') -Encoding utf8

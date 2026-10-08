# docs/29 §8 核实：第 1 项「酒类专卖（Rykovka）的制度细节」
# 策略：先用搜索 API 找相关条目，再抓正文
$ErrorActionPreference = 'Continue'
$px  = 'http://127.0.0.1:7993'
$dir = Join-Path $PSScriptRoot '..\tmp\rykov\verify'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

function Invoke-WikiJson([string]$url, [string]$outFile) {
    $r = & curl.exe -sS -L -x $px --max-time 90 -o $outFile -w '%{http_code}' $url 2>&1
    $code = ($r -join '')
    if ($code -ne '200' -or -not (Test-Path $outFile)) { return $null }
    try { return ([System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json) } catch { return $null }
}

$searches = @(
    @{ Lang = 'en'; Key = 's_en_rykovka';    Q = 'Rykovka vodka' },
    @{ Lang = 'en'; Key = 's_en_monopoly';   Q = 'vodka monopoly Soviet Union' },
    @{ Lang = 'en'; Key = 's_en_alcohol';    Q = 'alcohol policy Soviet Union NEP' },
    @{ Lang = 'zh'; Key = 's_zh_monopoly';   Q = '苏联 酒类专卖' },
    @{ Lang = 'zh'; Key = 's_zh_rykov';      Q = '李可夫 酒' }
)

$out = @()
foreach ($s in $searches) {
    $u = 'https://' + $s.Lang + '.wikipedia.org/w/api.php?action=query&format=json&list=search&srlimit=8&srsearch=' +
         [Uri]::EscapeDataString($s.Q)
    $json = Invoke-WikiJson $u (Join-Path $dir ($s.Key + '.json'))
    $out += ('===== ' + $s.Key + '  「' + $s.Q + '」 =====')
    if (-not $json) { $out += '  (请求失败)'; $out += ''; continue }
    foreach ($h in $json.query.search) {
        $out += ('  * {0}' -f $h.title)
        $snippet = [regex]::Replace($h.snippet, '<[^>]+>', '')
        $out += ('      ' + $snippet)
    }
    $out += ''
    Start-Sleep -Milliseconds 400
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'rykov-verify-1.txt') -Encoding utf8

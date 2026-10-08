# 抓「酒类专卖」相关条目正文
$ErrorActionPreference = 'Continue'
$px  = 'http://127.0.0.1:7993'
$dir = Join-Path $PSScriptRoot '..\tmp\rykov\verify'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$jobs = @(
    @{ Lang = 'en'; Key = 'en_prohibition'; Title = 'Prohibition in the Russian Empire and the Soviet Union' },
    @{ Lang = 'en'; Key = 'en_vodka';       Title = 'Vodka' },
    @{ Lang = 'ru'; Key = 'ru_rykov';       Title = 'Рыков, Алексей Иванович' },
    @{ Lang = 'ru'; Key = 'ru_monopoly';    Title = 'Винная монополия' }
)

$report = @()
foreach ($j in $jobs) {
    $q = 'https://' + $j.Lang + '.wikipedia.org/w/api.php?action=query&format=json&prop=extracts' +
         '&explaintext=1&redirects=1&exlimit=1&titles=' + [Uri]::EscapeDataString($j.Title)
    $hp = Join-Path $dir ($j.Key + '.json')
    $r = & curl.exe -sS -L -x $px --max-time 120 -o $hp -w '%{http_code}' $q 2>&1
    $code = ($r -join '')
    if ($code -ne '200' -or -not (Test-Path $hp)) { $report += ('  [FAIL] {0,-16} HTTP={1}' -f $j.Key, $code); continue }
    $json = [System.IO.File]::ReadAllText($hp, [System.Text.Encoding]::UTF8)
    $obj = $null
    try { $obj = $json | ConvertFrom-Json } catch { $report += ('  [FAIL] {0,-16} JSON 失败' -f $j.Key); continue }
    $page = $obj.query.pages.PSObject.Properties | Select-Object -First 1
    $ex = $page.Value.extract
    if (-not $ex) { $report += ('  [FAIL] {0,-16} 无 extract' -f $j.Key); continue }
    $tp = Join-Path $dir ($j.Key + '.txt')
    [System.IO.File]::WriteAllText($tp, ($ex -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $report += ('  [OK  ] {0,-16} {1,8} 字符 | {2}' -f $j.Key, $ex.Length, $page.Value.title)
    Start-Sleep -Milliseconds 500
}
$report | Out-File -LiteralPath (Join-Path $PSScriptRoot 'rykov-verify-2.txt') -Encoding utf8

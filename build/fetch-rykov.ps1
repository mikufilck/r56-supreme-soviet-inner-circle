# 抓李可夫相关维基条目（中英）+ 右翼反对派
# 🚩 坑（见仓库记忆）：① 一人一请求会被限流 → 用 titles=A|B 批量
#   ② 批量取整篇全文时 exlimit 会被强制降为 1 → 加 exintro=1（只取首段）才允许 batch
#   ③ 要全文就只能一条一条抓（exlimit=1 + 单 title）
#   ④ 一律走代理 -x
$ErrorActionPreference = 'Continue'
$px  = 'http://127.0.0.1:7993'
$dir = Join-Path $PSScriptRoot '..\tmp\rykov'
$raw = Join-Path $dir 'raw'
New-Item -ItemType Directory -Force -Path $raw | Out-Null

$jobs = @(
    @{ Lang = 'zh'; Key = 'rykov_zh';       Title = '阿列克谢·李可夫' },
    @{ Lang = 'en'; Key = 'rykov_en';       Title = 'Alexei Rykov' },
    @{ Lang = 'zh'; Key = 'right_opp_zh';   Title = '右翼反对派' },
    @{ Lang = 'zh'; Key = 'sovnarkom_zh';   Title = '苏联人民委员会' },
    @{ Lang = 'zh'; Key = 'labour_def_zh';  Title = '劳动与国防委员会' }
)

$report = @()
foreach ($j in $jobs) {
    # 单 title → exlimit=1 合法 → 可拿全文
    $q = 'https://' + $j.Lang + '.wikipedia.org/w/api.php' +
         '?action=query&format=json&prop=extracts&explaintext=1&redirects=1&exlimit=1' +
         '&titles=' + [Uri]::EscapeDataString($j.Title)
    $hp = Join-Path $raw ($j.Key + '.json')
    $r = & curl.exe -sS -L -x $px --max-time 90 -o $hp -w '%{http_code}' $q 2>&1
    $code = ($r -join '')
    if ($code -ne '200' -or -not (Test-Path $hp)) { $report += ('  [FAIL] {0,-14} HTTP={1}' -f $j.Key, $code); continue }
    $json = [System.IO.File]::ReadAllText($hp, [System.Text.Encoding]::UTF8)
    $obj = $null
    try { $obj = $json | ConvertFrom-Json } catch { $report += ('  [FAIL] {0,-14} JSON 解析失败' -f $j.Key); continue }
    $page = $obj.query.pages.PSObject.Properties | Select-Object -First 1
    $ex = $page.Value.extract
    if (-not $ex) { $report += ('  [FAIL] {0,-14} 无 extract（可能条目名不对）' -f $j.Key); continue }
    $tp = Join-Path $dir ($j.Key + '.txt')
    [System.IO.File]::WriteAllText($tp, ($ex -replace "`r`n", "`n"), (New-Object System.Text.UTF8Encoding($false)))
    $report += ('  [OK  ] {0,-14} {1,8} 字符 | 标题={2}' -f $j.Key, $ex.Length, $page.Value.title)
    Start-Sleep -Milliseconds 500
}
$report | Out-File -LiteralPath (Join-Path $PSScriptRoot 'fetch-rykov-report.txt') -Encoding utf8

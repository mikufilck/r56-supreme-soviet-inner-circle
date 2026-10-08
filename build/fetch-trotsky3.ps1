# 第三批：修正基础路径（章节页在各自子目录下）
# 🚩 教训：目录页链接是【相对】的，基准是【目录页自己所在目录】，不是 /chinese/trotsky/
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$root  = Join-Path $PSScriptRoot '..\tmp\trotsky'
$htmlDir = Join-Path $root 'html'
$txtDir  = Join-Path $root 'txt'
New-Item -ItemType Directory -Force -Path $htmlDir, $txtDir | Out-Null

$B30 = 'https://www.marxists.org/chinese/trotsky/1930book/'      # 俄国革命史
$B29 = 'https://www.marxists.org/chinese/trotsky/1929/'          # 我的生平
$BCN = 'https://www.marxists.org/chinese/trotsky/1926-1940book/' # 中国革命问题
$BFA = 'https://www.marxists.org/chinese/trotsky/about-FASCISM/' # 法西斯主义
$BPR = 'https://www.marxists.org/chinese/trotsky/permanent_revolution/' # 不断革命论

$targets = [ordered]@{
    'ii1_preface_ru_1930book03'    = $B30 + 'trotsky-1930book03.htm'
    'ii1_preface_1930book04'       = $B30 + 'trotsky-1930book04.htm'
    'ii1_ch1_1930book05'           = $B30 + 'trotsky-1930book05.htm'
    'ii1_ch1_appendix_1930book28'  = $B30 + 'trotsky-1930book28.htm'
    'ii3_bureaucratic_legend_58'   = $B30 + 'trotsky-1930book58.htm'
    'ii3_one_country_59'           = $B30 + 'trotsky-1930book59.htm'
    'ii2_permrev_review_60'        = $B30 + 'trotsky-1930book60.htm'
    'i1_train_1929book36'          = $B29 + 'trotsky_1929book36.htm'
    'i1_marxism_opposition_38'     = $B29 + 'trotsky_1929book38.htm'
    'i3_military_strategy_39'      = $B29 + 'trotsky_1929book39.htm'
    'iv1_nep_phase_1929book40'     = $B29 + 'trotsky_1929book40.htm'
    'iii1_brest_1929book33'        = $B29 + 'trotsky_1929book33.htm'
    'iii1_last_stage_1929book44'   = $B29 + 'trotsky_1929book44.htm'
    'e_october_lessons_1929book30' = $B29 + 'trotsky_1929book30.htm'
    'v2_class_relations_01b'       = $BCN + '01b.htm'
    'v2_against_stalin_theses_01c' = $BCN + '01c.htm'
    'v2_china_theses_03a'          = $BCN + '03a.htm'
    'v2_summary_prospect_05'       = $BCN + '05.htm'
    'v3_what_is_fascism_02'        = $BFA + '02.htm'
    'v3_workers_arms_10'           = $BFA + '10.htm'
    'v3_build_party_12'            = $BFA + '12.htm'
    'v3_mussolini_03'              = $BFA + '03.htm'
    'ii2_permrev_index'            = $BPR + 'index.htm'
}

function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', '')
    $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n")
    $t = [regex]::Replace($t, '(?i)</p>', "`n" + "`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n" + "`n")
    $t = [regex]::Replace($t, '(?i)</div>', "`n")
    $t = [regex]::Replace($t, '(?is)<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '[ \t]+', ' ')
    $t = [regex]::Replace($t, '(\r?\n){3,}', "`n" + "`n")
    return $t.Trim()
}
function Read-TextAuto([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    try {
        $enc = New-Object System.Text.UTF8Encoding($false, $true)
        return $enc.GetString($bytes)
    } catch {
        return [System.Text.Encoding]::GetEncoding(936).GetString($bytes)
    }
}

$report = @()
foreach ($k in $targets.Keys) {
    $u = $targets[$k]
    $hp = Join-Path $htmlDir "$k.htm"
    $r = & curl.exe -sS -L -x $proxy --max-time 90 -o $hp -w '%{http_code}' $u 2>&1
    $code = ($r -join '')
    if ($code -ne '200' -or -not (Test-Path $hp)) { $report += ('  [FAIL] {0,-32} HTTP={1}' -f $k, $code); continue }
    $html = Read-TextAuto $hp
    $txt  = Convert-HtmlToText $html
    [System.IO.File]::WriteAllText((Join-Path $txtDir "$k.txt"), $txt, (New-Object System.Text.UTF8Encoding($false)))
    # 头 90 字符作为标题校验（防止抓到别的文档）
    $head = ($txt -replace "`r?`n", ' ')
    if ($head.Length -gt 90) { $head = $head.Substring(0, 90) }
    $report += ('  [OK  ] {0,-32} {1,8} 字符 | {2}' -f $k, $txt.Length, $head)
    Start-Sleep -Milliseconds 400
}
$report | Out-File -LiteralPath (Join-Path $PSScriptRoot 'fetch-trotsky-report3.txt') -Encoding utf8

# 第二批：按 17 条国策逐条对好的关键篇目
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$root  = Join-Path $PSScriptRoot '..\tmp\trotsky'
$htmlDir = Join-Path $root 'html'
$txtDir  = Join-Path $root 'txt'
New-Item -ItemType Directory -Force -Path $htmlDir, $txtDir | Out-Null

$targets = [ordered]@{
    # --- II1 不平衡与综合发展律（《俄国革命史》序言 / 第一章）---
    'ii1_preface_ru_1930book03'  = 'https://www.marxists.org/chinese/trotsky/trotsky-1930book03.htm'
    'ii1_preface_1930book04'     = 'https://www.marxists.org/chinese/trotsky/trotsky-1930book04.htm'
    'ii1_ch1_1930book05'         = 'https://www.marxists.org/chinese/trotsky/trotsky-1930book05.htm'
    # --- II3 驳「一国社会主义」 / III2 反官僚化 ---
    'ii3_bureaucratic_legend_1930book58' = 'https://www.marxists.org/chinese/trotsky/trotsky-1930book58.htm'
    'ii3_socialism_one_country_1930book59' = 'https://www.marxists.org/chinese/trotsky/trotsky-1930book59.htm'
    'ii2_permrev_review_1930book60' = 'https://www.marxists.org/chinese/trotsky/trotsky-1930book60.htm'
    'ii1_ch1_appendix_1930book28' = 'https://www.marxists.org/chinese/trotsky/trotsky-1930book28.htm'
    # --- I1/I2/I3 军事（《我的生平》相关章节）---
    'i1_train_1929book36'        = 'https://www.marxists.org/chinese/trotsky/trotsky_1929book36.htm'
    'i1_marxism_opposition_1929book38' = 'https://www.marxists.org/chinese/trotsky/trotsky_1929book38.htm'
    'i3_military_strategy_1929book39' = 'https://www.marxists.org/chinese/trotsky/trotsky_1929book39.htm'
    # --- IV1/IV2 经济（新经济政策阶段）---
    'iv1_nep_phase_1929book40'   = 'https://www.marxists.org/chinese/trotsky/trotsky_1929book40.htm'
    # --- III1 新方针 / 党内斗争 ---
    'iii1_last_stage_1929book44' = 'https://www.marxists.org/chinese/trotsky/trotsky_1929book44.htm'
    'iii1_brest_1929book33'      = 'https://www.marxists.org/chinese/trotsky/trotsky_1929book33.htm'
    # --- V3 反法西斯统一战线 ---
    'v3_what_is_fascism_02'      = 'https://www.marxists.org/chinese/trotsky/02.htm'
    'v3_workers_arms_10'         = 'https://www.marxists.org/chinese/trotsky/10.htm'
    'v3_build_party_12'          = 'https://www.marxists.org/chinese/trotsky/12.htm'
    'v3_mussolini_03'            = 'https://www.marxists.org/chinese/trotsky/03.htm'
    # --- V2 中国革命问题 ---
    'v2_class_relations_01b'     = 'https://www.marxists.org/chinese/trotsky/01b.htm'
    'v2_against_stalin_theses_01c' = 'https://www.marxists.org/chinese/trotsky/01c.htm'
    'v2_china_theses_03a'        = 'https://www.marxists.org/chinese/trotsky/03a.htm'
    'v2_summary_prospect_05'     = 'https://www.marxists.org/chinese/trotsky/05.htm'
    # --- V1 共产国际 ---
    'v1_comintern_2nd_1926a'     = 'https://www.marxists.org/chinese/trotsky/marxist.org-chinese-trotsky-1926a.htm'
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
    if ($code -ne '200' -or -not (Test-Path $hp)) { $report += ('  [FAIL] {0,-34} HTTP={1}' -f $k, $code); continue }
    $html = Read-TextAuto $hp
    $txt  = Convert-HtmlToText $html
    [System.IO.File]::WriteAllText((Join-Path $txtDir "$k.txt"), $txt, (New-Object System.Text.UTF8Encoding($false)))
    $report += ('  [OK  ] {0,-34} -> {1,8} 字符' -f $k, $txt.Length)
    Start-Sleep -Milliseconds 400
}
$report | Out-File -LiteralPath (Join-Path $PSScriptRoot 'fetch-trotsky-report2.txt') -Encoding utf8

# =============================================================================
# 加米涅夫：抓一手材料（SOP 第 1 步用）
# -----------------------------------------------------------------------------
# 来源页：
#   中文  https://www.marxists.org/chinese/kamenev/index.htm   （200，19 条链接）
#   英文  https://www.marxists.org/archive/kamenev/index.htm   （200，6 篇正文）
# 🚩 与李可夫的关键区别：他**有**专页（李可夫 5 个候选 URL 全 404）→ 文案可走本人原话
# 🚩 三个已知坑（仓库记忆）：
#   ① 页面编码不统一（主 index GB2312 / 子目录多为 UTF-8）→ 自动探测，别写死
#   ② 中文经控制台管道必乱 → 直接 WriteAllText(UTF8 无 BOM) 落盘
#   ③ 本机是 TUN + 本地 HTTP 代理 → curl 必须显式 -x
# =============================================================================
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$cnBase = 'https://www.marxists.org/chinese/'
$enBase = 'https://www.marxists.org/archive/kamenev/'
$htmlDir = Join-Path $PSScriptRoot '..\tmp\kamenev\html'
$txtDir  = Join-Path $PSScriptRoot '..\tmp\kamenev\txt'
$null = New-Item -ItemType Directory -Force -Path $htmlDir, $txtDir

function Read-TextAuto([string]$path) {
    $b = [System.IO.File]::ReadAllBytes($path)
    try { $e = New-Object System.Text.UTF8Encoding($false, $true); return $e.GetString($b) }
    catch { return [System.Text.Encoding]::GetEncoding(936).GetString($b) }
}
function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', ''); $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n"); $t = [regex]::Replace($t, '(?i)</p>', "`n`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n`n"); $t = [regex]::Replace($t, '(?i)</li>', "`n")
    $t = [regex]::Replace($t, '(?is)<[^>]+>', ''); $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '[ \t]+', ' '); return ([regex]::Replace($t, '(\r?\n){3,}', "`n`n")).Trim()
}

# 全部 19 条中文 + 6 篇英文，逐条注明用途（判定时要用）
$cn = [ordered]@{
    # ---- 自传（定位「他自认的核心领域」，第 1 步最快的入口）----
    'bio_autobiography'   = 'reference-books/autobiography-of-bolsheviks/05.htm'

    # ---- 1917 · 反对起义（⚠️ 他的历史污点 = 有效性判定里的 ❌ 档）----
    'pol_19170304_april'  = 'kamenev/mia-chinese-kamenev-191703-04.htm'
    'pol_19171011_theses' = 'kamenev/mia-chinese-kamenev-19171011.htm'
    'pol_19171018_state'  = 'kamenev/mia-chinese-kamenev-19171018.htm'

    # ---- 1919 全俄中央执行委员会主席任内（乌克兰 / 马赫诺）----
    'pol_19190512_makhno' = 'kamenev/mia-chinese-kamenev-19190512.htm'

    # ---- 理论件 ----
    'w_192006_dictatorship' = 'kamenev/mia-chinese-kamenev-192006.htm'   # 无产阶级专政
    'w_leninism'            = 'kamenev/mia-chinese-kamenev-01.htm'       # 列宁主义（长文）
    'w_1924_gorky_letters'  = 'kamenev/mia-chinese-kamenev-1924.htm'     # 论列宁给高尔基的书信
    'w_1934_machiavelli'    = 'kamenev/mia-chinese-kamenev-1934.htm'     # 《马基雅维利著作集》序言

    # ---- 党内斗争 · 联合反对派（1926-27）----
    'pol_19261017_six'    = 'kamenev/mia-chinese-kamenev-19261017.htm'   # 六人声明
    'pol_19261101_conf15' = 'kamenev/mia-chinese-kamenev-19261101.htm'
    'pol_19261211_ecci7'  = 'kamenev/mia-chinese-kamenev-19261211.htm'   # 共产国际执委会第七次扩大全会
    'pol_19271208_cong15' = 'kamenev/mia-chinese-kamenev-19271208.htm'

    # ---- 1928 · 与布哈林、索柯里尼柯夫的谈话记录（三份）——
    #      这是「右倾」转向的一手证据，也解释他 1932-34 的复出
    'pol_19280711_talk_a' = 'kamenev/mia-chinese-kamenev-19280711.htm'
    'pol_19280711_talk_b' = 'kamenev/mia-chinese-kamenev-19280711b.htm'
    'pol_19280711_talk_c' = 'kamenev/mia-chinese-kamenev-19280711c.htm'

    # ---- 参考文献（对方来信，作对照用）----
    'ref_makhno_0512'     = 'makhno/mia-chinese-makhno-19190512.htm'
    'ref_makhno_0512_13'  = 'makhno/mia-chinese-makhno-19190512-13.htm'
}
$en = [ordered]@{
    'en_1906_hegemony'    = '1906/x01/hegemony.htm'      # 论无产阶级在民主革命中的领导权
    'en_19xx_x01'         = '19xx/x01/x01.htm'
    'en_1920_x01'         = '1920/x01/x01.htm'
    'en_1923_sitsovrus'   = '1923/01/sitsovrus.html'     # 俄国革命的现状
    'en_1923_lenin'       = '1923/10/lenin.htm'          # 论列宁
    'en_1924_trotskyism'  = '1924/11/trotskyism.htm'     # 托洛茨基主义还是列宁主义？
}

$rep = New-Object System.Collections.Generic.List[string]
foreach ($grp in @(@{ B = $cnBase; T = $cn; Tag = 'cn' }, @{ B = $enBase; T = $en; Tag = 'en' })) {
    $rep.Add('=' * 96)
    $rep.Add(('### [{0}] {1}' -f $grp.Tag, $grp.B))
    $rep.Add('=' * 96)
    foreach ($k in $grp.T.Keys) {
        $u  = $grp.B + $grp.T[$k]
        $hp = Join-Path $htmlDir ($k + '.htm')
        $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $hp -w '%{http_code}' $u 2>$null
        if ($code -ne '200' -or -not (Test-Path -LiteralPath $hp)) {
            $rep.Add(('  [FAIL] {0,-22} HTTP={1,-4} {2}' -f $k, $code, $grp.T[$k]))
            continue
        }
        $txt = Convert-HtmlToText (Read-TextAuto $hp)
        [System.IO.File]::WriteAllText((Join-Path $txtDir ($k + '.txt')), $txt,
            (New-Object System.Text.UTF8Encoding($false)))
        $rep.Add(('  [OK  ] {0,-22} {1,8:N0} 字符  {2}' -f $k, $txt.Length, $grp.T[$k]))
    }
    $rep.Add('')
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'kam-fetch-report.txt'), $rep,
    (New-Object System.Text.UTF8Encoding($false)))
$rep | ForEach-Object { Write-Output $_ }

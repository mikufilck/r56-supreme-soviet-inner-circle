# =============================================================================
# 季诺维也夫：抓中文一手材料（SOP 第 1 步用）
# -----------------------------------------------------------------------------
# 来源页：https://www.marxists.org/chinese/zinoviev/index.htm （200，有完整文集）
# 🚩 三个已知坑（见仓库记忆）：
#   ① 页面编码不统一（主 index GB / 子目录 UTF-8）→ 自动探测，别写死
#   ② 中文经控制台管道必乱 → 直接 WriteAllText(UTF8 无 BOM) 落盘
#   ③ 本机是 TUN + 本地 HTTP 代理 → curl 必须显式 -x
# =============================================================================
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$base  = 'https://www.marxists.org/chinese/'
$htmlDir = Join-Path $PSScriptRoot '..\tmp\zinoviev\html'
$txtDir  = Join-Path $PSScriptRoot '..\tmp\zinoviev\txt'
$null = New-Item -ItemType Directory -Force -Path $htmlDir, $txtDir

# key = 落盘名（ASCII）；value = 相对 $base 的路径
$targets = [ordered]@{
    # ---- 自传与大事记（定位用）----
    'bio_autobiography'   = 'reference-books/autobiography-of-bolsheviks/04.htm'   # 《谁发动了十月革命》他的自传
    'activity_1914_1926'  = 'zinoviev/mia-chinese-zinoviev-activity-1914-1926.htm' # 共产国际活动大事记

    # ---- 共产国际 · 缔造（1919）----
    'ci_191903_founding'  = 'zinoviev/mia-chinese-zinoviev-191903.htm'             # 共产国际（提纲）· 俄共八大报告
    'ci_19190302_decl'    = 'zinoviev/mia-chinese-zinoviev-19190302.htm'           # 关于成立第三国际的声明
    'ci_191904_prospect'  = 'zinoviev/mia-chinese-zinoviev-191904.htm'             # 无产阶级革命的前景
    'ci_191911_dying'     = 'zinoviev/mia-chinese-zinoviev-191911.htm'             # 垂死的国际和新生的国际

    # ---- 共产国际 · 组织与纪律（1920）----
    'ci_192005_urgent'    = 'zinoviev/mia-chinese-zinoviev-1920514.htm'            # 国际工人运动的迫切问题
    'ci_192009_east'      = 'zinoviev/mia-chinese-zinoviev-192009.htm'             # 在东方各民族代表大会上的讲话
    'ci_19201214_bureau'  = 'zinoviev/mia-chinese-zinoviev-19201214.htm'           # 同官僚主义作斗争（⚠️ 查与托洛茨基重叠）

    # ---- 共产国际 · 统一战线（1921-22）----
    'ci_192111_stages'    = 'zinoviev/mia-chinese-zinoviev-19211113.htm'           # 共产国际发展中的主要阶段
    'ci_192112_uf'        = 'zinoviev/mia-chinese-zinoviev-192112.htm'             # 工人统一战线提纲
    'ci_192112b_again'    = 'zinoviev/mia-chinese-zinoviev-192112a.htm'            # 再论统一战线的策略
    'ci_192202_uf'        = 'zinoviev/mia-chinese-zinoviev-192202.htm'             # 关于统一战线
    'ci_192204_prospect'  = 'zinoviev/mia-chinese-zinoviev-192204.htm'             # 无产阶级统一战线的前景

    # ---- 1923 德国革命（他的大失败）----
    'ci_192312_germany'   = 'zinoviev/mia-chinese-zinoviev-192312.htm'             # 德国事件的教训和统一战线的策略

    # ---- 共产国际 · 布尔什维克化（1924-25）----
    'ci_192402_fiveyears' = 'zinoviev/mia-chinese-zinoviev-192402.htm'             # 共产国际的诞生及其头五年的活动
    'ci_19250325_persp'   = 'zinoviev/mia-chinese-zinoviev-19250325.htm'           # 国际前景和布尔什维克化
    'ci_192504_stab'      = 'zinoviev/mia-chinese-zinoviev-192504.htm'             # 资本主义的局部「稳定」
    'ci_192509_zimmer'    = 'zinoviev/mia-chinese-zinoviev-192509.htm'             # 共产国际是齐美尔瓦尔德的产儿
    'ci_leninism'         = 'zinoviev/mia-chinese-zinoviev-1924-1925.htm'          # 《列宁主义》（摘录）
    'ci_192602_current'   = 'zinoviev/mia-chinese-zinoviev-192602.htm'             # 国际共产主义运动的当前问题（提纲）

    # ---- 党内斗争 / 污点（判定用）----
    'pol_19171011_theses' = 'kamenev/mia-chinese-kamenev-19171011.htm'             # 论时局（与加米涅夫联署）
    'pol_19171018_state'  = 'kamenev/mia-chinese-kamenev-19171018.htm'             # 反对起义的声明（⚠️ 泄露起义计划）
    'pol_19260414_letter' = 'zinoviev/mia-chinese-zinoviev-19260414.htm'           # 就公布列宁信件问题致中央政治局
    'pol_19250607_shanghai' = 'zinoviev/mia-chinese-zinoviev-19250607.htm'         # 上海事件（⚠️ 查与中国革命重叠）
}

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

$rep = @()
foreach ($k in $targets.Keys) {
    $u  = $base + $targets[$k]
    $hp = Join-Path $htmlDir ($k + '.htm')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $hp -w '%{http_code}' $u 2>$null
    if ($code -ne '200' -or -not (Test-Path -LiteralPath $hp)) {
        $rep += ('  [FAIL] {0,-24} HTTP={1}  {2}' -f $k, $code, $targets[$k])
        Write-Host $rep[-1]
        continue
    }
    $txt = Convert-HtmlToText (Read-TextAuto $hp)
    [System.IO.File]::WriteAllText((Join-Path $txtDir ($k + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
    $rep += ('  [OK  ] {0,-24} {1,7:N0} 字符  {2}' -f $k, $txt.Length, $targets[$k])
    Write-Host $rep[-1]
}
$rep | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'zin-fetch-report.txt') -Encoding utf8
Write-Host ''
Write-Host '--- build/zin-fetch-report.txt ---'

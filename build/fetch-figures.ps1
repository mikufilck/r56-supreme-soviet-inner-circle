# =============================================================================
# 抓候选池其余 15 人的维基条目 -> 纯文本，供人工/模型阅读
# -----------------------------------------------------------------------------
# 用途：docs/23 SOP 第 0 步「查现成内容」。产物落 tmp/figures/<key>.zh.txt / .en.txt。
#
# 🚩 2026-09-16 改用【维基 API + explaintext】而不再是抓 HTML 去标签：
#    HTML 版会带回大量导航/参考文献噪声，API 直接给纯文本全文，干净得多。
#    中英双份抓是为了【交叉核对职务与时间】—— 中文维基不少条目缺时间。
#
# 实测依据（见仓库记忆「抓中文网络资料」）：
#   · PS 5.1 的 Invoke-WebRequest 常因 TLS 失败 -> 用 curl.exe
#   · 一律【数组传参】& curl.exe @a（中文过控制台必乱）
#   · 产物用 [System.IO.File]::WriteAllText(..., UTF8Encoding($false)) 直接落盘
# 用法： powershell -NoProfile -ExecutionPolicy Bypass -File build/fetch-figures.ps1
# =============================================================================
$ErrorActionPreference = 'Continue'

$outDir = Join-Path (Get-Location) 'tmp\figures'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# Key 必须与 docs/10 §2.4.2 六个「营」里的键一致（= 角色 id 去掉 SOV_ 前缀）
# Zh 为维基条目名（不一定是我们的译名，靠 redirects=1 自动跳转）
$people = @(
    # ---- 批 2 · 左营补全 ----
    @{ Key = 'yevgeny_preobrazhensky'; Zh = '叶夫根尼·普列奥布拉任斯基'; En = 'Yevgeny Preobrazhensky' }
    @{ Key = 'karl_radek';             Zh = '卡尔·拉狄克';               En = 'Karl Radek' }
    @{ Key = 'ivar_smilga';            Zh = '伊瓦尔·斯米尔加';           En = 'Ivar Smilga' }
    # ---- 批 3 · 右营补全 + 工反营 ----
    @{ Key = 'mikhail_tomsky';         Zh = '米哈伊尔·托姆斯基';         En = 'Mikhail Tomsky' }
    @{ Key = 'martemyan_ryutin';       Zh = '里亚京';                   En = 'Martemyan Ryutin' }
    @{ Key = 'aleksandr_shlyapnikov';  Zh = '亚历山大·加夫里洛维奇·施利亚普尼科夫'; En = 'Alexander Shlyapnikov' }
    # ---- 批 4 · 中立营 ----
    @{ Key = 'mikhail_kalinin';        Zh = '米哈伊尔·加里宁';           En = 'Mikhail Kalinin' }
    @{ Key = 'maksim_litvinov';        Zh = '马克西姆·李维诺夫';         En = 'Maxim Litvinov' }
    @{ Key = 'grigory_sokolnikov';     Zh = '格里戈里·索柯里尼柯夫';     En = 'Grigory Sokolnikov' }
    @{ Key = 'mikhail_tukhachevsky';   Zh = '米哈伊尔·图哈切夫斯基';     En = 'Mikhail Tukhachevsky' }
    @{ Key = 'nikolay_voznesensky';    Zh = '尼古拉·沃兹涅先斯基';       En = 'Nikolai Voznesensky' }
    @{ Key = 'pyotr_smirnov';          Zh = '彼得·斯米尔诺夫';           En = 'Pyotr Aleksandrovich Smirnov' }
    # ---- 批 5 · 体制营 ----
    @{ Key = 'georgy_malenkow';        Zh = '格奥尔基·马林科夫';         En = 'Georgy Malenkov' }
    @{ Key = 'nikita_khrushchyov';     Zh = '尼基塔·赫鲁晓夫';           En = 'Nikita Khrushchev' }
    @{ Key = 'kliment_voroshilov';     Zh = '克利缅特·伏罗希洛夫';       En = 'Kliment Voroshilov' }
)

# 一次请求取【多人】的条目首段。
# 🚩🚩 踩过（两个不同的坑，都踩了）：
#   ① 一人一个请求 → 连发 10 个后维基返 **HTTP 429**，第 6 人起全挂。
#      → 改批量 titles=A|B|C。
#   ② 批量 + explaintext（不要 exintro）时，API 会警告
#      `"exlimit" was too large for a whole article extracts request, lowered to 1.`
#      —— **取整篇全文时 exlimit 被强降到 1**，结果 15 条里只有 1 条有内容，
#      其余页面只有 title、没有 extract（表现为“抓到了但全是 0 字节”）。
#      → 改加 **exintro=1**：只要首段时 exlimit 才能到 20，一次能取满 15 人。
#      首段对「查职务 / 身份」已经够用；需要全文时再单独抓（见脚本尾部说明）。
# 返回：@{ Extracts = @{最终标题=首段}; Alias = @{请求名=最终标题} }
function Get-WikiExtracts {
    param([string]$Lang, [string[]]$Titles)
    # 🚩🚩 踩过：不能写 "https://$Lang.wikipedia.org/..." ——
    #    PowerShell 会把 `$Lang.wikipedia` 当成【属性访问】解析，插值成空。
    $api = "https://$($Lang).wikipedia.org/w/api.php"
    # 🚩🚩 踩过：`& curl.exe` 的输出会被 PowerShell 按行拆成【数组】，
    #    再喂给 ConvertFrom-Json 会抛异常。这里让 curl 直接写文件（-o），绕开该问题。
    $jsonFile = Join-Path $outDir ("_raw_$Lang.json")
    $a = @(
        '-s', '-L', '--max-time', '120',
        '--retry', '6', '--retry-delay', '10', '--retry-all-errors',
        '-A', 'heart-of-iron-research/1.0 (local HOI4 modding; contact: local user)',
        '-G', $api,
        '--data-urlencode', 'action=query',
        '--data-urlencode', 'prop=extracts',
        '--data-urlencode', 'explaintext=1',
        '--data-urlencode', 'exintro=1',
        '--data-urlencode', 'exlimit=max',
        '--data-urlencode', 'redirects=1',
        '--data-urlencode', 'format=json',
        '--data-urlencode', ('titles=' + ($Titles -join '|')),
        '-o', $jsonFile
    )
    & curl.exe @a 2>$null | Out-Null

    $result = @{ Extracts = @{}; Alias = @{} }
    if (-not (Test-Path $jsonFile)) { return $result }
    $raw = [System.IO.File]::ReadAllText($jsonFile, [System.Text.Encoding]::UTF8)
    if (-not $raw) { return $result }
    try { $j = $raw | ConvertFrom-Json } catch { return $result }

    # 别名链：请求名 -> (normalized) -> (redirect) -> 最终标题
    if ($j.query.normalized) {
        foreach ($n in $j.query.normalized) { $result.Alias[[string]$n.from] = [string]$n.to }
    }
    if ($j.query.redirects) {
        foreach ($rd in $j.query.redirects) { $result.Alias[[string]$rd.from] = [string]$rd.to }
    }
    foreach ($prop in $j.query.pages.PSObject.Properties) {
        $pg = $prop.Value
        if ($pg.PSObject.Properties.Name -contains 'missing') { continue }
        $result.Extracts[[string]$pg.title] = [string]$pg.extract
    }
    return $result
}

# ---- 两个请求搞定：一个中文维基、一个英文维基 ----
Write-Output '======== 抓取候选池人物条目（批量）========'
Write-Output '  · zh.wikipedia.org ...'
$zhRes = Get-WikiExtracts -Lang 'zh' -Titles @($people | ForEach-Object { $_.Zh })
Write-Output ('    -> 拿到 {0} 条全文' -f $zhRes.Extracts.Count)
Write-Output '  · en.wikipedia.org ...'
$enRes = Get-WikiExtracts -Lang 'en' -Titles @($people | ForEach-Object { $_.En })
Write-Output ('    -> 拿到 {0} 条全文' -f $enRes.Extracts.Count)
Write-Output ''

function Resolve-Extract {
    param($Res, [string]$Name)
    if (-not $Name) { return $null }
    $t = $Name
    # 跟着别名链最多走 5 步（normalized + redirects）
    for ($i = 0; $i -lt 5; $i++) {
        if ($Res.Alias.ContainsKey($t)) { $t = $Res.Alias[$t] } else { break }
    }
    if ($Res.Extracts.ContainsKey($t) -and $Res.Extracts[$t]) { return $Res.Extracts[$t] }
    if ($Res.Extracts.ContainsKey($Name) -and $Res.Extracts[$Name]) { return $Res.Extracts[$Name] }
    return $null
}

$ok = 0; $miss = @()

foreach ($p in $people) {

    $zh = Resolve-Extract -Res $zhRes -Name $p.Zh
    $en = Resolve-Extract -Res $enRes -Name $p.En

    if ($zh) {
        [System.IO.File]::WriteAllText((Join-Path $outDir ($p.Key + '.zh.txt')), $zh, (New-Object System.Text.UTF8Encoding($false)))
    } else { $miss += ($p.Key + '.zh') }

    if ($en) {
        [System.IO.File]::WriteAllText((Join-Path $outDir ($p.Key + '.en.txt')), $en, (New-Object System.Text.UTF8Encoding($false)))
    } else { $miss += ($p.Key + '.en') }

    $zl = if ($zh) { $zh.Length } else { 0 }
    $el = if ($en) { $en.Length } else { 0 }
    $flag = if ($zh -and $en) { 'OK  ' } elseif ($zh -or $en) { 'HALF' } else { 'FAIL' }
    Write-Output ("  [{0}] {1,-24} zh={2,6}  en={3,6}  {4}" -f $flag, $p.Key, $zl, $el, $p.Zh)
    if ($zh -and $en) { $ok++ }
}

Write-Output ''
Write-Output ("  中英双全 {0} / {1} 人" -f $ok, $people.Count)
if ($miss.Count -gt 0) { Write-Output ('  ⚠️ 缺失：' + ($miss -join ', ')) }
Write-Output ("  产物目录：{0}" -f $outDir)

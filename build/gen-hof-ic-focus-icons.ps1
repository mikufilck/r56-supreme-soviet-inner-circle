# gen-hof-ic-focus-icons.ps1
# ---------------------------------------------------------------------------
# 把 art/focus/ 交付的 24 张国策图标注册成 sprite。
#
# 来源：art/focus/  （GPT 出图，100x88 RGBA PNG）
#       -> art/focus/export_focus.py 已导出 DDS 到
#          mod/heart_of_iron/gfx/interface/hof_ic/focus/GFX_*.dds
#
# 🚩 国策图标【必须】同时注册一张以 `_shine` 结尾的光泽 sprite，否则图标显示异常。
#    但贴图不用另外画：全游戏 5900+ 个 _shine 全都是同一张
#    gfx/interface/goals/shine_overlay.dds（动画叠加），
#    mask / texturefile 指向图标自己的 dds。蓝本：原版 interface/goals_shine.gfx
#
# 产出：mod/heart_of_iron/interface/hof_ic_focus_icons.gfx
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File build\gen-hof-ic-focus-icons.ps1
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$ModRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
)

$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$ddsDir = Join-Path $ModRoot 'gfx\interface\hof_ic\focus'
$outRel = 'interface/hof_ic_focus_icons.gfx'
$outAbs = Join-Path $ModRoot ($outRel -replace '/', '\')

Write-Output '======== 0. 扫描已交付的国策图标 DDS ========'

if (-not (Test-Path $ddsDir)) { throw "图标目录不存在：$ddsDir" }

$icons = Get-ChildItem $ddsDir -File -Filter 'GFX_*.dds' | Sort-Object Name
if ($icons.Count -eq 0) { throw "图标目录里没有 GFX_*.dds：$ddsDir" }

# 期望：7 张人物入口（GFX_hof_ic_seat_*） + 每人一条个人线（GFX_hof_ic_<人名拼音>_*）
# 🚩 这里是【按 build/focus-icon-owner.txt 自动归类】，不是硬编码清单 ——
#    美术交多少张就注册多少张，新人物落地时本脚本不用改。
#    踩过：早期写死了 trotsky / bukharin 两个前缀，李可夫上树后他那 5 张被归到
#    「其它」并打 ⚠ 未归类（其实完全正常）—— 每来一个人都得改一次脚本。
#    改为按【国策 id -> 人 key】的归属表分组（该表由 gen-hof-ic-s3.ps1 §10y 写出，
#    位于链路上游，一定先于本脚本跑）。
$ownerTxt = Join-Path $PSScriptRoot 'focus-icon-owner.txt'
$ownerMap = @{}
if (Test-Path -LiteralPath $ownerTxt) {
    foreach ($ln in [System.IO.File]::ReadAllLines($ownerTxt)) {
        if ($ln -match '^\s*#' -or $ln -notmatch '\S') { continue }
        if ($ln -match '^(\S+)\s*=\s*(\S+)$') { $ownerMap[$Matches[1]] = $Matches[2] }
    }
}

$seatIcons = $icons | Where-Object { $_.BaseName -like 'GFX_hof_ic_seat_*' }
$lineIcons = $icons | Where-Object { $_.BaseName -notlike 'GFX_hof_ic_seat_*' }

$byOwner = [ordered]@{}
$orphan  = New-Object System.Collections.Generic.List[string]
foreach ($ic in $lineIcons) {
    $id  = $ic.BaseName -replace '^GFX_', ''
    $key = if ($ownerMap.ContainsKey($id)) { $ownerMap[$id] } else { $null }
    if (-not $key) { $null = $orphan.Add($ic.Name); continue }
    if (-not $byOwner.Contains($key)) { $byOwner[$key] = 0 }
    $byOwner[$key] = $byOwner[$key] + 1
}

$parts = @("人物入口 $($seatIcons.Count) 张")
foreach ($k in $byOwner.Keys) { $parts += "$k $($byOwner[$k]) 张" }
$parts += "合计 $($icons.Count) 张"
Write-Output ('  ' + ($parts -join ' / '))
if ($ownerMap.Count -eq 0) {
    Write-Output '    ⚠ focus-icon-owner.txt 缺失或为空 —— 无法按人归类（请先跑 gen-hof-ic-s3.ps1）'
} else {
    foreach ($o in $orphan) { Write-Output "    ⚠ 未归类的图标（$ownerTxt 里查不到归属）：$o" }
}

# ---------------------------------------------------------------------------
# 0b. 国策图标缺失的【兜底注册】（2026-09-16 加，李可夫上树时暴露）
# ---------------------------------------------------------------------------
# 🚩 为什么必须兜底：国策块是 gen-hof-ic-s3.ps1 按【数据】发出去的，
#    而图标 DDS 是【美术交付】的另一条线。新人物上树但图还没交时：
#      · 国策里 icon = GFX_hof_ic_<key>_<focus> 指向一个不存在的 sprite
#      · 游戏里图标是空的，而且 error.log 会写 missing sprite
#        —— AGENTS 规则 5 明禁「改动引入新错误」
#    做法：扫生成物里所有 icon = GFX_*，凡磁盘上【没有】对应 dds 的，
#    注册一个指向【该人入口图标】的占位 sprite（肉眼一看就知道是占位），
#    并打出 ⚠ 清单。以后美术把 dds 补进 gfx/interface/hof_ic/focus/，
#    兜底自动失效（因为那时 dds 已存在），本脚本不用改。
$repoRoot = Split-Path $PSScriptRoot -Parent
$seatsTxt = Join-Path $PSScriptRoot 'inject-sov-seats.txt'
$placeholder = New-Object System.Collections.Generic.List[object]

# 图标脚本【只会兜底自己家的 sprite】（GFX_hof_ic_*）。
# 🚩 踩过：一开始把 icon = GFX_focus_SOV_the_supreme_soviet（原版 sprite，不需要我们注册）
#    也算成「缺失」，于是凭空多注册一个同名 sprite 去覆盖原版 —— 错的。
# 📌 $ownerMap 已在 §0 建好（按 focus-icon-owner.txt），这里直接复用。

if (Test-Path -LiteralPath $seatsTxt) {
    $txt = [System.IO.File]::ReadAllText($seatsTxt)
    $needed = [regex]::Matches($txt, '(?m)^\s*icon = (GFX_hof_ic_\S+)') |
              ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
    $have = @{}
    foreach ($ic in $icons) { $have[$ic.BaseName] = $true }
    # 兜底贴图的首选：该人的入口图标；不存在就退到任意一张入口图标
    $anySeat = @($seatIcons | ForEach-Object { $_.BaseName })[0]

    foreach ($n in $needed) {
        if ($have.ContainsKey($n)) { continue }
        $id  = $n -replace '^GFX_', ''
        $key = if ($ownerMap.ContainsKey($id)) { $ownerMap[$id] } else { $null }
        $tex = "gfx/interface/hof_ic/focus/GFX_hof_ic_seat_$key.dds"
        if (-not $key -or -not (Test-Path -LiteralPath (Join-Path $ModRoot ($tex -replace '/', '\')))) {
            $tex = "gfx/interface/hof_ic/focus/$anySeat.dds"
        }
        $null = $placeholder.Add(@{ Name = $n; Tex = $tex; Key = $key })
    }
}

if ($placeholder.Count -gt 0) {
    Write-Output ''
    Write-Output ("  ⚠ 有 {0} 张国策图标【美术未交付】—— 已用该人入口图标兜底注册（游戏里不会报错，但不是正式图）：" -f $placeholder.Count)
    foreach ($p in $placeholder) { Write-Output ("      {0,-52} -> {1}" -f $p.Name, (Split-Path $p.Tex -Leaf)) }
    Write-Output '      📌 补图后重跑本脚本即可，兜底会自动消失。'
}

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output "======== 1. 生成 sprite 注册（$outRel）======="

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 国策图标 sprite 注册（由 build/gen-hof-ic-focus-icons.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 素材：art/focus/  （GPT 出图，100x88 RGBA PNG）')
$null = $sb.AppendLine('#       DDS 已由 art/focus/export_focus.py 导出到')
$null = $sb.AppendLine('#       gfx/interface/hof_ic/focus/GFX_*.dds')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# 🚩 每个图标都有【两块】：本体 + `_shine`。')
$null = $sb.AppendLine('#    国策图标漏了 `_shine` 会显示成默认占位图。')
$null = $sb.AppendLine('#    但 `_shine` 不用另外画 —— 全游戏 5900+ 个 `_shine` 用的是同一张')
$null = $sb.AppendLine('#    gfx/interface/goals/shine_overlay.dds（动画叠加），')
$null = $sb.AppendLine('#    animationmaskfile / texturefile 指向图标自己的 dds。')
$null = $sb.AppendLine('#    蓝本：原版 interface/goals_shine.gfx  L1 起。')
$null = $sb.AppendLine('#')
$null = $sb.AppendLine('# 命名约定：sprite 名 = 国策 id（1:1 对齐，免映射表）')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('spriteTypes = {')

foreach ($ic in $icons) {
    $name = $ic.BaseName
    $tex  = "gfx/interface/hof_ic/focus/$name.dds"

    $null = $sb.AppendLine()
    $null = $sb.AppendLine("`t# ---------------- $name ----------------")
    $null = $sb.AppendLine("`tSpriteType = {")
    $null = $sb.AppendLine("`t`tname = `"$name`"")
    $null = $sb.AppendLine("`t`ttexturefile = `"$tex`"")
    $null = $sb.AppendLine("`t}")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("`tSpriteType = {")
    $null = $sb.AppendLine("`t`tname = `"${name}_shine`"")
    $null = $sb.AppendLine("`t`ttexturefile = `"$tex`"")
    $null = $sb.AppendLine("`t`teffectFile = `"gfx/FX/buttonstate.lua`"")
    foreach ($rot in @('-90.0', '90.0')) {
        $null = $sb.AppendLine("`t`tanimation = {")
        $null = $sb.AppendLine("`t`t`tanimationmaskfile = `"$tex`"")
        $null = $sb.AppendLine("`t`t`tanimationtexturefile = `"gfx/interface/goals/shine_overlay.dds`"")
        $null = $sb.AppendLine("`t`t`tanimationrotation = $rot")
        $null = $sb.AppendLine("`t`t`tanimationlooping = no")
        $null = $sb.AppendLine("`t`t`tanimationtime = 0.75")
        $null = $sb.AppendLine("`t`t`tanimationdelay = 0")
        $null = $sb.AppendLine("`t`t`tanimationblendmode = `"add`"")
        $null = $sb.AppendLine("`t`t`tanimationtype = `"scrolling`"")
        $null = $sb.AppendLine("`t`t`tanimationrotationoffset = { x = 0.0 y = 0.0 }")
        $null = $sb.AppendLine("`t`t`tanimationtexturescale = { x = 1.0 y = 1.0 }")
        $null = $sb.AppendLine("`t`t}")
    }
    $null = $sb.AppendLine("`t`tlegacy_lazy_load = no")
    $null = $sb.AppendLine("`t}")
}

# ---- 兜底 sprite（美术未交付的国策图标）----
foreach ($p in $placeholder) {
    $name = $p.Name
    $tex  = $p.Tex

    $null = $sb.AppendLine()
    $null = $sb.AppendLine("`t# ---------------- $name （⚠ 美术未交付，占位：复用入口图标）----------------")
    $null = $sb.AppendLine("`tSpriteType = {")
    $null = $sb.AppendLine("`t`tname = `"$name`"")
    $null = $sb.AppendLine("`t`ttexturefile = `"$tex`"")
    $null = $sb.AppendLine("`t}")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("`tSpriteType = {")
    $null = $sb.AppendLine("`t`tname = `"${name}_shine`"")
    $null = $sb.AppendLine("`t`ttexturefile = `"$tex`"")
    $null = $sb.AppendLine("`t`teffectFile = `"gfx/FX/buttonstate.lua`"")
    foreach ($rot in @('-90.0', '90.0')) {
        $null = $sb.AppendLine("`t`tanimation = {")
        $null = $sb.AppendLine("`t`t`tanimationmaskfile = `"$tex`"")
        $null = $sb.AppendLine("`t`t`tanimationtexturefile = `"gfx/interface/goals/shine_overlay.dds`"")
        $null = $sb.AppendLine("`t`t`tanimationrotation = $rot")
        $null = $sb.AppendLine("`t`t`tanimationlooping = no")
        $null = $sb.AppendLine("`t`t`tanimationtime = 0.75")
        $null = $sb.AppendLine("`t`t`tanimationdelay = 0")
        $null = $sb.AppendLine("`t`t`tanimationblendmode = `"add`"")
        $null = $sb.AppendLine("`t`t`tanimationtype = `"scrolling`"")
        $null = $sb.AppendLine("`t`t`tanimationrotationoffset = { x = 0.0 y = 0.0 }")
        $null = $sb.AppendLine("`t`t`tanimationtexturescale = { x = 1.0 y = 1.0 }")
        $null = $sb.AppendLine("`t`t}")
    }
    $null = $sb.AppendLine("`t`tlegacy_lazy_load = no")
    $null = $sb.AppendLine("`t}")
}

$null = $sb.AppendLine()
$null = $sb.AppendLine('}')

# 0.75 这种小数点在这个脚本里是字面量，不需要本地化处理

$text = $sb.ToString().Replace('`t', "`t")
[System.IO.File]::WriteAllText($outAbs, $text, $utf8NoBom)
Write-Output ("  写出 {0,-52} {1,8:N0} 字节" -f $outRel, (Get-Item -LiteralPath $outAbs).Length)

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '======== 2. 自检 ========'

$fail = 0

$bom = ([System.IO.File]::ReadAllBytes($outAbs))[0..2] -join ','
if ($bom -eq '239,187,191') { Write-Output '  [FAIL] 写出的 .gfx 带 BOM（脚本文件不能带）'; $fail++ }
else { Write-Output '  [OK ] 无 BOM' }

$lum = ([regex]::Matches($text, '\{')).Count
$rum = ([regex]::Matches($text, '\}')).Count
if ($lum -eq $rum) { Write-Output ("  [OK ] 括号配平  {0} / {1}" -f $lum, $rum) }
else { Write-Output ("  [FAIL] 括号不平  {0} / {1}" -f $lum, $rum); $fail++ }

# 🚩 注意：本文件行尾是 \r\n，正则里【不要用行尾 $】，否则 \r 会挡住匹配。
$total = ([regex]::Matches($text, '(?m)^\t\tname = "GFX_')).Count
$nShine = ([regex]::Matches($text, '(?m)^\t\tname = "GFX_[^"]*_shine"')).Count
$nIcon = $total - $nShine
# 🚩 期望值 = 已交付的 dds 数 + 兜底 sprites（美术未交付的国策图标）
$exp = $icons.Count + $placeholder.Count
if ($nIcon -eq $exp) { Write-Output ("  [OK ] 本体 sprite = {0}（{1} 张交付 + {2} 张兜底）" -f $nIcon, $icons.Count, $placeholder.Count) }
else { Write-Output ("  [FAIL] 本体 sprite = {0}，期望 {1}" -f $nIcon, $exp); $fail++ }
if ($nShine -eq $exp) { Write-Output ("  [OK ] _shine sprite = {0}" -f $nShine) }
else { Write-Output ("  [FAIL] _shine sprite = {0}，期望 {1}" -f $nShine, $exp); $fail++ }

# 每张 DDS 都要被引用到
$missing = @()
foreach ($ic in $icons) {
    $needle = "gfx/interface/hof_ic/focus/$($ic.BaseName).dds"
    if (-not $text.Contains($needle)) { $missing += $ic.BaseName }
}
if ($missing.Count -eq 0) { Write-Output ("  [OK ] {0} 张 DDS 全部被引用" -f $icons.Count) }
else { Write-Output ("  [FAIL] 未引用：" + ($missing -join ', ')); $fail++ }

# 兜底 sprite 也必须真的被注册进去（否则等于没兜）
if ($placeholder.Count -gt 0) {
    $nPh = @($placeholder | Where-Object { $text.Contains("name = `"$($_.Name)`"") }).Count
    if ($nPh -eq $placeholder.Count) { Write-Output ("  [OK ] 兜底 sprite {0} 张全部注册（美术未交付的国策图标）" -f $nPh) }
    else { Write-Output ("  [FAIL] 兜底 sprite 只注册了 {0}/{1}" -f $nPh, $placeholder.Count); $fail++ }
}

# shine_overlay 这张共享贴图必须真的存在
$shineTex = 'F:\Hearts.of.Iron.IV.v1.19.3.0\gfx\interface\goals\shine_overlay.dds'
if (Test-Path $shineTex) { Write-Output '  [OK ] 共享光泽贴图 shine_overlay.dds 存在' }
else { Write-Output "  [FAIL] 找不到 $shineTex"; $fail++ }

Write-Output ''
if ($fail -eq 0) { Write-Output '全部自检通过' } else { throw "自检失败 $fail 项" }

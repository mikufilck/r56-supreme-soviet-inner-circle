# gen-hof-ma-icons.ps1
# ---------------------------------------------------------------------------
# 把【共享国策线（S5 经互会）】的图标注册成 sprite —— 国策版 + 民族精神版。
#
# 来源（两条并行）：
#   art/focus/ma/GFX_hof_ma_<名>_focus.png  -> 100x88 RGBA -> gfx/interface/hof_ma/focus/GFX_hof_ma_<名>.dds
#   art/focus/ma/GFX_idea_hof_ma_<名>.png   ->  60x60 RGBA -> gfx/interface/hof_ma/ideas/GFX_idea_hof_ma_<名>.dds
#
# 🚩 国策图标【必须】同时注册一张以 `_shine` 结尾的光泽 sprite，否则图标显示异常。
#    贴图不用另外画：全游戏 5900+ 个 _shine 全都是同一张
#    gfx/interface/goals/shine_overlay.dds（动画叠加），mask / texturefile 指向图标自己的 dds。
#    蓝本：原版 interface/goals_shine.gfx；本项目 interface/hof_ic_focus_icons.gfx。
# ⚠️ 民族精神（idea / dynamic_modifier）的图【不需要】_shine —— 见原版 interface/ideas.gfx。
#
# 产出：mod/heart_of_iron/interface/hof_ma_icons.gfx
# 用法：powershell -NoProfile -ExecutionPolicy Bypass -File build\gen-hof-ma-icons.ps1
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$ModRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$focusDir = Join-Path $ModRoot 'gfx\interface\hof_ma\focus'
$ideaDir  = Join-Path $ModRoot 'gfx\interface\hof_ma\ideas'
$outRel   = 'interface/hof_ma_icons.gfx'
$outAbs   = Join-Path $ModRoot ($outRel -replace '/', '\')

function Get-DdsSize([string]$path) {
    $b = [System.IO.File]::ReadAllBytes($path)
    if ($b.Length -lt 128 -or $b[0] -ne 0x44 -or $b[1] -ne 0x44 -or $b[2] -ne 0x53 -or $b[3] -ne 0x20) {
        throw "不是 DDS：$path"
    }
    $h = [BitConverter]::ToUInt32($b, 12)
    $w = [BitConverter]::ToUInt32($b, 16)
    return @{ W = [int]$w; H = [int]$h; Bytes = $b.Length }
}

Write-Output '======== 0. 扫描 S5 图标 DDS ========'
if (-not (Test-Path $focusDir)) { throw "国策图标目录不存在：$focusDir" }
if (-not (Test-Path $ideaDir))  { throw "民族精神图标目录不存在：$ideaDir" }

$focusIcons = @(Get-ChildItem $focusDir -File -Filter 'GFX_*.dds' | Sort-Object Name)
$ideaIcons  = @(Get-ChildItem $ideaDir  -File -Filter 'GFX_idea_*.dds' | Sort-Object Name)
if ($focusIcons.Count -eq 0) { throw "国策图标目录里没有 GFX_*.dds：$focusDir" }
if ($ideaIcons.Count  -eq 0) { throw "民族精神图标目录里没有 GFX_idea_*.dds：$ideaDir" }

Write-Output ("  国策图标 {0} 张 · 民族精神图标 {1} 张" -f $focusIcons.Count, $ideaIcons.Count)

# ---- 自检 ①：尺寸 ----
$sizeBad = @()
foreach ($f in $focusIcons) {
    $s = Get-DdsSize $f.FullName
    if ($s.W -ne 100 -or $s.H -ne 88) { $sizeBad += "$($f.Name)($($s.W)x$($s.H))" }
}
foreach ($f in $ideaIcons) {
    $s = Get-DdsSize $f.FullName
    if ($s.W -ne 60 -or $s.H -ne 60) { $sizeBad += "$($f.Name)($($s.W)x$($s.H))" }
}
if ($sizeBad.Count -gt 0) { throw ("尺寸不合规（国策须 100x88、民族精神须 60x60）：" + ($sizeBad -join ', ')) }
Write-Output '  [OK ] 尺寸：国策图标 100x88 · 民族精神图标 60x60'

# ---- 自检 ②：民族精神图标必须真的是 32 位带 alpha（否则边角不会透明）----
$alphaBad = @()
foreach ($f in @($focusIcons + $ideaIcons)) {
    $b = [System.IO.File]::ReadAllBytes($f.FullName)
    $rgbBits = [BitConverter]::ToUInt32($b, 88)      # 32 = 每像素 32 位
    $aMask   = [BitConverter]::ToUInt32($b, 104)     # 4278190080 = 0xFF000000 = 有 alpha 通道
    # ⚠️ PS 5.1 里写 0xFF000000 会被解析成【负的 Int32】(-16777216)，与 UInt32 比永远不等 ⇒
    #    这里必须写十进制字面量 4278190080（踩过）。
    if ($rgbBits -ne 32 -or $aMask -ne 4278190080) { $alphaBad += $f.Name }
}
if ($alphaBad.Count -gt 0) { throw ("这些 DDS 没有 32 位 alpha 通道：" + ($alphaBad -join ', ')) }
Write-Output '  [OK ] 全部为 32 位 RGBA（边角透明的前提）'

# ---- 自检 ③：名字前缀 ----
$badName = @($focusIcons | Where-Object { $_.BaseName -notlike 'GFX_hof_ma_*' } | ForEach-Object { $_.Name })
$badName += @($ideaIcons | Where-Object { $_.BaseName -notlike 'GFX_idea_hof_ma_*' } | ForEach-Object { $_.Name })
if ($badName.Count -gt 0) { throw ("命名不合规（国策须 GFX_hof_ma_*、民族精神须 GFX_idea_hof_ma_*）：" + ($badName -join ', ')) }
Write-Output '  [OK ] 命名：国策 GFX_hof_ma_* · 民族精神 GFX_idea_hof_ma_*'

# ===========================================================================
# 发射 .gfx
# ===========================================================================
$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# S5 经互会通用线的图标 sprite（由 build/gen-hof-ma-icons.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 两类：')
$null = $sb.AppendLine('#   ① 国策版 GFX_hof_ma_<名>（100x88）+ 同名 _shine —— 国策 icon 用')
$null = $sb.AppendLine('#   ② 民族精神版 GFX_idea_hof_ma_<名>（60x60）—— idea 的 picture / DM 的 icon 用')
$null = $sb.AppendLine('# 素材：真实历史徽标（经互会旗徽 / 华约徽 / 共产国际徽 / 国际学联旗），')
$null = $sb.AppendLine('#       见 docs/un-focus/06-s5-emblem-icons.md')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()
$null = $sb.AppendLine('spriteTypes = {')
$null = $sb.AppendLine()

foreach ($f in $focusIcons) {
    $name = $f.BaseName
    $tex  = "gfx/interface/hof_ma/focus/$($f.Name)"
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
    $null = $sb.AppendLine()
}

$null = $sb.AppendLine('')
$null = $sb.AppendLine("`t# ========== 民族精神版（idea 的 picture / DM 的 icon 用；不需要 _shine）==========")

foreach ($f in $ideaIcons) {
    $name = $f.BaseName
    $tex  = "gfx/interface/hof_ma/ideas/$($f.Name)"
    $null = $sb.AppendLine("`t# ---------------- $name ----------------")
    $null = $sb.AppendLine("`tSpriteType = {")
    $null = $sb.AppendLine("`t`tname = `"$name`"")
    $null = $sb.AppendLine("`t`ttexturefile = `"$tex`"")
    $null = $sb.AppendLine("`t}")
    $null = $sb.AppendLine()
}

$null = $sb.AppendLine('}')

$text = $sb.ToString()
[System.IO.File]::WriteAllText($outAbs, $text, $utf8NoBom)

$bom = (Get-Content -LiteralPath $outAbs -Encoding Byte -TotalCount 3) -join ','
$flag = if ($bom -eq '239,187,191') { '有BOM(错误)' } else { '无BOM(正确)' }
Write-Output ("  写出 {0}  {1:N0} 字节  {2}" -f $outRel, (Get-Item -LiteralPath $outAbs).Length, $flag)

# ---- 自检 ④：写出来的 gfx 覆盖全部 DDS ----
$txt = [System.IO.File]::ReadAllText($outAbs)
$miss = @()
foreach ($f in $focusIcons) {
    if ($txt -notmatch [regex]::Escape('name = "' + $f.BaseName + '"')) { $miss += $f.BaseName }
    if ($txt -notmatch [regex]::Escape('name = "' + $f.BaseName + '_shine"')) { $miss += "$($f.BaseName)_shine" }
}
foreach ($f in $ideaIcons) {
    if ($txt -notmatch [regex]::Escape('name = "' + $f.BaseName + '"')) { $miss += $f.BaseName }
}
if ($miss.Count -gt 0) { throw ("这些 sprite 没写进 gfx：" + ($miss -join ', ')) }

$spriteCount = ([regex]::Matches($txt, '(?m)^\s*SpriteType = \{')).Count
$expect = $focusIcons.Count * 2 + $ideaIcons.Count
if ($spriteCount -ne $expect) { throw "SpriteType 数 $spriteCount != 期望 $expect" }

Write-Output ("  [OK ] sprite 数 {0}（国策 {1}x2 + 民族精神 {2}），全部 DDS 都有对应 sprite" -f $spriteCount, $focusIcons.Count, $ideaIcons.Count)
Write-Output ''
Write-Output ("==================== 失败项: 0 ====================")

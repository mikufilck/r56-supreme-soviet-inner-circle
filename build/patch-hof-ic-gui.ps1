# =============================================================================
# 给 interface/hof_ic_scripted_gui.gui 接线（S3）
# -----------------------------------------------------------------------------
# 本脚本是【幂等】的，可以在任意状态下反复运行：
#   未接线 -> 接线；已接线但方括号写错 -> 修正；已正确 -> 原样通过。
#
# 改四件事：
#   1. 席位框 iconType 的 spriteType 清空 —— 交给 inlay window 的 scripted_images
#      决定显示"空席框"还是"已占框"。
#   2. 席位名字 instantTextBoxType：text = "hof_ic_seat_empty_text"
#      -> context_aware_text = [hof_ic_slot_N_name]
#   3. 席位特质同理 -> context_aware_text = [hof_ic_slot_N_trait]
#   4. 修正历史错误：context_aware_text 少了方括号
#
# ⚠️ 方括号是关键，不是可选的：
#   原版 HOI4 的 GUI 里两种写法含义不同 ——
#        context_aware_text = "Some_loc_key"      ← 引号   = 普通本地化键
#        context_aware_text = [SomeDefinedText]   ← 方括号 = 脚本本地化 defined_text
#    我们的 hof_ic_slot_N_name 是 defined_text（common/scripted_localisation），
#    所以必须用方括号。写成裸的（既不引号也不方括号）会被当成字面量，
#    界面上就直接把 hof_ic_slot_1_name 这串字印出来（已踩过）。
#    依据：原版 GER_inner_circle_scripted_gui.gui 里两种都有实例 ——
#        context_aware_text = "GER_fuhrer_name_text"
#        context_aware_text = [GetAscendedAdvisorTraitName1]
# =============================================================================

$ErrorActionPreference = 'Stop'

$guiPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\interface\hof_ic_scripted_gui.gui'

if (-not (Test-Path $guiPath)) { throw "找不到 $guiPath" }

$lines = [System.IO.File]::ReadAllLines($guiPath)
Write-Output "文件行数 = $($lines.Count)"

# -----------------------------------------------------------------------------
# 前置自检：只有当需要"按次序替换"时，才要求席位容器按 1..7 排列
# -----------------------------------------------------------------------------
$needOrderedPatch = @($lines | Where-Object { $_ -match '^\s*text = "hof_ic_seat_empty_text"\s*$' }).Count -gt 0

if ($needOrderedPatch) {
    $seatOrder = @()
    foreach ($l in $lines) {
        if ($l -match '^\s*name = "hof_ic_seat_(\d+)_container"\s*$') { $seatOrder += [int]$Matches[1] }
    }
    Write-Output "席位容器次序 = $($seatOrder -join ',')  (期望 1,2,3,4,5,6,7)"
    if (($seatOrder -join ',') -ne '1,2,3,4,5,6,7') {
        throw '席位容器不是按 1..7 顺序排列，按次序替换会错位，中止。'
    }
}
else {
    Write-Output '未发现待接线的 text 行 —— 之前已接线过，本次只做幂等校验与修正。'
}

# -----------------------------------------------------------------------------
# 逐行处理
# -----------------------------------------------------------------------------
$out = New-Object System.Collections.Generic.List[string]
$nFrame      = 0
$nName       = 0
$nTrait      = 0
$nBracketFix = 0

foreach ($line in $lines) {

    # 1) 席位框：清空 spriteType，交给 scripted_images
    if ($line -match '^(\s*)spriteType = "GFX_hof_ic_seat_frame_empty"(\s*)$') {
        $out.Add($Matches[1] + 'spriteType = ""' + $Matches[2])
        $nFrame++
        continue
    }

    # 2) 席位名字（按出现次序编号；仅未接线时需要）
    if ($line -match '^(\s*)text = "hof_ic_seat_empty_text"(\s*)$') {
        $nName++
        $out.Add($Matches[1] + "context_aware_text = [hof_ic_slot_${nName}_name]" + $Matches[2])
        continue
    }

    # 3) 席位特质
    if ($line -match '^(\s*)text = "hof_ic_seat_trait_empty_text"(\s*)$') {
        $nTrait++
        $out.Add($Matches[1] + "context_aware_text = [hof_ic_slot_${nTrait}_trait]" + $Matches[2])
        continue
    }

    # 4) 修复历史错误：裸的 context_aware_text（缺方括号）
    if ($line -match '^(\s*)context_aware_text = (hof_ic_slot_\d+_(?:name|trait))(\s*)$') {
        $out.Add($Matches[1] + 'context_aware_text = [' + $Matches[2] + ']' + $Matches[3])
        $nBracketFix++
        continue
    }

    $out.Add($line)
}

Write-Output "  清空席位框 spriteType = $nFrame"
Write-Output "  接线席位名字           = $nName"
Write-Output "  接线席位特质           = $nTrait"
Write-Output "  补方括号               = $nBracketFix"

# .gui 是脚本类文件 -> UTF-8 不带 BOM
[System.IO.File]::WriteAllLines($guiPath, $out, (New-Object System.Text.UTF8Encoding($false)))

# -----------------------------------------------------------------------------
# 写后自检（幂等：这些条件在正确状态下永远成立）
# -----------------------------------------------------------------------------
Write-Output ''
Write-Output '======== 写后自检 ========'

$after = [System.IO.File]::ReadAllLines($guiPath)
$fail  = 0

$c1 = @($after | Where-Object { $_ -match '^\s*spriteType = "GFX_hof_ic_seat_frame_empty"\s*$' }).Count
$ok1 = if ($c1 -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok1] 旧硬编码席位框 spriteType 已清零（实际 $c1）"

$c2 = @($after | Where-Object { $_ -match '^\s*context_aware_text = \[hof_ic_slot_\d+_name\]\s*$' }).Count
$ok2 = if ($c2 -eq 7) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok2] context_aware_text = [.._name] 共 $c2 处（期望 7）"

$c3 = @($after | Where-Object { $_ -match '^\s*context_aware_text = \[hof_ic_slot_\d+_trait\]\s*$' }).Count
$ok3 = if ($c3 -eq 7) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok3] context_aware_text = [.._trait] 共 $c3 处（期望 7）"

# 这条哨兵专抓"方括号掉了"这个具体事故。
# ⚠️ 否定字符类里必须排除空白（\s），否则 `\s*` 会回溯成零个空格，
#    让 `=` 后面的那个空格被 [^\["...] 匹配上，导致每行都误报。
$c4 = @($after | Where-Object { $_ -match '^\s*context_aware_text\s*=\s*(?![\["\s])' }).Count
$ok4 = if ($c4 -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok4] 无裸 context_aware_text（不以 [ 或引号开头）共 $c4 处（期望 0）"

$c5 = @($after | Where-Object { $_ -match '^\s*text = "hof_ic_seat_empty_text"\s*$' }).Count
$ok5 = if ($c5 -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok5] 旧的静态 text 行已清零（实际 $c5）"

$c6 = @($after | Where-Object { $_ -match '^\s*spriteType = ""\s*$' }).Count
$ok6 = if ($c6 -ge 8) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok6] spriteType 留空共 $c6 处（领袖位 1 + 席位框 7 = 8 起）"

$txt = [System.IO.File]::ReadAllText($guiPath)
$o  = ([regex]::Matches($txt, '\{')).Count
$cl = ([regex]::Matches($txt, '\}')).Count
$ok7 = if ($o -eq $cl) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok7] 花括号配平 {=$o }=$cl"

$ob = ([regex]::Matches($txt, '\[')).Count
$cb = ([regex]::Matches($txt, '\]')).Count
$ok8 = if ($ob -eq $cb) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok8] 方括号配平 [=$ob ]=$cb"

$bom = (Get-Content -LiteralPath $guiPath -Encoding Byte -TotalCount 3) -join ','
$ok9 = if ($bom -eq '239,187,191') { $fail++; 'FAIL' } else { 'OK ' }
Write-Output "  [$ok9] 无 BOM（.gui 必须无 BOM）"

Write-Output ''
if ($fail -gt 0) { throw "自检失败 $fail 项" }
Write-Output '接线完成，全部自检通过'

# =============================================================================
# 生成 common/scripted_localisation/hof_ic_scripted_loc.txt
# -----------------------------------------------------------------------------
# 为什么用脚本生成：
#   7 个席位 × 7 名角色 × （名字 + 特质）= 112 个 text 块，手写极易出错。
#
# 原理（已对照原版 common/scripted_localisation/00_scripted_localisation.txt 核实）：
#   defined_text = {
#       name = <动态键>
#       text = { trigger = { <条件> } localization_key = <文案键> }
#       ...
#       text = { localization_key = <兜底文案键> }   # 无 trigger = 总是通过
#   }
#
# 席位变量语义：0 / 未赋值 = 空席
# =============================================================================

$ErrorActionPreference = 'Stop'

$outPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\scripted_localisation\hof_ic_scripted_loc.txt'
$outDir  = Split-Path -Parent $outPath
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# 角色序号 -> 文案键后缀（改动花名册时只改这里）
#
# ⚠️ 必须用【普通数组】+ 下标 $roster[$idx - 1]。
#    不要写成 [ordered]@{ 1 = 'x'; 2 = 'y' } 再用 $roster[$idx]：
#    PowerShell 会把 OrderedDictionary 的整数下标解析成【位置下标】，
#    $od[1] 拿到的是第 2 个值，导致整张映射表静默错位一格。
#    （此 bug 已发生过一次，末尾的自检就是为了防它复发。）
$roster = @(
    'lev_trotsky'          # 序号 1  列夫·托洛茨基
    'nikolay_bukharin'     # 序号 2  尼古拉·布哈林
    'aleksey_rykov'        # 序号 3  阿列克谢·李可夫
    'grigory_zinovyev'     # 序号 4  格里戈里·季诺维也夫
    'lev_kamenev'          # 序号 5  列夫·加米涅夫
    'ivan_smirnov'         # 序号 6  伊万·斯米尔诺夫
    'leonid_serebryakov'   # 序号 7  列昂尼德·谢列布里亚科夫
)
if ($roster.Count -ne 7) { throw "花名册必须是 7 人，实际 $($roster.Count) 人" }

$sb = New-Object System.Text.StringBuilder
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine('# 核心圈 · 席位动态文本（由 build/gen-hof-ic-scripted-loc.ps1 生成，勿手改）')
$null = $sb.AppendLine('# -----------------------------------------------------------------------------')
$null = $sb.AppendLine('# 每个席位有两个动态键：')
$null = $sb.AppendLine('#   hof_ic_slot_<N>_name   —— 席位上的角色名')
$null = $sb.AppendLine('#   hof_ic_slot_<N>_trait  —— 席位上的角色头衔/特质')
$null = $sb.AppendLine('# 空席走兜底条目（无 trigger 的 text 总是通过）。')
$null = $sb.AppendLine('# 角色序号：1 托洛茨基 / 2 布哈林 / 3 李可夫 / 4 季诺维也夫')
$null = $sb.AppendLine('#           5 加米涅夫 / 6 斯米尔诺夫 / 7 谢列布里亚科夫')
$null = $sb.AppendLine('# =============================================================================')
$null = $sb.AppendLine()

for ($seat = 1; $seat -le 7; $seat++) {

    foreach ($kind in @('name', 'trait')) {

        $prefix   = if ($kind -eq 'name') { 'hof_ic_name_' } else { 'hof_ic_trait_' }
        $fallback = if ($kind -eq 'name') { 'hof_ic_seat_empty_text' } else { 'hof_ic_seat_trait_empty_text' }

        $null = $sb.AppendLine('defined_text = {')
        $null = $sb.AppendLine("`tname = hof_ic_slot_${seat}_${kind}")

        for ($idx = 1; $idx -le 7; $idx++) {
            $null = $sb.AppendLine('')
            $null = $sb.AppendLine("`ttext = {")
            $null = $sb.AppendLine("`t`ttrigger = { check_variable = { hof_ic_slot_${seat} = $idx } }")
            $null = $sb.AppendLine("`t`tlocalization_key = ${prefix}$($roster[$idx - 1])")
            $null = $sb.AppendLine("`t}")
        }

        $null = $sb.AppendLine('')
        $null = $sb.AppendLine("`ttext = {")
        $null = $sb.AppendLine("`t`tlocalization_key = $fallback")
        $null = $sb.AppendLine("`t}")
        $null = $sb.AppendLine('}')
        $null = $sb.AppendLine('')
    }
}

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))

# ---------------------------------------------------------------- 统计与自检
$lines = (Get-Content -LiteralPath $outPath).Count
$bytes = (Get-Item -LiteralPath $outPath).Length
$bom   = (Get-Content -LiteralPath $outPath -Encoding Byte -TotalCount 3) -join ','

Write-Output "OUT   = $outPath"
Write-Output "LINES = $lines"
Write-Output "BYTES = $bytes"
Write-Output "BOM   = $(if ($bom -eq '239,187,191') { '有 BOM（错误！脚本 .txt 必须无 BOM）' } else { '无（正确）' })"
Write-Output "defined_text 数量 = $((Select-String -LiteralPath $outPath -Pattern '^defined_text = \{').Count)  (期望 14)"
Write-Output "text 块数量      = $((Select-String -LiteralPath $outPath -Pattern '^\ttext = \{').Count)  (期望 112)"
Write-Output ''

# 自检：回读生成结果，确认"序号 1"确实映射到托洛茨基 —— 防下标错位复发
# 注意：这里必须用 \s+ 而不是 \s*，否则 \s* 会贪婪吃掉换行，
# 随后的 \r?\n 就再也匹配不到 → 正则会假报"映射错位"。
$txt   = [System.IO.File]::ReadAllText($outPath)
$probe = [regex]::Match($txt, 'check_variable = \{ hof_ic_slot_1 = 1 \}\s+localization_key = (\S+)')
$got   = $probe.Groups[1].Value
Write-Output "自检 slot_1=1 -> $got"
Write-Output "     期望      -> hof_ic_name_lev_trotsky"
if ($got -ne 'hof_ic_name_lev_trotsky') { throw '映射错位！生成器下标仍有问题，已中止。' }
Write-Output '自检通过：映射表未错位'

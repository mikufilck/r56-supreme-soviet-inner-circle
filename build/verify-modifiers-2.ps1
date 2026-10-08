# 核实第二批词条/效果：
#   1) 兵种级进攻加成到底叫什么
#   2) 外交关系类修正
#   3) 给将领加特质 / 升级 的效果写法
#   4) 生产效率上限 / 增长 两个词条
# 扫描范围放宽到 R56+原版 的全部 common/ 与 events/
$ErrorActionPreference = 'Stop'

$roots = @(
    @{ tag = 'R56';     dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ tag = 'VANILLA'; dir = 'F:\Hearts of Iron IV' }
)

# 关键词 -> 收集匹配的 token
$kw = @('sub_unit','infantry','cavalry','armor','artillery','mechanized','motorized',
        'attack','defence','opinion','efficiency','leader','trait','skill',
        'production_speed','production_factory')

$tok = @{}      # token -> @{ count; example }
$eff = @{}      # 效果名 -> example

$scanDirs = @('common', 'events')

foreach ($r in $roots) {
    foreach ($sd in $scanDirs) {
        $d = Join-Path $r.dir $sd
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
            $lines = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $m = [regex]::Match($lines[$i], '^\s*([a-z][a-z0-9_]{2,})\s*=')
                if (-not $m.Success) { continue }
                $t = $m.Groups[1].Value
                $low = $t.ToLower()
                $hit = $false
                foreach ($k in $kw) { if ($low.Contains($k)) { $hit = $true; break } }
                if (-not $hit) { continue }
                if (-not $tok.ContainsKey($t)) { $tok[$t] = @{ Count = 0; Ex = "$($r.tag)/$($f.Name):$($i+1)  " + $lines[$i].Trim() } }
                $tok[$t].Count++
            }
        }
    }
}

$dst = Join-Path $PSScriptRoot '..\docs\reference\reports\modifier-words-2.txt'
$out = New-Object System.Collections.ArrayList
[void]$out.Add('# 第二批词条核实（兵种进攻 / 外交关系 / 将领特质 / 生产效率）')
[void]$out.Add('# 扫描范围：R56 + 原版 的 common/ 与 events/ 全部 .txt')
[void]$out.Add('')
[void]$out.Add("## 命中的 token 共 $($tok.Count) 个（按字母序，含出现次数与一个例子）")
[void]$out.Add('')
[void]$out.Add('| token | 次数 | 例子 |')
[void]$out.Add('| --- | --- | --- |')
foreach ($t in ($tok.Keys | Sort-Object)) {
    [void]$out.Add("| ``$t`` | $($tok[$t].Count) | $($tok[$t].Ex -replace '\|','\|') |")
}

[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst ; $($tok.Count) tokens"

# 重点关注项直接打印，省得翻文件
Write-Output ''
Write-Output '===== 关键问题速答 ====='
foreach ($probe in @('army_sub_unit_infantry_attack_factor','army_sub_unit_cavalry_attack_factor',
                     'army_sub_unit_armor_attack_factor','army_sub_unit_infantry_defence_factor',
                     'opinion_gain_monthly_factor','opinion_gain_monthly_same_ideology_factor',
                     'production_factory_efficiency_gain_factor','production_factory_max_efficiency_factor',
                     'production_speed_buildings_factor','add_unit_leader_trait','add_trait',
                     'add_skill_level','add_unit_leader_xp','set_leader_skill','add_opinion_modifier')) {
    if ($tok.ContainsKey($probe)) { Write-Output ("  OK   $probe  x" + $tok[$probe].Count + "   " + $tok[$probe].Ex) }
    else { Write-Output ("  MISS $probe") }
}

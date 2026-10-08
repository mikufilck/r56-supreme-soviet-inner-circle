# 核实第三批：combat_width / 装甲攻击 / 资源产量 / 建筑位
$ErrorActionPreference = 'Stop'

$roots = @(
    @{ tag = 'R56';     dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ tag = 'VANILLA'; dir = 'F:\Hearts of Iron IV' }
)

# token -> 出现次数 / 例子
$tok = @{}
$effects = @()

$kwEffect = @('building_slots','add_building_construction','add_extra_state_shared','add_resource',
              'combat_width','army_sub_unit_armor','armor_attack','tank_attack','resources_factor',
              'local_resources')

foreach ($r in $roots) {
    foreach ($sd in @('common', 'events')) {
        $d = Join-Path $r.dir $sd
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
            $lines = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $ln = $lines[$i]

                # 1) modifier 型 token
                $m = [regex]::Match($ln, '^\s*([a-z][a-z0-9_]{3,})\s*=')
                if ($m.Success) {
                    $t = $m.Groups[1].Value
                    if ($t -match 'combat_width|armor|tank|resources|building_slots|_slots') {
                        if (-not $tok.ContainsKey($t)) { $tok[$t] = @{ Count = 0; Ex = "$($r.tag)/$($f.Name):$($i+1)  " + $ln.Trim() } }
                        $tok[$t].Count++
                    }
                }

                # 2) 效果型
                foreach ($k in $kwEffect) {
                    if ($ln -match ('^\s*' + $k)) {
                        $e = $ln.Trim()
                        if ($effects -notcontains $e) { $effects += ("$($r.tag)/$($f.Name):$($i+1)  " + $e) }
                    }
                }
            }
        }
    }
}

$out = New-Object System.Collections.ArrayList
[void]$out.Add('# 第三批核实：战场宽度 / 装甲攻击 / 资源 / 建筑位')
[void]$out.Add('')
[void]$out.Add('## modifier 型 token')
[void]$out.Add('| token | 次数 | 例子 |')
[void]$out.Add('| --- | --- | --- |')
foreach ($t in ($tok.Keys | Sort-Object)) { [void]$out.Add("| ``$t`` | $($tok[$t].Count) | $($tok[$t].Ex) |") }
[void]$out.Add('')
[void]$out.Add('## 效果型（去重后的样本）')
[void]$out.Add('')
foreach ($e in ($effects | Select-Object -First 60)) { [void]$out.Add("- $e") }

$dst = Join-Path $PSScriptRoot '..\docs\reference\reports\modifier-words-3.txt'
[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst ; $($tok.Count) tokens"

Write-Output ''
Write-Output '===== 关键 probe ====='
foreach ($p in @('combat_width','armor_attack_factor','armored_attack_factor','tank_attack_factor',
                 'modifier_army_sub_unit_armor_attack_factor','modifier_army_sub_unit_tank_attack_factor',
                 'local_resources_factor','resources_factor','resource_gain_factor',
                 'global_building_slots_factor','state_building_slots_factor','local_building_slots_factor',
                 'industrial_capacity_factory','production_speed_buildings_factor')) {
    if ($tok.ContainsKey($p)) { Write-Output ("  OK   $p  x" + $tok[$p].Count + "   " + $tok[$p].Ex) }
    else { Write-Output ("  MISS $p") }
}
Write-Output ''
Write-Output '===== 建筑位 / 资源 效果样本 ====='
foreach ($e in ($effects | Where-Object { $_ -match 'building_slots|add_resource|add_building_construction' } | Select-Object -First 18)) {
    Write-Output ("  " + $e)
}

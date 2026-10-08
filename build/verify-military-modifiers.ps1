# 核实：军事/补给/进攻类 modifier 词条在 R56+原版里真实存在
# 目的：为"个人线国策往角色特质叠数值"提供一份可用词汇表，不靠记忆（AGENTS 规则 7）
$ErrorActionPreference = 'Stop'

$roots = @(
    @{ tag = 'R56';     dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ tag = 'VANILLA'; dir = 'F:\Hearts of Iron IV' }
)

# 待核实词条（按用途分组）
$cands = @{
    '军事-进攻' = @('army_attack_factor','army_core_attack_factor','division_attack_factor','breakthrough_factor',
                  'army_artillery_attack_factor','army_artillery_defence_factor','army_sub_unit_infantry_attack_factor',
                  'army_sub_unit_armor_attack_factor','army_sub_unit_cavalry_attack_factor','armor_attack_factor')
    '军事-防御' = @('army_defence_factor','army_core_defence_factor','max_dig_in_factor','dig_in_speed_factor',
                  'surrender_limit','max_surrender_limit_offset','cas_damage_reduction','army_org_regain')
    '军事-组织/士气' = @('army_org_factor','army_morale_factor','army_org_regain','army_sub_unit_infantry_max_org_factor')
    '军事-补给/后勤' = @('supply_consumption_factor','out_of_supply_factor','attrition','army_logistics_factor',
                     'military_leader_cost_factor','general_cost_factor','naval_coordination','positioning')
    '军事-训练/动员' = @('training_time_factor','conscription_factor','conscription','mobilization_speed',
                     'mobile_equipment_concentration','special_forces_cap','equipment_capture_factor')
    '军事-经验/学说' = @('experience_gain_army_factor','army_experience','land_doctrine_cost_factor',
                     'command_power_gain_mult','max_command_power')
    '科研'       = @('research_speed_factor','research_speed_factor_land','breakthrough_progress_factor')
    '工业'       = @('industrial_capacity_factory','industrial_capacity_dockyard','production_speed_buildings_factor',
                  'production_speed_industrial_complex_factor','production_speed_arms_factory_factor',
                  'production_factory_max_efficiency_factor','production_factory_efficiency_gain_factor',
                  'line_change_production_efficiency_factor','consumer_goods_factor','conversion_cost_civ_to_mil_factor')
    '政治'       = @('political_power_factor','political_power_gain','stability_factor','war_support_factor',
                  'communism_drift','drift_defence_factor','political_advisor_cost_factor','efficiency_growth_factor')
    '国际'       = @('send_volunteer_factor','opinion_gain_monthly_same_ideology_factor','operative_slot',
                  'subversive_activites_upkeep','boost_ideology_mission_factor')
}

$searchDirs = @('common\ideas', 'common\dynamic_modifiers', 'common\scripted_effects')

$out = New-Object System.Collections.ArrayList
[void]$out.Add('# 军事/补给/进攻类词条核实（R56 + 原版）')
[void]$out.Add('# 只在 common/ideas、common/dynamic_modifiers、common/scripted_effects 里找')
[void]$out.Add('')

$found = @{}
foreach ($r in $roots) {
    foreach ($sd in $searchDirs) {
        $d = Join-Path $r.dir $sd
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
            $lines = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                foreach ($grp in $cands.Keys) {
                    foreach ($w in $cands[$grp]) {
                        if ($lines[$i] -match ('^\s*' + [regex]::Escape($w) + '\s*=')) {
                            if (-not $found.ContainsKey($w)) { $found[$w] = @() }
                            if ($found[$w].Count -lt 2) {
                                $found[$w] += ("$($r.tag)/$($f.Name)`:$($i+1)  " + $lines[$i].Trim())
                            }
                        }
                    }
                }
            }
        }
    }
}

foreach ($grp in @('军事-进攻','军事-防御','军事-组织/士气','军事-补给/后勤','军事-训练/动员','军事-经验/学说','科研','工业','政治','国际')) {
    [void]$out.Add("## $grp")
    [void]$out.Add('')
    foreach ($w in $cands[$grp]) {
        if ($found.ContainsKey($w)) {
            [void]$out.Add("✅ ``$w``")
            foreach ($e in $found[$w]) { [void]$out.Add("     $e") }
        } else {
            [void]$out.Add("❌ ``$w``  —— 三个目录里都没出现，**不要用**")
        }
    }
    [void]$out.Add('')
}

$dst = Join-Path $PSScriptRoot '..\docs\reference\reports\military-modifier-words.txt'
[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst ($($out.Count) lines) ; 命中 $($found.Count) / $(($cands.Values | ForEach-Object { $_.Count } | Measure-Object -Sum).Sum)"

# Dump the German Inner Circle "personal line" focuses with their actual rewards.
# Source: R56 CN (workshop 2129897125) common/national_focus/germany.txt
# Purpose: establish the REAL scale of a per-character focus line, so we can tune
#          our own (Trotsky et al.) against measured data instead of guessing.
$ErrorActionPreference = 'Stop'

$src = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\germany.txt'
if (-not (Test-Path -LiteralPath $src)) { throw "not found: $src" }

$lines = [System.IO.File]::ReadAllLines($src)

# brace matching helper: returns index of the line holding the matching '}'
function Get-BlockEnd($lines, $startIdx) {
    $depth = 0
    for ($i = $startIdx; $i -lt $lines.Count; $i++) {
        $s = $lines[$i]
        foreach ($ch in $s.ToCharArray()) {
            if ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') {
                $depth--
                if ($depth -eq 0) { return $i }
            }
        }
    }
    return -1
}

$styleTag = 'GER_inner_circle_focus_style'

# effect-ish lines we care about
$keepRe = '^\s*(id|cost|text_icon|x|y|relative_position_id|prerequisite|available|allow_branch|mutually_exclusive|select_effect|bypass|focus|completion_reward|hidden_effect|effect_tooltip|custom_effect_tooltip|add_political_power|add_stability|add_war_support|add_popularity|add_ideas|remove_ideas|add_timed_idea|swap_ideas|add_tech_bonus|add_research_slot|add_extra_state_shared_building_slots|add_building_construction|add_dynamic_modifier|remove_dynamic_modifier|set_variable|add_to_variable|army_experience|air_experience|navy_experience|add_command_power|create_unit|division_template|unlock_decision|unlock_decision_category|add_breakthrough_progress|set_technology|create_equipment_variant|type|level|instant_build|category|name|bonus|uses|idea|modifier|tag|original_tag|has_completed_focus|always)\b'

$out = New-Object System.Collections.ArrayList
[void]$out.Add("# German Inner Circle personal-line focuses (R56) - reward dump")
[void]$out.Add("# source: $src")
[void]$out.Add("")

$i = 0
$count = 0
while ($i -lt $lines.Count) {
    if ($lines[$i] -match '^\s*focus\s*=\s*\{') {
        $end = Get-BlockEnd $lines $i
        if ($end -lt 0) { break }
        $block = $lines[$i..$end]
        $blob = ($block -join "`n")
        if ($blob -match [regex]::Escape($styleTag)) {
            $count++
            $idm = [regex]::Match($blob, '(?m)^\s*id\s*=\s*([A-Za-z0-9_]+)')
            $id = if ($idm.Success) { $idm.Groups[1].Value } else { '?' }
            $costm = [regex]::Match($blob, '(?m)^\s*cost\s*=\s*(.+?)\s*$')
            $cost = if ($costm.Success) { $costm.Groups[1].Value } else { '(default 10)' }
            $otherIdea = @([regex]::Matches($blob, 'add_ideas\s*=\s*([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
            [void]$out.Add("=====================================================================")
            [void]$out.Add("$id    cost=$cost    L$($i+1)..L$($end+1)")
            if ($otherIdea.Count -gt 0) { [void]$out.Add("  add_ideas: " + ($otherIdea -join ', ')) }
            [void]$out.Add("---------------------------------------------------------------------")
            foreach ($ln in $block) {
                if ($ln -match $keepRe) { [void]$out.Add($ln) }
            }
            [void]$out.Add("")
        }
        $i = $end + 1
    } else {
        $i++
    }
}

[void]$out.Add("TOTAL personal-line focuses with $styleTag : $count")

$dst = Join-Path (Join-Path $PSScriptRoot '..\reports') 'ger-ic-line-rewards.txt'
[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst  ($($out.Count) lines, $count focuses)"

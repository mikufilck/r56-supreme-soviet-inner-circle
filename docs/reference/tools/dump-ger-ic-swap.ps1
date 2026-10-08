# Extract the swap_ideas upgrade CHAIN of the German Inner Circle personal lines.
# Theory being tested: a personal line is ONE named office trait that gets
# upgraded tier by tier (swap_ideas), NOT a pile of separate stacking ideas.
$ErrorActionPreference = 'Stop'

$src = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\germany.txt'
if (-not (Test-Path -LiteralPath $src)) { throw "not found: $src" }
$lines = [System.IO.File]::ReadAllLines($src)

function Get-BlockEnd($lines, $startIdx) {
    $depth = 0
    for ($i = $startIdx; $i -lt $lines.Count; $i++) {
        foreach ($ch in $lines[$i].ToCharArray()) {
            if ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') { $depth--; if ($depth -eq 0) { return $i } }
        }
    }
    return -1
}

$styleTag = 'GER_inner_circle_focus_style'
$out = New-Object System.Collections.ArrayList
[void]$out.Add("# German Inner Circle personal lines - idea UPGRADE CHAINS")
[void]$out.Add("# swap_ideas pairs = the office trait being upgraded tier by tier")
[void]$out.Add("")

$i = 0
$order = New-Object System.Collections.ArrayList
while ($i -lt $lines.Count) {
    if ($lines[$i] -match '^\s*focus\s*=\s*\{') {
        $end = Get-BlockEnd $lines $i
        if ($end -lt 0) { break }
        $block = $lines[$i..$end]
        $blob = ($block -join "`n")
        if ($blob -match [regex]::Escape($styleTag)) {
            $id = [regex]::Match($blob, '(?m)^\s*id\s*=\s*([A-Za-z0-9_]+)').Groups[1].Value
            $cost = [regex]::Match($blob, '(?m)^\s*cost\s*=\s*(.+?)\s*$').Groups[1].Value
            $prereq = @([regex]::Matches($blob, 'prerequisite\s*=\s*\{\s*focus\s*=\s*([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value })
            # only real swap_ideas (not the ones inside effect_tooltip)
            $pairs = @()
            foreach ($m in [regex]::Matches($blob, 'swap_ideas\s*=\s*\{\s*remove_idea\s*=\s*([A-Za-z0-9_]+)\s*add_idea\s*=\s*([A-Za-z0-9_]+)')) {
                $p = $m.Groups[1].Value + '  ->  ' + $m.Groups[2].Value
                if ($pairs -notcontains $p) { $pairs += $p }
            }
            $addOnly = @([regex]::Matches($blob, '(?m)^\s*add_ideas\s*=\s*([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
            $addDyn = @([regex]::Matches($blob, 'add_dynamic_modifier\s*=\s*\{\s*modifier\s*=\s*([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
            $pp   = @([regex]::Matches($blob, 'add_political_power\s*=\s*(-?[0-9.]+)') | ForEach-Object { $_.Groups[1].Value })
            $xp   = @([regex]::Matches($blob, '(army|air|navy)_experience\s*=\s*(-?[0-9.]+)') | ForEach-Object { $_.Groups[0].Value })
            $slot = @([regex]::Matches($blob, 'add_extra_state_shared_building_slots\s*=\s*(-?[0-9.]+)') | ForEach-Object { $_.Groups[1].Value })
            $bld  = @([regex]::Matches($blob, 'add_building_construction\s*=\s*\{\s*type\s*=\s*([A-Za-z0-9_]+)\s*level\s*=\s*([0-9.]+)') | ForEach-Object { $_.Groups[1].Value + ' x' + $_.Groups[2].Value })
            $tech = @([regex]::Matches($blob, 'add_tech_bonus\s*=\s*\{[^}]*?(?:^|\s)name\s*=\s*([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
            $var  = @([regex]::Matches($blob, '(?m)^\s*(?:add_to_variable|set_variable)\s*=\s*\{\s*([A-Za-z0-9_]+)\s*=?\s*([-0-9.]*)\s*\}?') | ForEach-Object { $_.Groups[1].Value + '=' + $_.Groups[2].Value } | Sort-Object -Unique)
            $customTT = @([regex]::Matches($blob, 'custom_effect_tooltip\s*=\s*([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)

            [void]$out.Add("=====================================================================")
            [void]$out.Add("$id   cost=$cost")
            if ($prereq.Count -gt 0) { [void]$out.Add("  <- " + ($prereq -join ' | ')) }
            if ($pairs.Count -gt 0) {
                foreach ($p in $pairs) { [void]$out.Add("  SWAP  $p") }
            } else {
                [void]$out.Add("  SWAP  (none)")
            }
            if ($addOnly.Count -gt 0) { [void]$out.Add("  add_ideas: " + ($addOnly -join ', ')) }
            if ($addDyn.Count -gt 0) { [void]$out.Add("  dyn_mod:   " + ($addDyn -join ', ')) }
            if ($pp.Count -gt 0)   { [void]$out.Add("  PP: " + ($pp -join ', ')) }
            if ($xp.Count -gt 0)   { [void]$out.Add("  XP: " + ($xp -join ', ')) }
            if ($slot.Count -gt 0) { [void]$out.Add("  slots: " + ($slot -join ', ')) }
            if ($bld.Count -gt 0)  { [void]$out.Add("  bld: " + ($bld -join ', ')) }
            if ($tech.Count -gt 0) { [void]$out.Add("  tech: " + ($tech -join ', ')) }
            if ($var.Count -gt 0)  { [void]$out.Add("  var: " + ($var -join ', ')) }
            if ($customTT.Count -gt 0) { [void]$out.Add("  tt: " + ($customTT -join ', ')) }
            [void]$out.Add("")
        }
        $i = $end + 1
    } else { $i++ }
}

$dst = Join-Path (Join-Path $PSScriptRoot '..\reports') 'ger-ic-swap-chains.txt'
[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst ($($out.Count) lines)"

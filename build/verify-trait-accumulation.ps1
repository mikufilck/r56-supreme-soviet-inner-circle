# 核实：角色特质的"随国策累积"是怎么实现的
# 假设：个人线国策写 add_to_variable = { X = 0.05 }，X 被某个 dynamic_modifier 引用。
# 本脚本把这个链路的原文两端都抓出来，确认写法，不靠推测。
$ErrorActionPreference = 'Stop'

$roots = @(
    @{ tag = 'R56';     dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ tag = 'VANILLA'; dir = 'F:\Hearts of Iron IV' }
)

# 要核对的目标 dynamic_modifier（角色级累积容器）
$targets = @(
    'SOV_the_red_fleet_dynamic_modifier',
    'SOV_defense_industry_dynamic_modifier',
    'SOV_the_politburo_good_dynamic_modifier',
    'GER_wunderwaffen_dynamic_modifier',
    'GER_four_year_plan_initiative_modifier',
    'GER_the_inner_circle_dm'
)

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

$out = New-Object System.Collections.ArrayList
[void]$out.Add('# dynamic_modifier 定义（角色特质累积容器）—— 看 modifier 里怎么引用变量')
[void]$out.Add('')

foreach ($r in $roots) {
    $d = Join-Path $r.dir 'common\dynamic_modifiers'
    if (-not (Test-Path -LiteralPath $d)) { Write-Output "skip $($r.tag) (no dir)"; continue }
    foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
        $lines = [System.IO.File]::ReadAllLines($f.FullName)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            foreach ($t in $targets) {
                if ($lines[$i] -match ('^\s*' + [regex]::Escape($t) + '\s*=\s*\{')) {
                    $end = Get-BlockEnd $lines $i
                    if ($end -lt 0) { continue }
                    [void]$out.Add("======== [$($r.tag)] $t   ($($f.Name) L$($i+1)) ========")
                    foreach ($ln in $lines[$i..$end]) { [void]$out.Add($ln) }
                    [void]$out.Add('')
                }
            }
        }
    }
}

# 再看：哪些国策在写 add_to_variable 指向这些变量（取 5 个样本就够）
[void]$out.Add('')
[void]$out.Add('# 对照组：R56 国策里 add_to_variable 的写法样本（证明国策能往变量里加值）')
[void]$out.Add('')

$sov = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet.txt'
if (Test-Path -LiteralPath $sov) {
    $lines = [System.IO.File]::ReadAllLines($sov)
    $n = 0
    for ($i = 0; $i -lt $lines.Count -and $n -lt 12; $i++) {
        if ($lines[$i] -match 'add_to_variable\s*=\s*\{\s*SOV_(the_red_fleet|defense_industry|the_politburo)_') {
            [void]$out.Add("soviet.txt L$($i+1): $($lines[$i].Trim())")
            $n++
        }
    }
}

$dst = Join-Path $PSScriptRoot '..\docs\reference\reports\trait-accumulation-verify.txt'
[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst ($($out.Count) lines)"

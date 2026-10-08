# combat_width 是否可用于 idea / dynamic_modifier（而不是只在 combat_tactics 里）
$ErrorActionPreference = 'Stop'

$roots = @('D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125',
           'F:\Hearts of Iron IV')

$dirs = @('common\ideas', 'common\dynamic_modifiers', 'common\unit_leader',
          'common\combat_tactics', 'common\scripted_effects', 'common\national_focus')

$hits = 0
foreach ($r in $roots) {
    foreach ($sd in $dirs) {
        $d = Join-Path $r $sd
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
            $lines = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*combat_width\s*=') {
                    $hits++
                    $rel = $f.FullName.Replace($r, '').TrimStart('\')
                    Write-Output ("[combat_width] $rel : $($i+1)   " + $lines[$i].Trim())
                }
            }
        }
    }
}
Write-Output "combat_width 在六个目录里共 $hits 处"
Write-Output ''

# army_armor_attack_factor 的出处与次数
foreach ($r in $roots) {
    foreach ($sd in $dirs) {
        $d = Join-Path $r $sd
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
            $lines = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*army_armor_(attack|defence|speed)_factor\s*=') {
                    $rel = $f.FullName.Replace($r, '').TrimStart('\')
                    Write-Output ("[armor] $rel : $($i+1)   " + $lines[$i].Trim())
                }
            }
        }
    }
}

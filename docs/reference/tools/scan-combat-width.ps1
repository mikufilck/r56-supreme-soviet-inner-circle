# scan-combat-width.ps1
# ---------------------------------------------------------------------------
# `combat_width_factor` 到底是「己方部队占用的宽度」还是「战场的可用宽度」？
# 正负号哪个是好？
#
# 从四处找证据：
#   1. 官方 modifiers_documentation.md 里的条目（含所属 scope）
#   2. 游戏里实际用了它的地方（idea / focus / 决议），看主题是好是坏
#   3. 本地化里的修饰符名与说明
#   4. common/combat_tactics.txt 里的 combat_width（战术层面，不同东西）
#
# 产出（建议）：docs/reference/reports/combat-width.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

Write-Output '################################################################################'
Write-Output '# 1. 官方 modifiers_documentation.md 里所有含 combat_width 的行 + 所属 scope'
Write-Output '################################################################################'
$doc = Join-Path $HOI4 'documentation\modifiers_documentation.md'
if (Test-Path $doc) {
    $ls = [System.IO.File]::ReadAllLines($doc)
    $scope = '(未知)'
    for ($i = 0; $i -lt $ls.Count; $i++) {
        if ($ls[$i] -match '^##\s+(.+)$') { $scope = $Matches[1].Trim() }
        if ($ls[$i] -match 'combat_width') {
            Write-Output ("  L{0}  [{1}]  {2}" -f ($i + 1), $scope, $ls[$i].Trim())
        }
    }
} else { Write-Output '  （找不到 modifiers_documentation.md）' }

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 2. 游戏里实际用了 combat_width_factor 的地方（打印所属块，看主题）'
Write-Output '################################################################################'

$dirs = @('common\ideas', 'common\national_focus', 'common\decisions', 'common\dynamic_modifiers',
          'common\unit_leader', 'common\characters', 'common\operations', 'common\scripted_effects')

foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    foreach ($d in $dirs) {
        $p = Join-Path $root $d
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem $p -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object {
            $f = $_.FullName
            $ls = [System.IO.File]::ReadAllLines($f)
            for ($i = 0; $i -lt $ls.Count; $i++) {
                if ($ls[$i] -match 'combat_width_factor\s*=') {
                    # 往上找最近的块头（缩进更小的 xxx = {）
                    $hdr = ''; $hdrLine = 0
                    $own = ([regex]::Match($ls[$i], '^\t*')).Value.Length
                    for ($j = $i - 1; $j -ge 0 -and $j -gt $i - 60; $j--) {
                        $m = [regex]::Match($ls[$j], '^(\t*)([A-Za-z_0-9]+)\s*=\s*\{')
                        if ($m.Success -and $m.Groups[1].Value.Length -lt $own) {
                            $hdr = $m.Groups[2].Value; $hdrLine = $j + 1; break
                        }
                    }
                    Write-Output ("  [{0}] {1} L{2}   所属块: {3} (L{4})" -f `
                        $label, $f.Replace($root + '\', ''), ($i + 1), $hdr, $hdrLine)
                    Write-Output ("        {0}" -f $ls[$i].Trim())
                }
            }
        }
    }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 3. 本地化里 combat_width_factor 的名字 / 说明'
Write-Output '################################################################################'
foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    $p = Join-Path $root 'localisation'
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -File -Filter '*.yml' -ErrorAction SilentlyContinue | ForEach-Object {
        $f = $_.FullName
        $ls = [System.IO.File]::ReadAllLines($f)
        for ($i = 0; $i -lt $ls.Count; $i++) {
            if ($ls[$i] -match '^\s*combat_width') {
                $t = $ls[$i]
                if ($t.Length -gt 220) { $t = $t.Substring(0, 220) + '...' }
                Write-Output ("  [{0}] {1} L{2}: {3}" -f $label, (Split-Path $f -Leaf), ($i + 1), $t.Trim())
            }
        }
    }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 4. 战术里的 combat_width（不同层面的东西，对比用）'
Write-Output '################################################################################'
foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    $f = Join-Path $root 'common\combat_tactics.txt'
    if (-not (Test-Path $f)) { continue }
    $ls = [System.IO.File]::ReadAllLines($f)
    for ($i = 0; $i -lt $ls.Count; $i++) {
        if ($ls[$i] -match 'combat_width') {
            Write-Output ("  [{0}] L{1}: {2}" -f $label, ($i + 1), $ls[$i].Trim())
        }
    }
}

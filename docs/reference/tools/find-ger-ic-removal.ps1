# find-ger-ic-removal.ps1
# ---------------------------------------------------------------------------
# 德国核心圈：换人 / 移除时怎么处理职务 idea？
#   · 找所有引用职务 idea 的地方（尤其是 remove_ideas / swap_ideas）
#   · 顺便把两个"吃变量"的辅助动态修正原文导出来
#
# 产出（建议）：docs/reference/reports/ger-ic-removal.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$HOI4 = 'F:\Hearts of Iron IV'

# 德国职务 idea id（取自 ger-ic-idea-tiers.txt）
$ids = @(
    'GER_todt_reich_engineer', 'GER_todt_reich_minister_of_armaments',
    'GER_speer_reich_architect', 'GER_speer_reich_minister_of_armaments',
    'GER_goring_overseer_four_year_plan', 'GER_goring_four_year_plan_plenipotentiary',
    'GER_himmler_chief_of_german_police', 'GER_himmler_director_reich_security', 'GER_himmler_reichsfuhrer_ss',
    'GER_hess_party_chancellor', 'GER_bormann_secretary_to_the_fuhrer'
)

Write-Output '################################################################################'
Write-Output '# 1. 哪些文件引用了这些职务 idea，引用行长什么样'
Write-Output '################################################################################'

$dirs = @(
    'common\scripted_effects', 'common\scripted_triggers', 'common\national_focus',
    'events', 'common\decisions', 'common\dynamic_modifiers', 'common\ideas'
)

foreach ($root in @($R56, $HOI4)) {
    $label = 'R56'
    if ($root -eq $HOI4) { $label = '原版' }
    foreach ($d in $dirs) {
        $p = Join-Path $root $d
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem $p -Recurse -File -Filter *.txt | ForEach-Object {
            $f = $_.FullName
            $lines = [System.IO.File]::ReadAllLines($f)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                foreach ($id in $ids) {
                    if ($lines[$i] -like "*$id*") {
                        $rel = $f.Replace($root + '\', '')
                        Write-Output ("[{0}] {1} L{2}: {3}" -f $label, $rel, ($i + 1), $lines[$i].Trim())
                        break
                    }
                }
            }
        }
    }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 2. 吃变量的辅助动态修正原文（德国个人线额外数值就住在这里）'
Write-Output '################################################################################'

$want = @('GER_wunderwaffen', 'GER_military_intelligence_service', 'GER_four_year_plan_initiative_modifier')

foreach ($root in @($HOI4, $R56)) {
    $p = Join-Path $root 'common\dynamic_modifiers'
    if (-not (Test-Path $p)) { continue }
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    Get-ChildItem $p -Recurse -File -Filter *.txt | ForEach-Object {
        $f = $_.FullName
        $lines = [System.IO.File]::ReadAllLines($f)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*([A-Za-z_0-9]+)\s*=\s*\{\s*$') {
                $id = $Matches[1]
                $hit = $false
                foreach ($w in $want) { if ($id -eq $w) { $hit = $true } }
                if (-not $hit) { continue }
                Write-Output ''
                Write-Output ("--- [{0}] {1} :: {2}  L{3}" -f $label, (Split-Path $f -Leaf), $id, ($i + 1))
                $depth = 0
                for ($j = $i; $j -lt $lines.Count; $j++) {
                    Write-Output ('    ' + $lines[$j])
                    $depth += ([regex]::Matches($lines[$j], '\{')).Count - ([regex]::Matches($lines[$j], '\}')).Count
                    if ($j -gt $i -and $depth -le 0) { break }
                }
            }
        }
    }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 3. 卡片：add_to_variable / remove_ideas / swap_ideas 的官方签名'
Write-Output '################################################################################'
$effDoc = Join-Path $HOI4 'documentation\effects_documentation.md'
$tl = [System.IO.File]::ReadAllLines($effDoc)
$wantSec = @('## add_to_variable', '## remove_ideas', '## swap_ideas', '## add_ideas', '## remove_ideas_with_trait')
for ($i = 0; $i -lt $tl.Count; $i++) {
    foreach ($w in $wantSec) {
        if ($tl[$i].Trim() -eq $w) {
            Write-Output ''
            Write-Output ("--- {0} ---" -f $w)
            for ($j = $i; $j -lt $tl.Count -and $j -lt $i + 22; $j++) {
                Write-Output ('    ' + $tl[$j])
                if ($j -gt $i + 1 -and $tl[$j] -match '^## ') { break }
            }
        }
    }
}

# 从 modifier-words-2.txt 里筛出「兵种 / 将领 / 技能」相关的可用 token
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot '..\docs\reference\reports\modifier-words-2.txt'
$lines = [System.IO.File]::ReadAllLines($src)

$groups = @{
    '兵种相关' = 'infantry|cavalry|armor|artillery|mechanized|motorized|sub_unit|unit_'
    '将领 / 技能' = 'leader|skill|trait'
    '外交 / 好感' = 'opinion'
    '生产效率' = 'efficiency'
}

foreach ($g in @('兵种相关','将领 / 技能','外交 / 好感','生产效率')) {
    Write-Output ''
    Write-Output "===== $g ====="
    $re = $groups[$g]
    foreach ($l in $lines) {
        if ($l -match '^\| `([a-z0-9_]+)`') {
            $t = $Matches[1]
            if ($t -match $re) { Write-Output ("  " + $l) }
        }
    }
}

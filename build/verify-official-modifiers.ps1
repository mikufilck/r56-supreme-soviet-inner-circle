# 用游戏自带的官方文档定论：combat_width 能不能用在国家层面的民族精神上
# 官方文档 F:\Hearts of Iron IV\documentation\modifiers_documentation.md 是按 scope 分节排列的
$ErrorActionPreference = 'Stop'

$doc = 'F:\Hearts of Iron IV\documentation\modifiers_documentation.md'
if (-not (Test-Path -LiteralPath $doc)) { throw "找不到官方文档: $doc" }

$lines = [System.IO.File]::ReadAllLines($doc)

foreach ($probe in @('combat_width', 'army_armor_attack_factor', 'local_resources_factor',
                     'global_building_slots_factor', 'local_building_slots_factor',
                     'supply_consumption_factor', 'army_attack_factor',
                     'production_factory_efficiency_gain_factor')) {
    Write-Output "===== $probe ====="
    $n = 0
    $curScope = ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^#{1,4}\s+(.+)$') { $curScope = $Matches[1].Trim() }
        if ($lines[$i] -match ('^\s*\|?\s*' + [regex]::Escape($probe) + '\s*\|')) {
            $n++
            if ($n -le 4) { Write-Output ("  [scope: $curScope]  L$($i+1)  " + $lines[$i].Trim()) }
        }
    }
    if ($n -eq 0) { Write-Output "  ❌ 官方文档里没有这个词条" } else { Write-Output "  共 $n 处" }
    Write-Output ''
}

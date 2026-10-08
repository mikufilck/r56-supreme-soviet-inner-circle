# 先看官方 modifiers 文档的真实格式，再用宽松匹配重查
$ErrorActionPreference = 'Stop'
$doc = 'F:\Hearts of Iron IV\documentation\modifiers_documentation.md'
$lines = [System.IO.File]::ReadAllLines($doc)

Write-Output ("总行数: " + $lines.Count)
Write-Output '===== 前 45 行 ====='
for ($i = 0; $i -lt [Math]::Min(45, $lines.Count); $i++) { Write-Output ("{0,5}| {1}" -f ($i+1), $lines[$i]) }

Write-Output ''
Write-Output '===== 宽松搜索（只要行里含这个词就打印 + 最近的标题）====='
foreach ($probe in @('combat_width','army_armor_attack_factor','local_resources_factor',
                     'global_building_slots_factor','supply_consumption_factor')) {
    Write-Output "----- $probe -----"
    $cur = ''
    $n = 0
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^#{1,4}\s+(.+)$') { $cur = $Matches[1].Trim() }
        if ($lines[$i].Contains($probe)) {
            $n++
            if ($n -le 3) { Write-Output ("  [H: $cur] L$($i+1): " + $lines[$i].Trim()) }
        }
    }
    if ($n -eq 0) { Write-Output '  ❌ 全文无此字符串' } else { Write-Output "  共 $n 处" }
}

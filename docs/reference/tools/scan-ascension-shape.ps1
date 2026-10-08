# 扫描德国核心圈「升格国策」的形态，为我们的核心圈个人线定形。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-ascension-shape.ps1

$g = "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\germany.txt"
if (-not (Test-Path -LiteralPath $g)) { Write-Host "找不到 germany.txt"; exit 1 }

$lines = Get-Content -LiteralPath $g -Encoding UTF8
Write-Host "=== 1. GER_ascension_of_* 形态 ==="
$count = 0
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'id\s*=\s*(GER_ascension_of_\w+)') {
        $id = $Matches[1]
        $cost = "-"; $filter = "-"; $icon = "-"
        for ($j = $i; $j -lt [Math]::Min($i + 70, $lines.Count); $j++) {
            if ($lines[$j] -match '^\s*icon\s*=\s*(\S+)') { if ($icon -eq "-") { $icon = $Matches[1] } }
            if ($lines[$j] -match '^\s*cost\s*=\s*(\d+)') { $cost = $Matches[1] }
            if ($lines[$j] -match 'search_filters\s*=\s*\{(.*)\}') { $filter = $Matches[1].Trim(); break }
        }
        "{0,-40} cost={1,-3} icon={2,-40} filter={3}" -f $id, $cost, $icon, $filter
        $count++
    }
}
Write-Host "`n升格国策总数 = $count"

Write-Host "`n=== 2. 核心圈其它件（idea 名与筛选器分布）==="
$lines | Select-String -Pattern 'FOCUS_FILTER_INNER_CIRCLE' | ForEach-Object {
    if ($_.Line -match 'search_filters\s*=\s*\{(.*)\}') { $Matches[1].Trim() }
} | Group-Object | Sort-Object Count -Descending | ForEach-Object {
    "{0,3} x  {1}" -f $_.Count, $_.Name
}

Write-Host "`n=== 3. 每人是否只有 1 个升格国策（按 idea 名去重统计）==="
$ideas = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'id\s*=\s*GER_ascension_of_(\w+)') {
        for ($j = $i; $j -lt [Math]::Min($i + 70, $lines.Count); $j++) {
            if ($lines[$j] -match 'show_ideas_tooltip\s*=\s*(\S+)') { $ideas += $Matches[1]; break }
        }
    }
}
$ideas | ForEach-Object { "  idea: $_" }
Write-Host "`n升格国策 $count 个，对应 idea $(($ideas | Select-Object -Unique).Count) 个"

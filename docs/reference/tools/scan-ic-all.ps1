# 列出德国核心圈「全部」国策（不只升格国策），确认每人是否有后续个人线。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-ic-all.ps1

$g = "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\germany.txt"
if (-not (Test-Path -LiteralPath $g)) { Write-Host "找不到 germany.txt"; exit 1 }
$lines = Get-Content -LiteralPath $g -Encoding UTF8

# 按 focus = { ... } 切块（靠缩进计数，粗切即可）
$blocks = @()
$depth = 0; $start = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*focus\s*=\s*\{') { $start = $i; $depth = 0 }
    if ($start -ge 0) {
        $depth += ([regex]::Matches($lines[$i], '\{')).Count
        $depth -= ([regex]::Matches($lines[$i], '\}')).Count
        if ($depth -le 0 -and $i -gt $start) {
            $blocks += ,@($start, $i)
            $start = -1
        }
    }
}
Write-Host "germany.txt 共切出 focus 块: $($blocks.Count)"

Write-Host "`n=== 含 FOCUS_FILTER_INNER_CIRCLE 的国策（按出现顺序）==="
$n = 0
foreach ($b in $blocks) {
    $text = ($lines[$b[0]..$b[1]] -join "`n")
    if ($text -notmatch 'FOCUS_FILTER_INNER_CIRCLE') { continue }
    $n++
    $id = "-"; $cost = "-"; $filt = "-"; $idea = "-"; $prereq = "-"
    if ($text -match '(?m)^\s*id\s*=\s*(\w+)')          { $id = $Matches[1] }
    if ($text -match '(?m)^\s*cost\s*=\s*(\d+)')        { $cost = $Matches[1] }
    if ($text -match 'search_filters\s*=\s*\{(.*)\}')   { $filt = ($Matches[1].Trim() -replace 'FOCUS_FILTER_INNER_CIRCLE\s*','') }
    if ($text -match 'show_ideas_tooltip\s*=\s*(\S+)')  { $idea = $Matches[1] }
    if ($text -match 'prerequisite\s*=\s*\{\s*focus\s*=\s*(\w+)') { $prereq = $Matches[1] }
    "{0,3}. {1,-44} cost={2,-3} idea={3,-34} <- {4}" -f $n, $id, $cost, $idea, $prereq
    "         filter: {0}" -f $filt
}
Write-Host "`n合计 $n 个核心圈国策"

Write-Host "`n=== 核对：每个 idea 被几个国策引用 ==="
$map = @{}
foreach ($b in $blocks) {
    $text = ($lines[$b[0]..$b[1]] -join "`n")
    if ($text -notmatch 'FOCUS_FILTER_INNER_CIRCLE') { continue }
    if ($text -match '(?m)^\s*id\s*=\s*(\w+)') { $fid = $Matches[1] } else { continue }
    if ($text -match 'show_ideas_tooltip\s*=\s*(\S+)') {
        $k = $Matches[1]
        if (-not $map.ContainsKey($k)) { $map[$k] = @() }
        $map[$k] += $fid
    }
}
$map.GetEnumerator() | Sort-Object Name | ForEach-Object {
    "{0,-34} <- {1}" -f $_.Key, ($_.Value -join ", ")
}

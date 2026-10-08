# scan-focus-spacing.ps1
# ---------------------------------------------------------------------------
# 量原版国策树的【排布惯例】，用来对照我们个人线的间距。
#
# 做法：解析 focus_tree，解出每个国策的绝对坐标（沿 relative_position_id 链上溯），
#       然后统计两类距离：
#         a) 前置边（父 -> 子）的 (dx, dy) 分布  —— 这是"一步走多远"
#         b) 共享同一 relative_position_id 的兄弟国策之间的 |dx| 分布 —— 分支间距
#
# 产出（建议）：docs/reference/reports/focus-spacing.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$MINE = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\build\inject-sov-seats.txt'

function Parse-FocusTree([string]$path, [string]$label) {
    if (-not (Test-Path $path)) { return @() }
    $lines = [System.IO.File]::ReadAllLines($path)

    # 找 focus = { ... } 块（按大括号配平）
    $blocks = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*focus\s*=\s*\{\s*$') {
            $depth = 0
            $buf = New-Object System.Collections.Generic.List[string]
            for ($j = $i; $j -lt $lines.Count; $j++) {
                $buf.Add($lines[$j])
                $depth += ([regex]::Matches($lines[$j], '\{')).Count - ([regex]::Matches($lines[$j], '\}')).Count
                if ($j -gt $i -and $depth -le 0) { break }
            }
            $blocks += ,$buf.ToArray()
            $i = $j
        }
    }

    $foci = @{}
    foreach ($b in $blocks) {
        $txt = $b -join "`n"
        $id = $null; $rel = $null; $x = $null; $y = $null
        $prereq = New-Object System.Collections.Generic.List[string]
        if ($txt -match '(?m)^\s*id\s*=\s*([A-Za-z_0-9]+)') { $id = $Matches[1] }
        if ($txt -match '(?m)^\s*relative_position_id\s*=\s*([A-Za-z_0-9]+)') { $rel = $Matches[1] }
        if ($txt -match '(?m)^\s*x\s*=\s*(-?\d+)') { $x = [int]$Matches[1] }
        if ($txt -match '(?m)^\s*y\s*=\s*(-?\d+)') { $y = [int]$Matches[1] }
        foreach ($m in [regex]::Matches($txt, '(?m)^\s*focus\s*=\s*([A-Za-z_0-9]+)')) {
            if ($m.Groups[1].Value -ne $id) { $prereq.Add($m.Groups[1].Value) }
        }
        if ($null -ne $id -and $null -ne $x -and $null -ne $y) {
            $foci[$id] = @{ Id = $id; Rel = $rel; X = $x; Y = $y; Pre = $prereq.ToArray() }
        }
    }
    return @{ Label = $label; Foci = $foci }
}

function Abs-Coords($tree) {
    $foci = $tree.Foci
    $cache = @{}
    $resolve = {
        param($id, $depth)
        if ($depth -gt 20) { return $null }
        if ($cache.ContainsKey($id)) { return $cache[$id] }
        $f = $foci[$id]
        if ($null -eq $f) { return $null }
        $ax = $f.X; $ay = $f.Y
        if ($f.Rel -and $foci.ContainsKey($f.Rel)) {
            $p = & $resolve $f.Rel ($depth + 1)
            if ($p) { $ax += $p[0]; $ay += $p[1] }
        }
        $cache[$id] = @($ax, $ay)
        return @($ax, $ay)
    }
    $out = @{}
    foreach ($k in $foci.Keys) { $out[$k] = (& $resolve $k 0) }
    return $out
}

function Report([string]$label, $tree) {
    Write-Output ''
    Write-Output ('=' * 96)
    Write-Output ("### $label    （国策 {0} 个）" -f $tree.Foci.Count)
    Write-Output ('=' * 96)
    if ($tree.Foci.Count -eq 0) { Write-Output '  （没解析到）'; return }

    $abs = Abs-Coords $tree

    # a) 前置边 (dx, dy)
    $edge = @{}
    $n = 0
    foreach ($f in $tree.Foci.Values) {
        $c = $abs[$f.Id]
        if ($null -eq $c) { continue }
        foreach ($p in $f.Pre) {
            if (-not $abs.ContainsKey($p)) { continue }
            $pc = $abs[$p]
            if ($null -eq $pc) { continue }
            $k = ('dx={0,2} dy={1,2}' -f ($c[0] - $pc[0]), ($c[1] - $pc[1]))
            if ($edge.ContainsKey($k)) { $edge[$k] = $edge[$k] + 1 } else { $edge[$k] = 1 }
            $n++
        }
    }
    Write-Output ''
    Write-Output ("  --- a) 前置边（父->子）的 (dx, dy) 分布，共 {0} 条 ---" -f $n)
    $edge.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 14 | ForEach-Object {
        Write-Output ('      {0,-16} x{1}' -f $_.Key, $_.Value)
    }

    # b) 同一 relative_position_id 下兄弟的 |dx|
    $sib = @{}
    foreach ($f in $tree.Foci.Values) {
        if (-not $f.Rel) { continue }
        $k = $f.Rel
        if (-not $sib.ContainsKey($k)) { $sib[$k] = New-Object System.Collections.Generic.List[int] }
        $sib[$k].Add($f.X)
    }
    $gap = @{}
    foreach ($k in $sib.Keys) {
        $xs = @($sib[$k] | Sort-Object -Unique)
        if ($xs.Count -lt 2) { continue }
        for ($i = 1; $i -lt $xs.Count; $i++) {
            $g = $xs[$i] - $xs[$i - 1]
            if ($gap.ContainsKey($g)) { $gap[$g] = $gap[$g] + 1 } else { $gap[$g] = 1 }
        }
    }
    Write-Output ''
    Write-Output '  --- b) 同锚点下相邻兄弟的 |dx|（分支间距）---'
    $gap.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Output ('      {0,3} 格   x{1}' -f $_.Key, $_.Value)
    }
}

$trees = @()
$trees += ,(Parse-FocusTree (Join-Path $HOI4 'common\national_focus\soviet.txt')  '原版 soviet.txt')
$trees += ,(Parse-FocusTree (Join-Path $HOI4 'common\national_focus\germany.txt') '原版 germany.txt')
$trees += ,(Parse-FocusTree (Join-Path $R56  'common\national_focus\germany.txt') 'R56 germany.txt（含核心圈）')
$trees += ,(Parse-FocusTree $MINE '★ 我们自己的个人线（inject-sov-seats.txt）')

foreach ($t in $trees) { Report $t.Label $t }

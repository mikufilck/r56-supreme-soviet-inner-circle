# scan-ger-ic-grid.ps1
# 提取德国核心圈全部国策的 x / y / relative_position_id，换算绝对坐标，画网格图。
# 目的：搞清楚德国核心圈的**网格设计语言**（间距、分行、支线怎么摆）。
$ErrorActionPreference = 'Stop'

$file = 'F:\Hearts of Iron IV\common\national_focus\germany.txt'
if (-not (Test-Path $file)) { Write-Output ('找不到：' + $file); exit 1 }

$lines = [System.IO.File]::ReadAllLines($file)
Write-Output ('germany.txt 行数：' + $lines.Count)

# ---- 切 focus 块 ----
$blocks = New-Object System.Collections.Generic.List[string]
$i = 0
while ($i -lt $lines.Count) {
    if ($lines[$i] -match '^\s*focus\s*=\s*\{') {
        $d = 0
        $buf = New-Object System.Collections.Generic.List[string]
        $k = $i
        while ($k -lt $lines.Count) {
            $buf.Add($lines[$k])
            $d += ([regex]::Matches($lines[$k], '\{')).Count - ([regex]::Matches($lines[$k], '\}')).Count
            if ($k -gt $i -and $d -le 0) { break }
            $k++
        }
        $blocks.Add(($buf -join "`n"))
        $i = $k + 1
    } else { $i++ }
}
Write-Output ('切出 focus 块：' + $blocks.Count)

# ---- 全量坐标表（用于递归解析 relative_position_id）----
$pos = @{}
foreach ($b in $blocks) {
    $id = [regex]::Match($b, '(?m)^\s*id\s*=\s*(\S+)')
    if (-not $id.Success) { continue }
    $idv = $id.Groups[1].Value.Trim()
    $xm = [regex]::Match($b, '(?m)^\s*x\s*=\s*(-?\d+)')
    $ym = [regex]::Match($b, '(?m)^\s*y\s*=\s*(-?\d+)')
    $rm = [regex]::Match($b, '(?m)^\s*relative_position_id\s*=\s*(\S+)')
    $pos[$idv] = [pscustomobject]@{
        Id   = $idv
        X    = if ($xm.Success) { [int]$xm.Groups[1].Value } else { 0 }
        Y    = if ($ym.Success) { [int]$ym.Groups[1].Value } else { 0 }
        Rel  = if ($rm.Success) { $rm.Groups[1].Value.Trim() } else { '' }
        IsIC = ($b -match 'FOCUS_FILTER_INNER_CIRCLE')
    }
}

function Get-Abs([string]$idv, [int]$depth) {
    if ($depth -gt 10 -or -not $pos.ContainsKey($idv)) { return @(0,0) }
    $p = $pos[$idv]
    if (-not $p.Rel -or -not $pos.ContainsKey($p.Rel)) { return @($p.X, $p.Y) }
    if ($p.Rel -eq $idv) { return @($p.X, $p.Y) }
    $b = Get-Abs $p.Rel ($depth + 1)
    return @(($p.X + $b[0]), ($p.Y + $b[1]))
}

$ic = @($pos.Values | Where-Object { $_.IsIC } | Sort-Object Id)
Write-Output ''
Write-Output ('=== 含 FOCUS_FILTER_INNER_CIRCLE 的国策：{0} 个 ===' -f $ic.Count)
Write-Output ''
Write-Output ('{0,-46} {1,-34} {2,6} {3,5} {4,7} {5,5}' -f 'id', 'relative_to', 'dx', 'dy', 'absX', 'absY')
Write-Output ('-' * 112)

$rows = @()
foreach ($p in $ic) {
    $a = Get-Abs $p.Id 0
    $rows += [pscustomobject]@{ Id=$p.Id; Rel=$p.Rel; Dx=$p.X; Dy=$p.Y; Ax=$a[0]; Ay=$a[1] }
    Write-Output ('{0,-46} {1,-34} {2,6} {3,5} {4,7} {5,5}' -f $p.Id, $p.Rel, $p.X, $p.Y, $a[0], $a[1])
}

# ---- 网格图 ----
Write-Output ''
Write-Output '=== 网格图（行 = 绝对 y，列 = 绝对 x）==='
Write-Output ''
$minX = ($rows | Measure-Object Ax -Minimum).Minimum
$maxX = ($rows | Measure-Object Ax -Maximum).Maximum
$minY = ($rows | Measure-Object Ay -Minimum).Minimum
$maxY = ($rows | Measure-Object Ay -Maximum).Maximum
Write-Output ('x 范围 {0}..{1}（宽 {2}）   y 范围 {3}..{4}（高 {5}）' -f `
    $minX, $maxX, ($maxX - $minX + 1), $minY, $maxY, ($maxY - $minY + 1))
Write-Output ''

for ($yy = $minY; $yy -le $maxY; $yy++) {
    $onRow = @($rows | Where-Object { $_.Ay -eq $yy } | Sort-Object Ax)
    $line = 'y={0,3}  ' -f $yy
    foreach ($r in $onRow) {
        $short = $r.Id -replace '^GER_', ''
        if ($short.Length -gt 26) { $short = $short.Substring(0, 26) }
        $line += ('[x={0,4}] {1}   ' -f $r.Ax, $short)
    }
    Write-Output $line
}

# ---- 间距统计 ----
Write-Output ''
Write-Output '=== 同行相邻国策的 |dx| 分布 ==='
$gaps = @{}
foreach ($g in ($rows | Group-Object Ay)) {
    $xs = @($g.Group | Sort-Object Ax | ForEach-Object { $_.Ax })
    for ($n = 1; $n -lt $xs.Count; $n++) {
        $d = $xs[$n] - $xs[$n-1]
        if (-not $gaps.ContainsKey($d)) { $gaps[$d] = 0 }
        $gaps[$d]++
    }
}
foreach ($k in ($gaps.Keys | Sort-Object)) { Write-Output ('  dx = {0,3}  : {1} 次' -f $k, $gaps[$k]) }

Write-Output ''
Write-Output '=== 纵向：每个国策到其 prerequisite[0] 的 (dx, dy) ==='
Write-Output '(需要另一份提 prerequisite 的扫描，此处仅给同族纵向间隔)'
$byCol = $rows | Group-Object Ax | Where-Object { $_.Count -gt 1 }
foreach ($c in $byCol) {
    $ys = @($c.Group | Sort-Object Ay | ForEach-Object { $_.Ay })
    $ds = @()
    for ($n = 1; $n -lt $ys.Count; $n++) { $ds += ($ys[$n] - $ys[$n-1]) }
    Write-Output ('  x={0,4} : y 序列 {1}  间隔 {2}' -f $c.Name, ($ys -join ','), ($ds -join ','))
}

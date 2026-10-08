# scan-mutual-tree-bbox.ps1
# ---------------------------------------------------------------------------
# 目的：为「互助会联合国策」（需求 C / S5）选址。
#
#   互助会通用线是 joint_focus —— 同一批焦点会出现在【每一个参与国的树里】，
#   位置由 joint_focus 自己的 x / y 决定（各国可用 offset = { x y trigger } 错开）。
#   ⇒ 想知道该把 y 放到多少才不压到任何一棵树，就必须先量出【16 棵挂载树】的绝对包围盒。
#
#   本脚本对 build/attach-points.json 里的每个挂载点：
#     ① 读本 mod 里那份副本（游戏实际加载的那份）
#     ② 抽取该 focus_tree 内的 focus 节点 id / x / y / relative_position_id
#     ③ 沿 relative_position_id 链累加出绝对坐标（含缓存 + 环检测）
#     ④ 输出每棵树的 X/Y 包围盒，并给出全局 maxY（= 放共享国策的安全下沿）
#
# 用法：powershell -NoProfile -File scan-mutual-tree-bbox.ps1
# 输出：docs/reference/reports/mutual-tree-bbox-report.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$Root    = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron'
$ModRoot = Join-Path $Root 'mod\heart_of_iron'
$ListPath = Join-Path $Root 'build\attach-points.json'
$OutPath  = Join-Path $Root 'docs\reference\reports\mutual-tree-bbox-report.txt'

if (-not (Test-Path $ListPath)) { throw "找不到挂载点清单：$ListPath" }

# ⚠️ 必须带 -Encoding UTF8，否则 PowerShell 5.1 按 ANSI(GBK) 解码，中文注释乱码
$points = (Get-Content -LiteralPath $ListPath -Raw -Encoding UTF8 | ConvertFrom-Json).points

function Get-TreeNodes {
    param([string]$Text, [string]$TreeId)

    # 只截取目标 focus_tree 那一块。
    #
    # ⚠️ 这里【不能】靠花括号配平来切块 —— 实测 poland.txt（440 KB，5 棵 focus_tree）
    #    全文花括号就是配不平的（字符串/注释里也有 { }），配平法会一路扫到 EOF 然后失败。
    #    ⇒ 改用「按 focus_tree = { 的出现位置切段」：目标块 = 从它前面最近的
    #      `focus_tree` 到下一个 `focus_tree`（或 EOF）。对本用途（量一棵树的包围盒）足够且稳。
    $anchor = [regex]::Match($Text, '(?m)^[ \t]*id[ \t]*=[ \t]*' + [regex]::Escape($TreeId) + '[ \t]*\r?$')
    if (-not $anchor.Success) { return $null }

    $marks = @()
    foreach ($mm in [regex]::Matches($Text, '(?m)^[ \t]*focus_tree[ \t]*=')) { $marks += $mm.Index }
    if ($marks.Count -eq 0) { return $null }

    $start = 0; $end = $Text.Length - 1
    for ($k = 0; $k -lt $marks.Count; $k++) {
        if ($marks[$k] -le $anchor.Index) {
            $start = $marks[$k]
            if ($k + 1 -lt $marks.Count) { $end = $marks[$k + 1] - 1 } else { $end = $Text.Length - 1 }
        }
    }
    $body = $Text.Substring($start, $end - $start + 1)

    $nodes = @{}
    foreach ($m in [regex]::Matches($body, '(?ms)^[ \t]*focus\s*=\s*\{(.*?)^[ \t]*\}')) {
        $inner = $m.Groups[1].Value
        $id = ([regex]::Match($inner, '(?m)^\s*id\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
        if (-not $id) { continue }
        $x   = ([regex]::Match($inner, '(?m)^\s*x\s*=\s*(-?\d+)')).Groups[1].Value
        $y   = ([regex]::Match($inner, '(?m)^\s*y\s*=\s*(-?\d+)')).Groups[1].Value
        $rel = ([regex]::Match($inner, '(?m)^\s*relative_position_id\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
        $nodes[$id] = @{
            X   = if ($x) { [int]$x } else { 0 }
            Y   = if ($y) { [int]$y } else { 0 }
            Rel = $rel
            Abs = $null
        }
    }
    return $nodes
}

function Get-Abs {
    param($Nodes, [string]$Id, [System.Collections.Generic.HashSet[string]]$Visiting)
    $n = $Nodes[$Id]
    if ($null -ne $n.Abs) { return $n.Abs }
    if ($Visiting.Contains($Id)) {
        $n.Abs = @{ X = $n.X; Y = $n.Y; Cycle = $true }
        return $n.Abs
    }
    [void]$Visiting.Add($Id)
    if ($n.Rel -and $Nodes.ContainsKey($n.Rel)) {
        $p = Get-Abs $Nodes $n.Rel $Visiting
        $n.Abs = @{ X = $n.X + $p.X; Y = $n.Y + $p.Y; Cycle = $false }
    } else {
        $n.Abs = @{ X = $n.X; Y = $n.Y; Cycle = $false }
    }
    [void]$Visiting.Remove($Id)
    return $n.Abs
}

$lines = New-Object System.Collections.Generic.List[string]
function W([string]$s) { $lines.Add($s) }

W '============================================================================='
W ' 互助会联合国策（需求 C）选址勘查 —— 16 棵挂载树的绝对坐标包围盒'
W ' 生成者：docs/reference/tools/scan-mutual-tree-bbox.ps1'
W ' 数据源：build/attach-points.json + mod/heart_of_iron/common/national_focus/*.txt'
W '============================================================================='
W ''

$rows = @()
$globalMaxY = [int]::MinValue

foreach ($p in $points) {
    $file = Join-Path $ModRoot ($p.srcRelativePath -replace '/', '\')
    if (-not (Test-Path $file)) {
        W ("  !! {0,-14} {1,-4} 缺少副本：{2}" -f $p.id, $p.tag, $p.srcRelativePath)
        continue
    }
    $text = [System.IO.File]::ReadAllText($file)
    $nodes = Get-TreeNodes -Text $text -TreeId $p.treeId
    if ($null -eq $nodes -or $nodes.Count -eq 0) {
        W ("  !! {0,-14} {1,-4} 在 {2} 里找不到 focus_tree id = {3}" -f $p.id, $p.tag, $p.srcRelativePath, $p.treeId)
        continue
    }

    $minX = [int]::MaxValue; $maxX = [int]::MinValue
    $minY = [int]::MaxValue; $maxY = [int]::MinValue
    $cycles = 0
    foreach ($id in @($nodes.Keys)) {
        $a = Get-Abs $nodes $id (New-Object 'System.Collections.Generic.HashSet[string]')
        if ($a.Cycle) { $cycles++ }
        if ($a.X -lt $minX) { $minX = $a.X }
        if ($a.X -gt $maxX) { $maxX = $a.X }
        if ($a.Y -lt $minY) { $minY = $a.Y }
        if ($a.Y -gt $maxY) { $maxY = $a.Y }
    }
    if ($maxY -gt $globalMaxY) { $globalMaxY = $maxY }

    $rows += [pscustomobject]@{
        Id = $p.id; Tag = $p.tag; Tree = $p.treeId; File = $p.srcRelativePath
        N = $nodes.Count; MinX = $minX; MaxX = $maxX; MinY = $minY; MaxY = $maxY; Cycles = $cycles
    }
    W ("OK {0}" -f $p.id)
}

W ''
W '=== 1. 每棵挂载树的包围盒（单位：国策网格）==='
W ''
W ("  {0,-14} {1,-5} {2,-30} {3,6}  {4,7} {5,7}  {6,7} {7,7}  {8}" -f '挂载点', 'TAG', '树 id', '节点数', 'X 最小', 'X 最大', 'Y 最小', 'Y 最大', '环')
W ('  ' + ('-' * 122))
foreach ($r in ($rows | Sort-Object -Property MaxY -Descending)) {
    W ("  {0,-14} {1,-5} {2,-30} {3,6}  {4,7} {5,7}  {6,7} {7,7}  {8}" -f $r.Id, $r.Tag, $r.Tree, $r.N, $r.MinX, $r.MaxX, $r.MinY, $r.MaxY, $r.Cycles)
}

W ''
W '=== 2. 结论：两种摆法的安全边界 ==='
W ''
W ("  共 {0} 棵树；Y 的最大值 = {1}（来源：{2}）" -f $rows.Count, $globalMaxY, (($rows | Sort-Object -Property MaxY -Descending | Select-Object -First 1).Tag))
W ("  ⇒ 【摆在树下方】的基准 y 取 {0}（= maxY + 2）即可不与任何一棵树重叠" -f ($globalMaxY + 2))
W ("  ⇒ 【摆在树右侧】（2026-09-20 用户口径，S5 经互会通用线采用）：头部 x = 该树 X 最大 + 4，" -f '')
W ("     子节点相对 x 取 0..+2 ⇒ 整条带子落在 [maxX+2, maxX+6]，永远在树右侧、永不重叠；" -f '')
W ("     基准（无 offset 命中时的落点）取 ( x = 0 , y = {0} ) —— 比 Y 最大值还低 2 格，压不到任何一棵树。" -f ($globalMaxY + 2))
W ''
W '=== 3. X 宽度参考（最宽的树有多宽）==='
W ''
$w = ($rows | ForEach-Object { $_.MaxX - $_.MinX + 1 } | Measure-Object -Maximum).Maximum
W ("  最宽的树：{0} 格（X {1} .. {2}）" -f $w,
    (($rows | Sort-Object -Property @{Expression={$_.MaxX - $_.MinX}} -Descending | Select-Object -First 1).MinX),
    (($rows | Sort-Object -Property @{Expression={$_.MaxX - $_.MinX}} -Descending | Select-Object -First 1).MaxX))
W ("  X 的全局范围：{0} .. {1}" -f (($rows | Measure-Object -Property MinX -Minimum).Minimum), (($rows | Measure-Object -Property MaxX -Maximum).Maximum))
W ''

[System.IO.File]::WriteAllLines($OutPath, $lines, (New-Object System.Text.UTF8Encoding($false)))

# 控制台也打一份摘要
$lines | ForEach-Object { Write-Output $_ }

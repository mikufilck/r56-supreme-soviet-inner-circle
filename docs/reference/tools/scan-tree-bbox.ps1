# scan-tree-bbox.ps1
# ---------------------------------------------------------------------------
# 目的：
#   A. 解析苏联国策树的「绝对坐标包围盒」——因为树里几乎全部用 relative_position_id，
#      必须沿依赖链把相对坐标累加出来，才能知道树占了多大地方、窗口该放哪。
#   B. 读候选中性素材的 DDS 头部，取得真实像素尺寸（.gfx 里不写尺寸）。
# 用法：powershell -NoProfile -File scan-tree-bbox.ps1
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

# ============================ A. 国策树包围盒 ============================

$treeFile = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\national_focus\soviet.txt'
$text = [System.IO.File]::ReadAllText($treeFile)

# 逐个提取 focus 块的 id / x / y / relative_position_id
$nodes = @{}
foreach ($m in [regex]::Matches($text, '(?ms)^\t*focus\s*=\s*\{(.*?)^\t*\}')) {
    $body = $m.Groups[1].Value
    $id = ([regex]::Match($body, '(?m)^\s*id\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
    if (-not $id) { continue }
    $x  = ([regex]::Match($body, '(?m)^\s*x\s*=\s*(-?\d+)')).Groups[1].Value
    $y  = ([regex]::Match($body, '(?m)^\s*y\s*=\s*(-?\d+)')).Groups[1].Value
    $rel = ([regex]::Match($body, '(?m)^\s*relative_position_id\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
    $nodes[$id] = @{
        X   = if ($x) { [int]$x } else { 0 }
        Y   = if ($y) { [int]$y } else { 0 }
        Rel = $rel
        Abs = $null
    }
}

Write-Output ("解析到 focus 节点: {0} 个" -f $nodes.Count)

# 沿 relative_position_id 链累加求绝对坐标（带缓存与环检测）
function Get-Abs([string]$id, [System.Collections.Generic.HashSet[string]]$visiting) {
    $n = $nodes[$id]
    if ($null -ne $n.Abs) { return $n.Abs }
    if ($visiting.Contains($id)) {
        # 环：直接按自身数值处理，避免死循环
        $n.Abs = @{ X = $n.X; Y = $n.Y; Cycle = $true }
        return $n.Abs
    }
    [void]$visiting.Add($id)
    if ($n.Rel -and $nodes.ContainsKey($n.Rel)) {
        $p = Get-Abs $n.Rel $visiting
        $n.Abs = @{ X = $n.X + $p.X; Y = $n.Y + $p.Y; Cycle = $false }
    } else {
        $n.Abs = @{ X = $n.X; Y = $n.Y; Cycle = $false }
    }
    [void]$visiting.Remove($id)
    return $n.Abs
}

$minX = [int]::MaxValue; $maxX = [int]::MinValue
$minY = [int]::MaxValue; $maxY = [int]::MinValue
$cycles = 0
foreach ($id in $nodes.Keys) {
    $a = Get-Abs $id (New-Object 'System.Collections.Generic.HashSet[string]')
    if ($a.Cycle) { $cycles++ }
    if ($a.X -lt $minX) { $minX = $a.X }
    if ($a.X -gt $maxX) { $maxX = $a.X }
    if ($a.Y -lt $minY) { $minY = $a.Y }
    if ($a.Y -gt $maxY) { $maxY = $a.Y }
}

Write-Output ""
Write-Output "=== 苏联国策树绝对坐标包围盒（单位：国策网格）==="
Write-Output ("  X: {0} .. {1}   （宽 {2} 格）" -f $minX, $maxX, ($maxX - $minX + 1))
Write-Output ("  Y: {0} .. {1}   （高 {2} 格）" -f $minY, $maxY, ($maxY - $minY + 1))
Write-Output ("  存在循环引用: {0} 个" -f $cycles)

Write-Output ""
Write-Output "=== 关键国策的绝对坐标 ==="
foreach ($k in @('SOV_the_peoples_revolution', 'SOV_the_supreme_soviet')) {
    if ($nodes.ContainsKey($k)) {
        $a = Get-Abs $k (New-Object 'System.Collections.Generic.HashSet[string]')
        Write-Output ("  {0,-34} 绝对 ({1}, {2})" -f $k, $a.X, $a.Y)
    }
}

# 各 X 区间的国策密度，用于找空白列
Write-Output ""
Write-Output "=== X 方向分布（每 20 格一档，找空白区）==="
$buckets = @{}
foreach ($id in $nodes.Keys) {
    $a = Get-Abs $id (New-Object 'System.Collections.Generic.HashSet[string]')
    $b = [math]::Floor($a.X / 20) * 20
    if (-not $buckets.ContainsKey($b)) { $buckets[$b] = 0 }
    $buckets[$b]++
}
foreach ($b in ($buckets.Keys | Sort-Object)) {
    Write-Output ("  X {0,5} .. {1,5}   {2,4} 个" -f $b, ($b + 19), $buckets[$b])
}

# ============================ B. 中性素材尺寸 ============================

Write-Output ""
Write-Output "=== 候选中性 sprite 的 DDS 实际尺寸 ==="

$want = @(
    'GFX_tiled_plain_bg', 'GFX_tiled_plain_bg2', 'GFX_tiled_window_thin_border',
    'GFX_tiled_paper_bg', 'GFX_tiled_header',
    'GFX_generic_box', 'GFX_generic_box_small', 'GFX_generic_box_96', 'GFX_generic_box_125',
    'GFX_generic_circle_background', 'GFX_generic_bg',
    'GFX_empty_paper', 'GFX_empty_green_frame',
    'GFX_trait_box_fuhrer', 'GFX_blank_leader_portrait'
)

# 收集 名称 -> texturefile
$map = @{}
foreach ($root in @('F:\Hearts of Iron IV', 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125')) {
    foreach ($f in Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
        $lines = [System.IO.File]::ReadAllLines($f.FullName)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'name\s*=\s*"([A-Za-z0-9_]+)"') {
                $nm = $Matches[1]
                if ($want -contains $nm -and -not $map.ContainsKey($nm)) {
                    for ($j = $i; $j -lt [Math]::Min($i + 4, $lines.Count); $j++) {
                        if ($lines[$j] -match 'texturefile\s*=\s*"([^"]+)"') {
                            $map[$nm] = $Matches[1]
                            break
                        }
                    }
                }
            }
        }
    }
}

function Get-DdsSize([string]$texRel) {
    foreach ($root in @('F:\Hearts of Iron IV', 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125')) {
        $p = Join-Path $root ($texRel -replace '/', '\')
        if (Test-Path $p) {
            $b = New-Object byte[] 20
            $fs = [System.IO.File]::OpenRead($p)
            [void]$fs.Read($b, 0, 20)
            $fs.Close()
            if ($b[0] -eq 0x44 -and $b[1] -eq 0x44 -and $b[2] -eq 0x53) {  # "DDS"
                $h = [BitConverter]::ToInt32($b, 12)
                $w = [BitConverter]::ToInt32($b, 16)
                return "$w x $h"
            }
            return "（非 DDS）"
        }
    }
    return "（找不到纹理）"
}

foreach ($n in $want) {
    if ($map.ContainsKey($n)) {
        Write-Output ("  {0,-34} {1,9}   {2}" -f $n, (Get-DdsSize $map[$n]), $map[$n])
    } else {
        Write-Output ("  {0,-34} （未找到定义）" -f $n)
    }
}

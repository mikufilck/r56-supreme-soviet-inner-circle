# calibrate-v2.ps1
# ---------------------------------------------------------------------------
# 假设：国策网格 1 格 = 100 像素。
# 验证方法：把每棵树的「Y 最大值」与它的 continuous_focus_position.y 对比。
#   若 树高(格) * 100 ≈ continuous_focus_position.y，则倍率成立。
# 同时对比 inlay_window 位置，看窗口是否落在树的右下角外。
# 用法：powershell -NoProfile -File calibrate-v2.ps1
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$OurMod = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'

function Analyze-Tree([string]$path) {
    $text = [System.IO.File]::ReadAllText($path)

    $nodes = @{}
    foreach ($m in [regex]::Matches($text, '(?ms)^\t*focus\s*=\s*\{(.*?)^\t*\}')) {
        $body = $m.Groups[1].Value
        $id = ([regex]::Match($body, '(?m)^\s*id\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
        if (-not $id) { continue }
        $x = ([regex]::Match($body, '(?m)^\s*x\s*=\s*(-?\d+)')).Groups[1].Value
        $y = ([regex]::Match($body, '(?m)^\s*y\s*=\s*(-?\d+)')).Groups[1].Value
        $rel = ([regex]::Match($body, '(?m)^\s*relative_position_id\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
        $nodes[$id] = @{ X = if ($x) { [int]$x } else { 0 }; Y = if ($y) { [int]$y } else { 0 }; Rel = $rel; Abs = $null }
    }

    for ($pass = 0; $pass -lt 80; $pass++) {
        $changed = $false
        foreach ($id in @($nodes.Keys)) {
            $n = $nodes[$id]
            if ($null -ne $n.Abs) { continue }
            if (-not $n.Rel) { $n.Abs = @{ X = $n.X; Y = $n.Y }; $changed = $true }
            elseif ($nodes.ContainsKey($n.Rel) -and $null -ne $nodes[$n.Rel].Abs) {
                $p = $nodes[$n.Rel].Abs
                $n.Abs = @{ X = $n.X + $p.X; Y = $n.Y + $p.Y }; $changed = $true
            }
        }
        if (-not $changed) { break }
    }

    $maxX = [int]::MinValue; $maxY = [int]::MinValue
    foreach ($id in $nodes.Keys) {
        $a = $nodes[$id].Abs
        if ($null -eq $a) { continue }
        if ($a.X -gt $maxX) { $maxX = $a.X }
        if ($a.Y -gt $maxY) { $maxY = $a.Y }
    }

    $cfp = [regex]::Match($text, 'continuous_focus_position\s*=\s*\{\s*x\s*=\s*(-?\d+)\s*y\s*=\s*(-?\d+)')
    $cfx = if ($cfp.Success) { [int]$cfp.Groups[1].Value } else { $null }
    $cfy = if ($cfp.Success) { [int]$cfp.Groups[2].Value } else { $null }

    $iw = [regex]::Match($text, 'inlay_window\s*=\s*\{[^}]*?position\s*=\s*\{\s*[xX]\s*=\s*(-?\d+)\s*y\s*=\s*(-?\d+)')
    $iwx = if ($iw.Success) { [int]$iw.Groups[1].Value } else { $null }
    $iwy = if ($iw.Success) { [int]$iw.Groups[2].Value } else { $null }

    return @{ MaxX = $maxX; MaxY = $maxY; CfX = $cfx; CfY = $cfy; IwX = $iwx; IwY = $iwy; N = $nodes.Count }
}

$cases = @(
    @{ Name = '德国';   Path = (Join-Path $R56 'common\national_focus\germany.txt') },
    @{ Name = '日本';   Path = (Join-Path $R56 'common\national_focus\japan.txt') },
    @{ Name = '暹罗';   Path = (Join-Path $R56 'common\national_focus\siam.txt') },
    @{ Name = '澳洲';   Path = (Join-Path $R56 'common\national_focus\australia_taog.txt') },
    @{ Name = '苏联(我们)'; Path = (Join-Path $OurMod 'common\national_focus\soviet.txt') }
)

Write-Output ("{0,-12} {1,5} {2,5} {3,7} {4,7} {5,7} {6,7}   {7}" -f '树', 'Xmax', 'Ymax', 'CFP.x', 'CFP.y', 'inlay.x', 'inlay.y', '推断（假设 1 格 = 100px）')
Write-Output ('-' * 118)

foreach ($c in $cases) {
    if (-not (Test-Path $c.Path)) { Write-Output ("{0,-12} 文件不存在" -f $c.Name); continue }
    $r = Analyze-Tree $c.Path

    $infer = ''
    if ($null -ne $r.CfY) {
        $perCell = [math]::Round($r.CfY / [math]::Max(1, $r.MaxY), 1)
        $infer = ("CFP.y/Ymax = {0} px/格" -f $perCell)
    }
    if ($null -ne $r.IwX -and $null -ne $r.IwY) {
        $ix = if ($r.MaxX -ne 0) { [math]::Round($r.IwX / [math]::Max(1, $r.MaxX), 1) } else { 0 }
        $iy = if ($r.MaxY -ne 0) { [math]::Round($r.IwY / [math]::Max(1, $r.MaxY), 1) } else { 0 }
        $infer += ("  |  窗口 Xmax倍率 {0} / Ymax倍率 {1}" -f $ix, $iy)
    }
    Write-Output ("{0,-12} {1,5} {2,5} {3,7} {4,7} {5,7} {6,7}   {7}" -f $c.Name, $r.MaxX, $r.MaxY,
        $(if ($null -ne $r.CfX) { $r.CfX } else { '-' }),
        $(if ($null -ne $r.CfY) { $r.CfY } else { '-' }),
        $(if ($null -ne $r.IwX) { $r.IwX } else { '-' }),
        $(if ($null -ne $r.IwY) { $r.IwY } else { '-' }), $infer)
}

# calibrate-inlay-scale.ps1
# ---------------------------------------------------------------------------
# 目的：标定「国策网格坐标」与「inlay_window position」的换算比例。
#       方法：算德国的树包围盒，与其已知可用的 inlay 位置 (4500, 1150) 对比。
# 用法：powershell -NoProfile -File calibrate-inlay-scale.ps1
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

function Get-TreeBox([string]$path) {
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

    # 迭代式求解：反复松弛直到稳定（比递归更耐环）
    for ($pass = 0; $pass -lt 60; $pass++) {
        $changed = $false
        foreach ($id in @($nodes.Keys)) {
            $n = $nodes[$id]
            if ($null -ne $n.Abs) { continue }
            if (-not $n.Rel) {
                $n.Abs = @{ X = $n.X; Y = $n.Y }
                $changed = $true
            } elseif ($nodes.ContainsKey($n.Rel) -and $null -ne $nodes[$n.Rel].Abs) {
                $p = $nodes[$n.Rel].Abs
                $n.Abs = @{ X = $n.X + $p.X; Y = $n.Y + $p.Y }
                $changed = $true
            }
        }
        if (-not $changed) { break }
    }

    $minX = [int]::MaxValue; $maxX = [int]::MinValue
    $minY = [int]::MaxValue; $maxY = [int]::MinValue
    $unresolved = 0
    foreach ($id in $nodes.Keys) {
        $a = $nodes[$id].Abs
        if ($null -eq $a) { $unresolved++; continue }
        if ($a.X -lt $minX) { $minX = $a.X }
        if ($a.X -gt $maxX) { $maxX = $a.X }
        if ($a.Y -lt $minY) { $minY = $a.Y }
        if ($a.Y -gt $maxY) { $maxY = $a.Y }
    }
    return @{ Count = $nodes.Count; MinX = $minX; MaxX = $maxX; MinY = $minY; MaxY = $maxY; Unresolved = $unresolved }
}

$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$OurMod = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'

$cases = @(
    @{ Name = '德国（标定用）'; Path = (Join-Path $R56 'common\national_focus\germany.txt');       InlayX = 4500;  InlayY = 1150 },
    @{ Name = '日本';           Path = (Join-Path $R56 'common\national_focus\japan.txt');         InlayX = 10000; InlayY = 700  },
    @{ Name = '暹罗';           Path = (Join-Path $R56 'common\national_focus\siam.txt');          InlayX = 2200;  InlayY = 300  },
    @{ Name = '澳洲';           Path = (Join-Path $R56 'common\national_focus\australia_taog.txt'); InlayX = 4705;  InlayY = 510  },
    @{ Name = '苏联';           Path = (Join-Path $OurMod 'common\national_focus\soviet.txt');     InlayX = $null; InlayY = $null }
)

Write-Output ("{0,-16} {1,8} {2,8} {3,8} {4,8} {5,6}  {6}" -f '国家', 'X min', 'X max', 'Y min', 'Y max', '未解', 'inlay 位置 / 比例')
Write-Output ('-' * 104)

foreach ($c in $cases) {
    if (-not (Test-Path $c.Path)) { Write-Output ("{0,-16} 文件不存在" -f $c.Name); continue }
    $b = Get-TreeBox $c.Path
    $info = ''
    if ($null -ne $c.InlayX) {
        # 以 X 方向反推「每格多少像素」
        $px = [math]::Round($c.InlayX / [math]::Max(1, $b.MaxX), 1)
        $py = [math]::Round($c.InlayY / [math]::Max(1, $b.MaxY), 1)
        $info = ("inlay=({0},{1})  X倍率≈{2}  Y倍率≈{3}" -f $c.InlayX, $c.InlayY, $px, $py)
    }
    Write-Output ("{0,-16} {1,8} {2,8} {3,8} {4,8} {5,6}  {6}" -f $c.Name, $b.MinX, $b.MaxX, $b.MinY, $b.MaxY, $b.Unresolved, $info)
}

Write-Output ""
Write-Output "=== 若倍率约为 96~100（每格像素），则可据此为苏联窗口选址 ==="

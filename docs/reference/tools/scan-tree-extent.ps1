# scan-tree-extent.ps1
# 目的：① 算出苏联国策树的坐标范围，为 inlay window 选址
#       ② 找出 R56 自身对 inlay_window 的用法做参照
# 用法：powershell -NoProfile -File scan-tree-extent.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$OurSov = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\national_focus\soviet.txt'

Write-Output "=== 1. 苏联国策树坐标范围（含负值）==="
if (Test-Path $OurSov) {
    $t = [System.IO.File]::ReadAllText($OurSov)

    $xs = @()
    foreach ($m in [regex]::Matches($t, '(?m)^\s*x\s*=\s*(-?\d+)\s*$')) { $xs += [int]$m.Groups[1].Value }
    $ys = @()
    foreach ($m in [regex]::Matches($t, '(?m)^\s*y\s*=\s*(-?\d+)\s*$')) { $ys += [int]$m.Groups[1].Value }

    if ($xs.Count -gt 0) {
        $sx = $xs | Sort-Object
        $sy = $ys | Sort-Object
        Write-Output ("  x: 最小 {0} / 最大 {1} / 中位 {2}   (样本 {3})" -f $sx[0], $sx[-1], $sx[[int]($sx.Count/2)], $sx.Count)
        Write-Output ("  y: 最小 {0} / 最大 {1} / 中位 {2}   (样本 {3})" -f $sy[0], $sy[-1], $sy[[int]($sy.Count/2)], $sy.Count)
    } else {
        Write-Output "  未匹配到坐标（正则或文件格式不符）"
    }
} else {
    Write-Output "  找不到 $OurSov"
}

Write-Output ""
Write-Output "=== 2. R56 自身所有 inlay_window 声明（含 position）==="
$files = Get-ChildItem (Join-Path $R56 'common') -Recurse -Include *.txt -File -ErrorAction SilentlyContinue
foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*inlay_window\s*=\s*\{') {
            Write-Output ("  --- {0} L{1} ---" -f $f.Name, ($i + 1))
            for ($j = $i; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                Write-Output ("      " + $lines[$j].Trim())
                if ($lines[$j] -match '^\s*\}\s*$' -and $j -gt $i) { break }
            }
        }
    }
}

Write-Output ""
Write-Output "=== 3. 原版 inlay_window 声明（对照 R56 是否改过位置）==="
$vfiles = Get-ChildItem 'F:\Hearts of Iron IV\common' -Recurse -Include *.txt -File -ErrorAction SilentlyContinue
foreach ($f in $vfiles) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*inlay_window\s*=\s*\{') {
            $blk = @()
            for ($j = $i; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                $blk += $lines[$j].Trim()
                if ($lines[$j] -match '^\s*\}\s*$' -and $j -gt $i) { break }
            }
            Write-Output ("  {0,-34} {1}" -f $f.Name, ($blk -join ' '))
        }
    }
}

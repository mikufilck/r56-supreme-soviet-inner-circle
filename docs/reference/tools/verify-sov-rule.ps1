# verify-sov-rule.ps1
# 目的：判定 SOV 的「老国策树」选项是否真的可达。
#       若可达，我们的核心圈必须同时挂到 soviet_old.txt，成本 +2 万行。
# 用法：powershell -NoProfile -File verify-sov-rule.ps1

$ErrorActionPreference = 'Stop'
$root = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

Write-Output "=== 1. 全 mod 搜索 'SOV_focus_tree_selection'（引用处会暴露是否可达） ==="
Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern 'SOV_focus_tree_selection' -List -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Output ("  " + $_.Path.Replace($root + '\', '')) }

Write-Output ""
Write-Output "=== 2. 全 mod 搜索 'soviet_focus_old'（树名被谁引用） ==="
Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern 'soviet_focus_old' -List -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Output ("  " + $_.Path.Replace($root + '\', '')) }

Write-Output ""
Write-Output "=== 3. 全 mod 搜索 'sov_old_focus_tree'（MTTH 里的开关 flag） ==="
Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue |
    Select-String -Pattern 'sov_old_focus_tree' -List -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Output ("  " + $_.Path.Replace($root + '\', '')) }

Write-Output ""
Write-Output "=== 4. 三个 SOV 树文件规模 ==="
foreach ($f in @('soviet.txt', 'soviet_old.txt', 'r56_soviet_civil_war.txt')) {
    $p = Join-Path $root ('common\national_focus\' + $f)
    if (Test-Path $p) {
        $n = ([System.IO.File]::ReadAllLines($p)).Count
        Write-Output ("  {0,-28} {1,7} 行" -f $f, $n)
    } else {
        Write-Output ("  {0,-28} 缺失" -f $f)
    }
}

Write-Output ""
Write-Output "=== 5. on_actions 目录全部文件（找是否存在其它树选用文件） ==="
Get-ChildItem (Join-Path $root 'common\on_actions') -File -ErrorAction SilentlyContinue |
    ForEach-Object { Write-Output ("  " + $_.Name) }

# verify-sov-old-tree.ps1
# 目的：判定旧苏联树下核心圈入口国策是否存在。
#       若不存在 → 旧树无需挂载，省 13,942 行。
# 用法：powershell -NoProfile -File verify-sov-old-tree.ps1

$ErrorActionPreference = 'Stop'
$root = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

Write-Output "=== 1. 核心圈入口国策在两个 SOV 树文件里的存在情况 ==="
foreach ($f in @('soviet.txt', 'soviet_old.txt', 'r56_soviet_civil_war.txt')) {
    $p = Join-Path $root ('common\national_focus\' + $f)
    if (-not (Test-Path $p)) { Write-Output ("  {0,-28} 缺失" -f $f); continue }

    $hits = @()
    foreach ($needle in @('SOV_the_supreme_soviet', 'SOV_supreme_soviet')) {
        $n = (Select-String -Path $p -Pattern $needle -SimpleMatch -ErrorAction SilentlyContinue).Count
        $hits += ("{0}={1}" -f $needle, $n)
    }
    Write-Output ("  {0,-28} {1}" -f $f, ($hits -join '  '))
}

Write-Output ""
Write-Output "=== 2. 两个树文件里 focus 总数 ==="
foreach ($f in @('soviet.txt', 'soviet_old.txt')) {
    $p = Join-Path $root ('common\national_focus\' + $f)
    if (-not (Test-Path $p)) { continue }
    $n = (Select-String -Path $p -Pattern '^\s*focus\s*=\s*\{' -ErrorAction SilentlyContinue).Count
    Write-Output ("  {0,-28} focus 块 {1}" -f $f, $n)
}

Write-Output ""
Write-Output "=== 3. old_sov on_actions 全文（体积小，直接看机制） ==="
$p = Join-Path $root 'common\on_actions\oldsov_on_actions.txt'
if (Test-Path $p) {
    $lines = [System.IO.File]::ReadAllLines($p)
    Write-Output ("  文件行数: " + $lines.Count)
    $i = 0
    foreach ($l in $lines) {
        $i++
        Write-Output ("  {0,5}: {1}" -f $i, $l.TrimEnd())
    }
} else {
    Write-Output "  缺失"
}

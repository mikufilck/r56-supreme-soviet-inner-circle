# verify-has-start-date.ps1
# 目的：判定 `has_start_date > 1945.01.01` 这种写法是否合法。
#       若非法，该行求值为假，会让 old sov 分支默认执行 —— 直接决定需求 A 的成败。
# 用法：powershell -NoProfile -File verify-has-start-date.ps1

$ErrorActionPreference = 'Stop'
$r56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$van = 'F:\Hearts of Iron IV'

Write-Output "=== 1. 原版 + R56 里 has_start_date 的出现次数与写法 ==="
foreach ($root in @($van, $r56)) {
    Write-Output ""
    Write-Output ("--- " + $root + " ---")
    $files = Get-ChildItem $root -Recurse -Include *.txt -File -ErrorAction SilentlyContinue
    $all = $files | Select-String -Pattern 'has_start_date' -ErrorAction SilentlyContinue
    Write-Output ("  总命中: " + $all.Count)
    $all | Select-Object -First 25 | ForEach-Object {
        Write-Output ("    {0,-46} L{1,6}  {2}" -f $_.Filename, $_.LineNumber, $_.Line.Trim())
    }
}

Write-Output ""
Write-Output "=== 2. R56 中 has_game_started / start_date 相关触发器（对照用） ==="
Get-ChildItem $r56 -Recurse -Include *.txt -File -ErrorAction SilentlyContinue |
    Select-String -Pattern 'has_game_started|start_date\s*>' -ErrorAction SilentlyContinue |
    Select-Object -First 15 | ForEach-Object {
        Write-Output ("    {0,-46} L{1,6}  {2}" -f $_.Filename, $_.LineNumber, $_.Line.Trim())
    }

Write-Output ""
Write-Output "=== 3. error.log 里是否已有 has_start_date 报错（若游戏跑过） ==="
$logDir = 'C:\Users\xuwei\Documents\Paradox Interactive\Hearts of Iron IV\logs'
if (Test-Path $logDir) {
    Get-ChildItem $logDir -Filter '*.log' -ErrorAction SilentlyContinue | ForEach-Object {
        $h = (Select-String -Path $_.FullName -Pattern 'has_start_date' -ErrorAction SilentlyContinue).Count
        Write-Output ("    {0,-28} has_start_date 命中 {1}" -f $_.Name, $h)
    }
} else {
    Write-Output "    logs 目录不存在（游戏未运行过）"
}

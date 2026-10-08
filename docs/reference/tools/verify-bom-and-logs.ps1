# verify-bom-and-logs.ps1
# 目的：
#   1. 检查/修正刚创建的两个 .mod 文件的 BOM（带 BOM 会导致 mod 完全不加载）
#   2. 校验 wiki 归档是否可搜（用已知触发器对照）
#   3. 检查 error.log 的新鲜度，判断能否用它验证 has_start_date 是否报错
# 用法：powershell -NoProfile -File verify-bom-and-logs.ps1

$ErrorActionPreference = 'Stop'

$targets = @(
    'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\descriptor.mod',
    'C:\Users\xuwei\Documents\Paradox Interactive\Hearts of Iron IV\mod\The Heart of Iron.mod'
)

Write-Output "=== 1. .mod 文件 BOM 检查 ==="
foreach ($t in $targets) {
    if (-not (Test-Path $t)) { Write-Output ("  {0}`n    -> 文件不存在" -f $t); continue }
    $bytes = [System.IO.File]::ReadAllBytes($t)
    $hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $eol = if ($bytes -contains 0x0D) { 'CRLF' } else { 'LF' }
    Write-Output ("  {0}" -f $t)
    Write-Output ("    {0} 字节 | BOM={1} | 行尾={2}" -f $bytes.Length, $hasBom, $eol)

    if ($hasBom) {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
        [System.IO.File]::WriteAllText($t, $text, (New-Object System.Text.UTF8Encoding($false)))
        Write-Output "    -> 已剥离 BOM（重写为 UTF-8 无 BOM）"
    }
}

Write-Output ""
Write-Output "=== 2. wiki 归档可搜性对照（已知触发器应有命中）==="
$wiki = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\docs\reference\wiki\Triggers.txt'
if (Test-Path $wiki) {
    foreach ($needle in @('has_war', 'has_start_date', 'has_game_started', 'has_completed_focus')) {
        $n = (Select-String -Path $wiki -Pattern $needle -SimpleMatch -ErrorAction SilentlyContinue).Count
        Write-Output ("    {0,-24} 命中 {1}" -f $needle, $n)
    }
    Write-Output ("    （wiki 文件大小 {0} 字节）" -f (Get-Item $wiki).Length)
} else {
    Write-Output "    Triggers.txt 不存在"
}

Write-Output ""
Write-Output "=== 3. error.log 新鲜度 ==="
$logDir = 'C:\Users\xuwei\Documents\Paradox Interactive\Hearts of Iron IV\logs'
$err = Join-Path $logDir 'error.log'
if (Test-Path $err) {
    $fi = Get-Item $err
    Write-Output ("    error.log  修改时间 = {0}  大小 = {1} 字节" -f $fi.LastWriteTime, $fi.Length)
    Write-Output ("    今天 = {0}" -f (Get-Date))
    Write-Output "    --- 前 25 行 ---"
    Get-Content $err -TotalCount 25 | ForEach-Object { Write-Output ("      " + $_) }
} else {
    Write-Output "    error.log 不存在"
}

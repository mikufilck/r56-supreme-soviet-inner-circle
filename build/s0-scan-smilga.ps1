# SOP 第 0 步：查现成内容（原版 + dlc 子目录 + R56）
# 目标人物：伊瓦尔·捷尼索维奇·斯米尔加（花名册 Idx 10）
# 工具蓝本：build/s0-scan-radek.ps1（同一命名约定）
# 🚩 教训（docs/23 第 0 步）：必须扫 dlc\<name>\，漏扫曾导致「布哈林没有大立绘」错判。
# 🚩 性能：F: 盘逐文件 Select-String 跑不完 —— 必须【一次调用 + 路径数组】。
$ErrorActionPreference = 'Continue'

$roots = @(
    @{ Name = '原版';     Path = 'F:\Hearts of Iron IV' },
    @{ Name = '原版-dlc'; Path = 'F:\Hearts of Iron IV\dlc' },
    @{ Name = 'R56';      Path = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)

# ASCII 部分保证可匹配；西里尔部分用于俄文（BOM 保证按 UTF-8 读）
# ⚠️ 变体：Smilga / Смилга / 拉脱维亚语 Smilga 同形；注意别把 Smilgа（最后一个字母是西里尔 а）
#    与拉丁 Smilga 混淆 —— 两种都要查。
$rx     = 'smilga|Smilga|Смилга|смилга'
$rxFile = 'smilga|Smilga|Смилга|смилга'

$subdirs = @('common', 'events', 'history', 'localisation', 'interface')

$out = @()
$out += '==== SOP 第 0 步 · 斯米尔加（Idx 10）===='
$out += ''

foreach ($r in $roots) {
    if (-not (Test-Path $r.Path)) { $out += "[$($r.Name)] 路径不存在：$($r.Path)"; continue }
    $out += "==================== $($r.Name) ===================="

    # --- A. 内容命中（逐行）---
    foreach ($sd in $subdirs) {
        $d = Join-Path $r.Path $sd
        if (-not (Test-Path $d)) { continue }
        $files = @(Get-ChildItem -LiteralPath $d -Recurse -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Extension -in @('.txt', '.yml', '.gfx', '.gui') } |
                   Select-Object -ExpandProperty FullName)
        if ($files.Count -eq 0) { continue }
        $m = @(Select-String -Path $files -Pattern $rx -ErrorAction SilentlyContinue)
        if ($m.Count -gt 0) {
            $fc = @($m | Select-Object -ExpandProperty Path -Unique).Count
            $out += "  --- $sd （$($m.Count) 行命中 / $fc 个文件）---"
            foreach ($x in $m) {
                $out += ('    {0}:{1}' -f $x.Path.Replace($r.Path + '\', ''), $x.LineNumber)
                $out += ('        ' + $x.Line.Trim())
            }
        }
    }

    # --- B. 文件名命中（立绘 / 资产）---
    $gd = Join-Path $r.Path 'gfx'
    $fn = @()
    if (Test-Path $gd) {
        $fn = @(Get-ChildItem -LiteralPath $gd -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $rxFile } |
                Select-Object -ExpandProperty FullName)
    }
    $out += "  --- gfx 下文件名命中（$($fn.Count) 个）---"
    foreach ($f in $fn) { $out += ('    ' + $f.Replace($r.Path + '\', '')) }

    $out += ''
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-smilga.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

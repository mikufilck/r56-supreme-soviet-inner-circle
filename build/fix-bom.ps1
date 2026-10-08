# fix-bom.ps1
# ---------------------------------------------------------------------------
# BOM 归一化。HOI4 的编码红线：
#   · 脚本 .txt / .gui / .mod / descriptor.mod  ->  UTF-8 【无】BOM
#   · 本地化 .yml                                ->  UTF-8 【带】BOM
# 写错会乱码、静默不加载，本地化甚至崩溃 0xC0000005。
#
# ⚠️ 本项目的文件是用 create_file 工具创建的，该工具【默认写 BOM】，
#    因此每次新增脚本文件后都要跑一次这个脚本。
#
# 用法：powershell -NoProfile -File fix-bom.ps1
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$ModRoot = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron',
    [switch]$WhatIfOnly
)

$ErrorActionPreference = 'Stop'

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$utf8Bom   = New-Object System.Text.UTF8Encoding($true)

function Test-HasBom([byte[]]$bytes) {
    return ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
}

function Strip-Bom([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

function Add-Bom([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    [System.IO.File]::WriteAllText($path, $text, $utf8Bom)
}

$changed = 0
$ok = 0

Write-Output "=== 应为【无 BOM】：脚本 .txt / .gui / .mod ==="
$scriptFiles = Get-ChildItem $ModRoot -Recurse -File |
    Where-Object { $_.Extension -in @('.txt', '.gui', '.mod') }
foreach ($f in $scriptFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if (Test-HasBom $bytes) {
        if ($WhatIfOnly) {
            Write-Output ("  [待处理] " + $f.FullName.Replace($ModRoot + '\', ''))
        } else {
            Strip-Bom $f.FullName
            Write-Output ("  [已剥 BOM] " + $f.FullName.Replace($ModRoot + '\', ''))
        }
        $changed++
    } else {
        $ok++
    }
}
Write-Output ("  已正确 {0} 个" -f $ok)

Write-Output ""
Write-Output "=== 应为【带 BOM】：本地化 .yml ==="
$ymlFiles = Get-ChildItem (Join-Path $ModRoot 'localisation') -Recurse -File -Filter '*.yml' -ErrorAction SilentlyContinue
foreach ($f in $ymlFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    $nameOk = $f.Name -match '_l_[a-z_]+\.yml$'
    if (-not $nameOk) {
        Write-Output ("  [⚠️ 文件名缺语言后缀] " + $f.Name)
    }
    if (-not (Test-HasBom $bytes)) {
        if ($WhatIfOnly) {
            Write-Output ("  [待处理] " + $f.Name)
        } else {
            Add-Bom $f.FullName
            Write-Output ("  [已加 BOM] " + $f.Name)
        }
        $changed++
    } else {
        # 首行必须是对应语言声明
        $firstLine = (Get-Content $f.FullName -TotalCount 1)
        $expected = 'l_simp_chinese:'
        if ($firstLine -notmatch '^\uFEFF?l_simp_chinese:\s*$') {
            Write-Output ("  [⚠️ 首行异常] " + $f.Name + "  实际: '" + $firstLine + "'  （应为 " + $expected + "）")
        } else {
            $ok++
        }
    }
}

Write-Output ""
if ($WhatIfOnly) {
    Write-Output ("需要处理 {0} 个文件（仅检查模式，未改动）" -f $changed)
} else {
    Write-Output ("已修正 {0} 个文件，其余 {1} 个本已正确" -f $changed, $ok)
}

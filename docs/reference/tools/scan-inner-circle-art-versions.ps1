# scan-inner-circle-art-versions.ps1
# ---------------------------------------------------------------------------
# 核实核心圈窗口美术：v1 / v2 各交付了什么，游戏里实际用的是哪一套？
#   · 列 art/inner_circle/v1 与 v2 的文件（大小 + 修改时间）
#   · 列 mod/heart_of_iron/gfx/interface/hof_ic 下已接入的 DDS
#   · 读 DDS 头拿宽高，和 docs/16 的规格对照
#
# 产出（建议）：docs/reference/reports/inner-circle-art-versions.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'SilentlyContinue'

$ROOT = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron'
$dirs = @(
    'art\inner_circle\v1',
    'art\inner_circle\v2',
    'mod\heart_of_iron\gfx\interface\hof_ic'
)

function Show-Dds([string]$path) {
    # DDS 头：magic(4) size(4) flags(4) height(4)@12 width(4)@16
    $b = [System.IO.File]::ReadAllBytes($path)
    if ($b.Length -lt 20) { return '' }
    if ($b[0] -ne 0x44) { return '' }   # 'D'
    $h = [BitConverter]::ToUInt32($b, 12)
    $w = [BitConverter]::ToUInt32($b, 16)
    return "${w}x${h}"
}

foreach ($d in $dirs) {
    $full = Join-Path $ROOT $d
    Write-Output ''
    Write-Output ('=' * 100)
    Write-Output ("### $d")
    Write-Output ('=' * 100)
    if (-not (Test-Path $full)) { Write-Output '  （目录不存在）'; continue }
    Get-ChildItem $full -File | Sort-Object Name | ForEach-Object {
        $dim = ''
        if ($_.Extension -ieq '.dds') { $dim = Show-Dds $_.FullName }
        $line = '  {0,-46} {1,10:N0}  {2}  {3}' -f $_.Name, $_.Length, $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm'), $dim
        Write-Output $line
    }
}

# .gui 里引用的 sprite 名（看窗口用哪些）
Write-Output ''
Write-Output ('=' * 100)
Write-Output '### interface/hof_ic.gfx 里注册的 sprite -> texturefile'
Write-Output ('=' * 100)
$gfx = Join-Path $ROOT 'mod\heart_of_iron\interface\hof_ic.gfx'
if (Test-Path $gfx) {
    $lines = [System.IO.File]::ReadAllLines($gfx)
    $cur = ''
    foreach ($l in $lines) {
        if ($l -match 'name\s*=\s*"([^"]+)"') { $cur = $Matches[1] }
        if ($l -match 'texturefile\s*=\s*"([^"]+)"') {
            Write-Output ('  {0,-38} -> {1}' -f $cur, $Matches[1])
        }
    }
} else {
    Write-Output '  （找不到 hof_ic.gfx）'
}

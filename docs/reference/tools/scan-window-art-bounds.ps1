# =============================================================================
# 量 hof_ic_window_bg.dds 的实际覆盖范围（逐行/逐列统计 alpha）
# -----------------------------------------------------------------------------
# 为什么要量：
#   窗口容器是 631x583，底板图也是 631x583，看起来"1:1 完美贴合"。
#   但"图是 631x583"不等于"可用的画框区域就是 631x583" ——
#   美术可能只在画布中间画了画框，四周（尤其底部）是透明的。
#   那样的话，摆在边缘的组件（比如底部候选栏）就会落在画框之外。
#
#   从缩略截图里目测这个说不清，所以直接读 DDS 数 alpha。
#
# 本 DDS 是 32 位【未压缩】，所以极好解析：
#   文件大小 = 128(头) + 宽 x 高 x 4，每像素 4 字节 BGRA（行序自上而下）
#   631 x 583 x 4 + 128 = 1,471,620 字节 —— 与磁盘上的大小吻合，已确认。
# =============================================================================

$ErrorActionPreference = 'Stop'

$ddsPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\gfx\interface\hof_ic\hof_ic_window_bg.dds'

if (-not (Test-Path $ddsPath)) { throw "找不到 $ddsPath" }

$bytes = [System.IO.File]::ReadAllBytes($ddsPath)
Write-Output "文件: $ddsPath"
Write-Output ("字节 = {0:N0}" -f $bytes.Length)

$magic = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4)
$height = [BitConverter]::ToUInt32($bytes, 12)
$width  = [BitConverter]::ToUInt32($bytes, 16)
Write-Output "magic = '$magic'   尺寸 = ${width} x ${height}"

$expect = 128 + [int]$width * [int]$height * 4
if ($bytes.Length -ne $expect) {
    Write-Output "  ⚠️ 大小与'32 位未压缩'不符（期望 $expect）。本脚本只能解析未压缩格式，后面的结论不可信。"
    exit 1
}
Write-Output '  ✓ 大小吻合，确认为 32 位未压缩 BGRA'

$px = 128
$A_TH = 16          # alpha 阈值：小于它视为透明

# ---- 逐行 alpha 覆盖率 ----
$rowCov = New-Object int[] $height
for ($y = 0; $y -lt $height; $y++) {
    $rowStart = $px + $y * $width * 4
    $c = 0
    for ($x = 0; $x -lt $width; $x++) {
        if ($bytes[$rowStart + $x * 4 + 3] -gt $A_TH) { $c++ }
    }
    $rowCov[$y] = $c
}

# ---- 逐列 alpha 覆盖率 ----
$colCov = New-Object int[] $width
for ($x = 0; $x -lt $width; $x++) {
    $c = 0
    $off = $px + $x * 4
    for ($y = 0; $y -lt $height; $y++) {
        if ($bytes[$off + $y * $width * 4 + 3] -gt $A_TH) { $c++ }
    }
    $colCov[$x] = $c
}

Write-Output ''
Write-Output '================ 逐行 alpha 覆盖率（每 10 行采样）================'
Write-Output '  行    覆盖像素   占宽比例   条形图'
for ($y = 0; $y -lt $height; $y += 10) {
    $pct = 100.0 * $rowCov[$y] / $width
    $barLen = [int][Math]::Round($pct / 4)
    $bar = '#' * $barLen
    Write-Output ("  {0,4}  {1,8}   {2,6:N1}%   {3}" -f $y, $rowCov[$y], $pct, $bar)
}

Write-Output ''
Write-Output '================ 关键行 ================'

$nonEmptyRows = @(0..($height - 1) | Where-Object { $rowCov[$_] -gt 0 })
$halfRows     = @(0..($height - 1) | Where-Object { $rowCov[$_] -gt ($width * 0.5) })

if ($nonEmptyRows.Count -gt 0) {
    Write-Output ("  有任何非透明像素的行范围 : {0} .. {1}" -f $nonEmptyRows[0], $nonEmptyRows[-1])
} else {
    Write-Output '  整张图全透明！'
}
if ($halfRows.Count -gt 0) {
    Write-Output ("  覆盖超过半宽的行范围     : {0} .. {1}   （可视为'画框主体'）" -f $halfRows[0], $halfRows[-1])
} else {
    Write-Output '  没有任何一行覆盖超过半宽 —— 画框可能很窄或是散件'
}

$nonEmptyCols = @(0..($width - 1) | Where-Object { $colCov[$_] -gt 0 })
$halfCols     = @(0..($width - 1) | Where-Object { $colCov[$_] -gt ($height * 0.5) })
if ($nonEmptyCols.Count -gt 0) {
    Write-Output ("  有任何非透明像素的列范围 : {0} .. {1}" -f $nonEmptyCols[0], $nonEmptyCols[-1])
}
if ($halfCols.Count -gt 0) {
    Write-Output ("  覆盖超过半高的列范围     : {0} .. {1}" -f $halfCols[0], $halfCols[-1])
}

Write-Output ''
Write-Output '================ 结论对照（当前 .gui 的摆法）================'
Write-Output '  当前布局竖向占用：'
Write-Output '    标题      10 .. 44'
Write-Output '    领袖位    48 .. 213（含绸带/头衔框到 220）'
Write-Output '    第一排   232 .. 371'
Write-Output '    第二排   376 .. 515'
Write-Output '    候选栏   523 .. 581'
Write-Output ''
if ($halfRows.Count -gt 0) {
    $top = $halfRows[0]
    $bot = $halfRows[-1]
    Write-Output "  画框主体竖向可用范围 = $top .. $bot（高 $($bot - $top + 1)）"
    if (581 -gt $bot) {
        Write-Output "  ✗ 候选栏底部 581 超出画框主体下沿 $bot —— 会落在画框之外"
    } else {
        Write-Output "  ✓ 候选栏在画框主体之内"
    }
    if ($top -gt 10) {
        Write-Output "  ⚠️ 标题顶部 10 在画框主体上沿 $top 之外"
    }
} else {
    Write-Output '  无法判定画框主体，跳过对照。'
}

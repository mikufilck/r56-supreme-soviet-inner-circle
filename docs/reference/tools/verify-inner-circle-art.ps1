# verify-inner-circle-art.ps1
# 目的：核对交付的 11 张 DDS —— 尺寸是否符合设计清单，通道是否为 32 位带 alpha。
#       .gfx 里不写尺寸，必须读 DDS 头。
# 用法：powershell -NoProfile -File verify-inner-circle-art.ps1

$ErrorActionPreference = 'Stop'
$artDir = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\gfx\interface\hof_ic'

# 设计清单（docs/16-art-spec-inner-circle.md）里规定的尺寸
$spec = [ordered]@{
    'hof_ic_window_bg'         = @(631, 583)
    'hof_ic_spotlight'         = @(588, 538)
    'hof_ic_leader_frame'      = @(165, 165)
    'hof_ic_leader_ribbon'     = @(160, 36)
    'hof_ic_leader_title_box'  = @(115, 22)
    'hof_ic_seat_frame_empty'  = @(131, 139)
    'hof_ic_seat_frame_filled' = @(131, 139)
    'hof_ic_seat_name_box'     = @(146, 26)
    'hof_ic_seat_trait_box'    = @(144, 43)
    'hof_ic_blank_portrait'    = @(156, 210)
    'hof_ic_candidate_slot'    = @(58, 58)
}

Write-Output ("{0,-26} {1,12} {2,12} {3,10} {4}" -f '文件', '实际尺寸', '规格尺寸', '位深', '结果')
Write-Output ('-' * 88)

$bad = 0
$missing = 0

foreach ($name in $spec.Keys) {
    $p = Join-Path $artDir ($name + '.dds')
    if (-not (Test-Path $p)) {
        Write-Output ("{0,-26} {1,12} {2,12} {3,10} {4}" -f $name, '-', ($spec[$name] -join 'x'), '-', '✗ 文件缺失')
        $missing++
        continue
    }

    $b = New-Object byte[] 128
    $fs = [System.IO.File]::OpenRead($p)
    [void]$fs.Read($b, 0, 128)
    $fs.Close()

    if (-not ($b[0] -eq 0x44 -and $b[1] -eq 0x44 -and $b[2] -eq 0x53)) {
        Write-Output ("{0,-26} 非 DDS 文件" -f $name)
        $bad++
        continue
    }

    $h = [BitConverter]::ToInt32($b, 12)
    $w = [BitConverter]::ToInt32($b, 16)

    # DDS_PIXELFORMAT 从偏移 76 开始，flags 在 80，RGBBitCount 在 88，alpha 掩码在 104
    $pfFlags = [BitConverter]::ToInt32($b, 80)
    $bitCount = [BitConverter]::ToInt32($b, 88)
    $alphaMask = [BitConverter]::ToInt32($b, 104)
    $hasAlpha = ($pfFlags -band 0x1) -ne 0

    $depth = "$bitCount 位"
    if (-not $hasAlpha) { $depth += ' 无 alpha' }

    $sizeOk = ($w -eq $spec[$name][0] -and $h -eq $spec[$name][1])
    $alphaOk = $hasAlpha -and $alphaMask -ne 0

    $res = if ($sizeOk -and $alphaOk) { '✓' } elseif (-not $sizeOk) { "✗ 尺寸不符（应为 $($spec[$name] -join 'x')）" } else { '⚠️ 无 alpha 通道，会盖住底下的国策树' }
    if ($res -ne '✓') { $bad++ }

    Write-Output ("{0,-26} {1,12} {2,12} {3,10} {4}" -f $name, "$w x $h", ($spec[$name] -join 'x'), $depth, $res)
}

Write-Output ('-' * 88)
Write-Output ("缺失 {0} 个 / 异常 {1} 个 / 共 {2} 项" -f $missing, $bad, $spec.Count)

Write-Output ""
Write-Output "=== 目录实际内容 ==="
Get-ChildItem $artDir -File | Select-Object Name, Length | Format-Table -AutoSize

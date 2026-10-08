# scan-attach-sizes.ps1 -> 现用于盘点德国核心圈纹理
# 目的：列出德国核心圈窗口用到的全部 DDS 纹理 —— 路径 + 实际像素尺寸。
#       这份清单直接交给 GPT 出图时当参考（可让它读这些文件来模仿风格）。
# 用法：powershell -NoProfile -File scan-inner-circle-art.ps1

$ErrorActionPreference = 'Stop'
$Game = 'F:\Hearts of Iron IV'

# 德国窗口 (.gui) 实际引用到的 sprite，以及它们在 .gfx 里的纹理
$used = @(
    'GFX_inner_circle_decor_bg',
    'GFX_spotlight_overlay',
    'GFX_circular_frame_fuhrer',
    'GFX_fuhrer_name_ribbon',
    'GFX_trait_box_fuhrer',
    'GFX_ascended_advisors_unappointed_frame',
    'GFX_ascended_advisor_name_box',
    'GFX_ascended_advisor_trait_box',
    'GFX_blank_leader_portrait',
    'GFX_tiled_plain_bg2'
)

# 顺便扫一下 inner_circle.gfx 里全部 sprite，看看还有哪些没用上
$allInFile = @()

function Get-DdsSize([string]$rel) {
    $p = Join-Path $Game ($rel -replace '/', '\' -replace '\\\\', '\')
    if (Test-Path $p) {
        $b = New-Object byte[] 20
        $fs = [System.IO.File]::OpenRead($p)
        [void]$fs.Read($b, 0, 20)
        $fs.Close()
        if ($b[0] -eq 0x44 -and $b[1] -eq 0x44 -and $b[2] -eq 0x53) {
            return ("{0} x {1}" -f [BitConverter]::ToInt32($b, 16), [BitConverter]::ToInt32($b, 12))
        }
        return '非 DDS'
    }
    return '文件不存在'
}

Write-Output "=== 德国核心圈窗口用到的纹理（给 GPT 出图时的参考基准）==="
Write-Output ""
Write-Output ("{0,-42} {1,-14} {2}" -f 'sprite', '尺寸', '纹理路径（可交给 GPT 参考）')
Write-Output ('-' * 120)

foreach ($f in Get-ChildItem (Join-Path $Game 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'name\s*=\s*"([A-Za-z0-9_]+)"') {
            $nm = $Matches[1]
            if ($used -contains $nm) {
                $tex = ''
                for ($j = $i; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                    if ($lines[$j] -match 'texturefile\s*=\s*"([^"]+)"') { $tex = $Matches[1]; break }
                }
                $t = $tex -replace '//', '/'
                Write-Output ("{0,-42} {1,-14} {2}" -f $nm, (Get-DdsSize $t), ($Game + '\' + $t))
            }
        }
    }
}

Write-Output ""
Write-Output "=== inner_circle.gfx 里定义的全部 sprite（含未被窗口引用的）==="
$icf = Join-Path $Game 'interface\inner_circle.gfx'
if (Test-Path $icf) {
    $lines = [System.IO.File]::ReadAllLines($icf)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'name\s*=\s*"([A-Za-z0-9_]+)"') {
            $nm = $Matches[1]
            $tex = ''
            for ($j = $i; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                if ($lines[$j] -match 'texturefile\s*=\s*"([^"]+)"') { $tex = $Matches[1]; break }
            }
            $mark = if ($used -contains $nm) { '[窗口在用]' } else { '           ' }
            Write-Output ("  {0} {1,-44} {2}" -f $mark, $nm, (Get-DdsSize ($tex -replace '//','/')))
        }
    }
} else {
    Write-Output "  找不到 inner_circle.gfx"
}

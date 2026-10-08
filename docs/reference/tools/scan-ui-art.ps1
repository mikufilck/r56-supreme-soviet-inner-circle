# scan-ui-art.ps1
# 目的：盘点可用的 UI 素材——中性框/背景候选，以及苏联偏执度 sprite 的实测尺寸。
#       用于把核心圈窗口从德国美术换成中性/苏联美术。
# 用法：powershell -NoProfile -File scan-ui-art.ps1

$ErrorActionPreference = 'Stop'
$Game = 'F:\Hearts of Iron IV'

# 把 interface 下所有 .gfx 读进一个大字符串，便于正则检索
$all = New-Object System.Text.StringBuilder
foreach ($f in Get-ChildItem (Join-Path $Game 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    [void]$all.Append([System.IO.File]::ReadAllText($f.FullName))
}
$t = $all.ToString()
Write-Output ("interface 下 .gfx 合计 {0} 字符" -f $t.Length)

Write-Output ""
Write-Output "=== A. 中性候选 sprite（按前缀分组）==="
foreach ($prefix in @('GFX_tiled', 'GFX_generic', 'GFX_portrait_slot', 'GFX_empty', 'GFX_blank', 'GFX_advisor')) {
    $names = @()
    foreach ($m in [regex]::Matches($t, 'name\s*=\s*"(' + $prefix + '[A-Za-z0-9_]*)"')) {
        $names += $m.Groups[1].Value
    }
    $names = $names | Sort-Object -Unique
    Write-Output ("  [{0}]  {1} 个" -f $prefix, $names.Count)
    $names | Select-Object -First 18 | ForEach-Object { Write-Output ("      " + $_) }
}

Write-Output ""
Write-Output "=== B. 苏联偏执度系统用到的 sprite（含尺寸）==="
$targets = @('GFX_SOV_paranoia_bg', 'GFX_paranoia_photo', 'GFX_SOV_paranoia_meter', 'GFX_SOV_paranoia_needle', 'GFX_propaganda_bg')
foreach ($f in Get-ChildItem (Join-Path $Game 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($tg in $targets) {
            if ($lines[$i] -match ('name\s*=\s*"' + [regex]::Escape($tg) + '"')) {
                Write-Output ("  --- {0}   ({1}) ---" -f $tg, $f.Name)
                for ($j = [Math]::Max(0, $i - 2); $j -lt [Math]::Min($i + 9, $lines.Count); $j++) {
                    Write-Output ("      " + $lines[$j].Trim())
                }
            }
        }
    }
}

Write-Output ""
Write-Output "=== C. 我们现在用的德国 sprite（含尺寸，供对比）==="
$gerTargets = @('GFX_inner_circle_decor_bg', 'GFX_ascended_advisors_unappointed_frame', 'GFX_circular_frame_fuhrer', 'GFX_spotlight_overlay', 'GFX_blank_leader_portrait')
foreach ($f in Get-ChildItem (Join-Path $Game 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        foreach ($tg in $gerTargets) {
            if ($lines[$i] -match ('name\s*=\s*"' + [regex]::Escape($tg) + '"')) {
                Write-Output ("  --- {0} ---" -f $tg)
                for ($j = $i; $j -lt [Math]::Min($i + 8, $lines.Count); $j++) {
                    Write-Output ("      " + $lines[$j].Trim())
                }
            }
        }
    }
}

# scan-roster-art2.ps1
# 目的：修正上一版的致命盲点 —— R56 的角色 portraits 块里，立绘是【直接写 .dds 路径】的，
#       不是 GFX_ sprite 名。上一版只抓 "GFX_..." 因此得出错误结论。
#       本版同时抓两种写法，并对裸 .dds 路径生成「我们需要自己注册的 sprite 名」。
# 用法：powershell -NoProfile -File scan-roster-art2.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$Van = 'F:\Hearts of Iron IV'
$charFile = Join-Path $R56 'common\characters\SOV.txt'

$targets = @(
    'SOV_lev_trotsky', 'SOV_karl_radek', 'SOV_yevgeny_preobrazhensky', 'SOV_ivar_smilga',
    'SOV_ivan_smirnov', 'SOV_grigory_zinovyev', 'SOV_lev_kamenev', 'SOV_nikolay_bukharin',
    'SOV_aleksey_rykov', 'SOV_mikhail_tomsky', 'SOV_martemyan_ryutin',
    'SOV_grigory_sokolnikov', 'SOV_aleksandr_shlyapnikov',
    'SOV_leonid_serebryakov', 'SOV_boris_shteifon',
    'SOV_vyacheslav_molotov', 'SOV_lazar_kaganovich', 'SOV_mikhail_kalinin',
    'SOV_kliment_voroshilov', 'SOV_mikhail_tukhachevsky', 'SOV_maksim_litvinov',
    'SOV_supreme_soviet'
)

$text = [System.IO.File]::ReadAllText($charFile)

# 括号配平取每个角色块
$blocks = @{}
foreach ($m in [regex]::Matches($text, '(?m)^\s*(SOV_[A-Za-z0-9_]+)\s*=\s*\{')) {
    $id = $m.Groups[1].Value
    if ($blocks.ContainsKey($id)) { continue }
    $open = $text.IndexOf('{', $m.Index)
    $depth = 0; $close = -1
    for ($j = $open; $j -lt $text.Length; $j++) {
        $c = $text[$j]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') { $depth--; if ($depth -eq 0) { $close = $j; break } }
    }
    if ($close -gt 0) { $blocks[$id] = $text.Substring($open, $close - $open + 1) }
}
Write-Output ("解析到角色块: {0} 个" -f $blocks.Count)

# 只取 portraits = { ... } 子块，避免把 advisor 的 icon 也算进来
function Get-PortraitsBlock([string]$body) {
    $m = [regex]::Match($body, 'portraits\s*=\s*\{')
    if (-not $m.Success) { return '' }
    $open = $body.IndexOf('{', $m.Index)
    $depth = 0; $close = -1
    for ($j = $open; $j -lt $body.Length; $j++) {
        $c = $body[$j]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') { $depth--; if ($depth -eq 0) { $close = $j; break } }
    }
    if ($close -lt 0) { return '' }
    return $body.Substring($open, $close - $open + 1)
}

# 判断裸 .dds 路径对应的文件是否真实存在（相对任一根目录）
function Resolve-Dds([string]$rel) {
    $r = $rel -replace '/', '\'
    foreach ($root in @($Van, $R56)) {
        if (Test-Path (Join-Path $root $r)) { return $(if ($root -eq $Van) { 'vanilla' } else { 'r56' }) }
    }
    return ''
}

Write-Output ""
Write-Output ("{0,-30} {1,-8} {2,-58} {3}" -f '角色', '有无立绘', '立绘路径 / sprite', '需要我们注册的 sprite 名')
Write-Output ('-' * 130)

$hasCount = 0
foreach ($t in $targets) {
    if (-not $blocks.ContainsKey($t)) {
        Write-Output ("{0,-30} {1,-8} {2,-58} {3}" -f $t, '-', '【角色块不存在】', '-')
        continue
    }
    $pb = Get-PortraitsBlock $blocks[$t]
    $dds = @()
    $gfx = @()
    foreach ($m in [regex]::Matches($pb, '"([^"]+\.dds)"')) { $dds += $m.Groups[1].Value }
    foreach ($m in [regex]::Matches($pb, '"(GFX_[A-Za-z0-9_]+)"')) { $gfx += $m.Groups[1].Value }
    $dds = $dds | Sort-Object -Unique
    $gfx = $gfx | Sort-Object -Unique

    if ($dds.Count -eq 0 -and $gfx.Count -eq 0) {
        Write-Output ("{0,-30} {1,-8} {2,-58} {3}" -f $t, '无', '（portraits 块为空）', '-')
        continue
    }

    $hasCount++
    $show = if ($dds.Count) { $dds[0] } else { $gfx[0] }
    $exist = if ($dds.Count) { Resolve-Dds $dds[0] } else { '(sprite)' }
    $need = if ($dds.Count) { 'GFX_hof_ic_portrait_' + ($t -replace '^SOV_','') } else { '（已是 sprite，直接用）' }
    Write-Output ("{0,-30} {1,-8} {2,-58} {3}" -f $t, '有', $show, $need)
    if ($exist -eq '') { Write-Output ("      ⚠️ 该 .dds 文件在两边都找不到") }
}

Write-Output ('-' * 130)
Write-Output ("{0} / {1} 个角色有立绘" -f $hasCount, $targets.Count)

Write-Output ""
Write-Output "=== 领袖位 SOV_supreme_soviet 的立绘 ==="
if ($blocks.ContainsKey('SOV_supreme_soviet')) {
    Write-Output (Get-PortraitsBlock $blocks['SOV_supreme_soviet'])
} else {
    Write-Output "（角色块不存在）"
}

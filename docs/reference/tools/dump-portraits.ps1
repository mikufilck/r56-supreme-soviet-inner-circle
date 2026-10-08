# dump-portraits.ps1
# 目的：把目标角色的 portraits 块【原文】打出来。不做任何加工，避免解析引入错误。
# 用法：powershell -NoProfile -File dump-portraits.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$text = [System.IO.File]::ReadAllText((Join-Path $R56 'common\characters\SOV.txt'))

$targets = @(
    'SOV_lev_trotsky', 'SOV_karl_radek', 'SOV_yevgeny_preobrazhensky', 'SOV_ivar_smilga',
    'SOV_ivan_smirnov', 'SOV_grigory_zinovyev', 'SOV_lev_kamenev', 'SOV_nikolay_bukharin',
    'SOV_aleksey_rykov', 'SOV_mikhail_tomsky', 'SOV_martemyan_ryutin',
    'SOV_grigory_sokolnikov', 'SOV_aleksandr_shlyapnikov',
    'SOV_vyacheslav_molotov', 'SOV_mikhail_tukhachevsky', 'SOV_kliment_voroshilov',
    'SOV_boris_shteifon'
)

foreach ($t in $targets) {
    $m = [regex]::Match($text, '(?m)^\s*' + [regex]::Escape($t) + '\s*=\s*\{')
    Write-Output ""
    Write-Output ("########## " + $t + " ##########")
    if (-not $m.Success) { Write-Output "  （角色块不存在）"; continue }

    $open = $text.IndexOf('{', $m.Index)
    $depth = 0; $close = -1
    for ($j = $open; $j -lt $text.Length; $j++) {
        $c = $text[$j]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') { $depth--; if ($depth -eq 0) { $close = $j; break } }
    }
    $body = $text.Substring($open, $close - $open + 1)

    # 只打印 portraits 块
    $pm = [regex]::Match($body, 'portraits\s*=\s*\{')
    if (-not $pm.Success) { Write-Output "  portraits 块：不存在"; continue }
    $po = $body.IndexOf('{', $pm.Index)
    $d2 = 0; $pc = -1
    for ($j = $po; $j -lt $body.Length; $j++) {
        $c = $body[$j]
        if ($c -eq '{') { $d2++ }
        elseif ($c -eq '}') { $d2--; if ($d2 -eq 0) { $pc = $j; break } }
    }
    $pblock = $body.Substring($po, $pc - $po + 1)
    foreach ($line in ($pblock -split "`r?`n")) {
        if ($line.Trim()) { Write-Output ("  " + $line.Trim()) }
    }
}

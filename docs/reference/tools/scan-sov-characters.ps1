# scan-sov-characters.ps1
# 目的：直接解析 R56 的 common/characters/SOV.txt —— 每个角色的 id 与其
#       portraits 块里实际引用的 sprite 名。这是权威映射，不用猜命名规律。
# 用法：powershell -NoProfile -File scan-sov-characters.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$charFile = Join-Path $R56 'common\characters\SOV.txt'

if (-not (Test-Path $charFile)) { Write-Output "找不到 $charFile"; exit 1 }

$text = [System.IO.File]::ReadAllText($charFile)
Write-Output ("SOV.txt 大小: {0} 字符" -f $text.Length)

# 目标角色（docs/10 §2.2.1 的 13 名 + §2.2.4 领袖位 + 体制方几名）
$targets = @(
    'SOV_lev_trotsky', 'SOV_karl_radek', 'SOV_yevgeny_preobrazhensky', 'SOV_ivar_smilga',
    'SOV_ivan_smirnov', 'SOV_grigory_zinovyev', 'SOV_lev_kamenev', 'SOV_nikolay_bukharin',
    'SOV_aleksey_rykov', 'SOV_mikhail_tomsky', 'SOV_martemyan_ryutin',
    'SOV_grigory_sokolnikov', 'SOV_aleksandr_shlyapnikov',
    'SOV_supreme_soviet',
    'SOV_vyacheslav_molotov', 'SOV_lazar_kaganovich', 'SOV_mikhail_kalinin',
    'SOV_kliment_voroshilov', 'SOV_mikhail_tukhachevsky', 'SOV_maksim_litvinov',
    'SOV_genrikh_yagoda', 'SOV_nikolay_yezhov', 'SOV_lavrenty_beriya'
)

# 提取每个角色块：<TAG_char_id> = { ... }
# 用括号配平切块，再取 portraits 里所有 "GFX_..." 引用
function Get-Blocks([string]$t) {
    $res = @{}
    foreach ($m in [regex]::Matches($t, '(?m)^\s*(SOV_[A-Za-z0-9_]+)\s*=\s*\{')) {
        $id = $m.Groups[1].Value
        $open = $t.IndexOf('{', $m.Index)
        $depth = 0
        $close = -1
        for ($j = $open; $j -lt $t.Length; $j++) {
            $c = $t[$j]
            if ($c -eq '{') { $depth++ }
            elseif ($c -eq '}') { $depth--; if ($depth -eq 0) { $close = $j; break } }
        }
        if ($close -gt 0) { $res[$id] = $t.Substring($open, $close - $open + 1) }
    }
    return $res
}

$blocks = Get-Blocks $text
Write-Output ("解析到角色块: {0} 个" -f $blocks.Count)

Write-Output ""
Write-Output "=== 目标角色的立绘 sprite ==="
Write-Output ("{0,-38} {1}" -f '角色 id', 'portraits 里的 sprite')
Write-Output ('-' * 100)

foreach ($t in $targets) {
    if (-not $blocks.ContainsKey($t)) {
        Write-Output ("{0,-38} 【角色块不存在】" -f $t)
        continue
    }
    $body = $blocks[$t]
    $sprites = @()
    foreach ($m in [regex]::Matches($body, '"(GFX_[A-Za-z0-9_]+)"')) { $sprites += $m.Groups[1].Value }
    $sprites = $sprites | Sort-Object -Unique
    Write-Output ("{0,-38} {1}" -f $t, $(if ($sprites.Count) { $sprites -join ' , ' } else { '（块内无 sprite 引用）' }))
}

Write-Output ""
Write-Output "=== 对照：R56 里所有 r56_portrait_SOV_* 的 sprite（含大小图）==="
$gfxAll = New-Object System.Text.StringBuilder
foreach ($root in @('F:\Hearts of Iron IV', $R56)) {
    foreach ($f in Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -Recurse -ErrorAction SilentlyContinue) {
        [void]$gfxAll.Append([System.IO.File]::ReadAllText($f.FullName))
    }
}
$all = $gfxAll.ToString()
$lst = @()
foreach ($m in [regex]::Matches($all, 'name\s*=\s*"(GFX_(?:r56_)?portrait_SOV_[A-Za-z0-9_]+)"')) { $lst += $m.Groups[1].Value }
foreach ($m in [regex]::Matches($all, 'name\s*=\s*"(GFX_r56_[A-Za-z0-9_]*portrait[A-Za-z0-9_]*)"')) { $lst += $m.Groups[1].Value }
$lst | Sort-Object -Unique | ForEach-Object { Write-Output ("   " + $_) }

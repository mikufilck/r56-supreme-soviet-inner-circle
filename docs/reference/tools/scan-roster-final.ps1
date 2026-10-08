# scan-roster-final.ps1
# 目的：一次性、无遗漏地确定「哪些角色有可用的大幅立绘」。
#       要点（前几版都栽在这里）：
#         1. 大幅立绘可能写在 civilian.large 【或】 army.large —— 两个都要查
#         2. 值可能是 .dds 直接路径，也可能是 GFX_ sprite 名，还可能是【不带引号】的裸名
#         3. 输出原始值，不做花哨加工（PowerShell 的字符串 [0] 取首字符坑过两次）
# 用法：powershell -NoProfile -File scan-roster-final.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$Van = 'F:\Hearts of Iron IV'
$charFile = Join-Path $R56 'common\characters\SOV.txt'
$text = [System.IO.File]::ReadAllText($charFile)

# 候选：13 反对派 + 谢列布里亚科夫(需补) + 体制方 + 几名存疑组
$targets = @(
    'SOV_lev_trotsky','SOV_karl_radek','SOV_yevgeny_preobrazhensky','SOV_ivar_smilga',
    'SOV_ivan_smirnov','SOV_grigory_zinovyev','SOV_lev_kamenev','SOV_nikolay_bukharin',
    'SOV_aleksey_rykov','SOV_mikhail_tomsky','SOV_martemyan_ryutin',
    'SOV_grigory_sokolnikov','SOV_aleksandr_shlyapnikov',
    'SOV_vyacheslav_molotov','SOV_lazar_kaganovich','SOV_mikhail_kalinin',
    'SOV_kliment_voroshilov','SOV_mikhail_tukhachevsky','SOV_maksim_litvinov',
    'SOV_supreme_soviet','SOV_genrikh_yagoda','SOV_nikolay_yezhov','SOV_lavrenty_beriya',
    'SOV_georgy_malenkow','SOV_nikita_khrushchyov','SOV_nikolay_voznesensky',
    'SOV_pyotr_smirnov','SOV_vsevolod_merkulov',
    # 名单里提到但 §2.2.3 说"未找到"的，一并验证是否真的没有
    'SOV_leonid_serebryakov','SOV_grigory_ordzhonikidze','SOV_felix_dzerzhinsky',
    'SOV_valerian_kuibyshev','SOV_sergei_kirov','SOV_anastas_mikoyan',
    'SOV_grigory_pyatakov','SOV_nikolai_muralov','SOV_alexandra_kollontai'
)

# 取角色块
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

# 从 portraits 块里取出某个键的值（容忍有引号/无引号）
function Get-PortraitValue([string]$pblock, [string]$section, [string]$key) {
    $m = [regex]::Match($pblock, $section + '\s*=\s*\{(?<inner>[^}]*)\}', 'IgnoreCase')
    if (-not $m.Success) { return '' }
    $inner = $m.Groups['inner'].Value
    $k = [regex]::Match($inner, $key + '\s*=\s*"?([^"\r\n\}]+)"?', 'IgnoreCase')
    if (-not $k.Success) { return '' }
    return $k.Groups[1].Value.Trim()
}

function Get-Portraits([string]$body) {
    $m = [regex]::Match($body, 'portraits\s*=\s*\{')
    if (-not $m.Success) { return $null }
    $open = $body.IndexOf('{', $m.Index)
    $depth = 0; $close = -1
    for ($j = $open; $j -lt $body.Length; $j++) {
        $c = $body[$j]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') { $depth--; if ($depth -eq 0) { $close = $j; break } }
    }
    if ($close -lt 0) { return $null }
    return $body.Substring($open, $close - $open + 1)
}

function Dds-Exists([string]$rel) {
    $r = $rel -replace '/', '\'
    foreach ($root in @($Van, $R56)) { if (Test-Path (Join-Path $root $r)) { return '是' } }
    return '否'
}

Write-Output ("{0,-30} {1,-34} {2,-34} {3}" -f '角色', 'civilian.large', 'army.large', '结论')
Write-Output ('-' * 122)

$have = @(); $lack = @(); $noblock = @()

foreach ($t in $targets) {
    if (-not $blocks.ContainsKey($t)) { $noblock += $t; continue }
    $pb = Get-Portraits $blocks[$t]
    if (-not $pb) { $noblock += $t; continue }

    $cl = Get-PortraitValue $pb 'civilian' 'large'
    $al = Get-PortraitValue $pb 'army' 'large'

    $best = ''
    if ($cl) { $best = $cl } elseif ($al) { $best = $al }

    $verdict = ''
    if ($best) {
        if ($best -match '\.dds$') {
            $ex = Dds-Exists $best
            $verdict = if ($ex -eq '是') { '✅ 有可用大幅立绘（.dds）' } else { '⚠️ 指向的 .dds 不存在' }
        } else {
            $verdict = '✅ 有可用大幅立绘（sprite）'
        }
        $have += $t
    } else {
        $verdict = '❌ 只有小图，需补大图'
        $lack += $t
    }
    Write-Output ("{0,-30} {1,-34} {2,-34} {3}" -f $t, $(if($cl){$cl}else{'-'}), $(if($al){$al}else{'-'}), $verdict)
}

Write-Output ('-' * 122)
Write-Output ("有大幅立绘 {0} 个 / 只有小图 {1} 个 / 角色块不存在 {2} 个" -f $have.Count, $lack.Count, $noblock.Count)

Write-Output ""
Write-Output "=== 有大幅立绘的 ==="
$have | ForEach-Object { Write-Output ("   " + $_) }
Write-Output ""
Write-Output "=== 只有小图、需要补的 ==="
$lack | ForEach-Object { Write-Output ("   " + $_) }
Write-Output ""
Write-Output "=== 角色块不存在的（需新建）==="
$noblock | ForEach-Object { Write-Output ("   " + $_) }

# 把小图路径也吐出来，供出图时做参考
Write-Output ""
Write-Output "=== 需补图角色的「小图」sprite 与文件路径（给 GPT 当参考用）==="
foreach ($t in $lack) {
    $pb = Get-Portraits $blocks[$t]
    $cs = Get-PortraitValue $pb 'civilian' 'small'
    $as = Get-PortraitValue $pb 'army' 'small'
    $s = if ($cs) { $cs } elseif ($as) { $as } else { '' }
    if (-not $s) { Write-Output ("   {0,-30} （无小图）" -f $t); continue }
    # 找这个 sprite 的 texturefile
    $tex = ''
    foreach ($root in @($Van, $R56)) {
        foreach ($f in Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -Recurse -ErrorAction SilentlyContinue) {
            $x = [System.IO.File]::ReadAllText($f.FullName)
            $mm = [regex]::Match($x, '(?s)name\s*=\s*"' + [regex]::Escape($s) + '".{0,300}?texturefile\s*=\s*"([^"]+)"')
            if ($mm.Success) { $tex = $mm.Groups[1].Value -replace '//', '/'; break }
        }
        if ($tex) { break }
    }
    if ($tex) {
        $full = ''
        foreach ($root in @($Van, $R56)) { if (Test-Path (Join-Path $root ($tex -replace '/','\'))) { $full = $root + '\' + ($tex -replace '/','\'); break } }
        Write-Output ("   {0,-30} {1,-40} {2}" -f $t, $s, $full)
    } else {
        Write-Output ("   {0,-30} {1,-40} （纹理未找到）" -f $t, $s)
    }
}

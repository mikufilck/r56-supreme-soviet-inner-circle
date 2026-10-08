# scan-sov-portraits2.ps1
# 目的：修正上一版的扫描漏洞 —— 立绘 sprite 可能定义在
#       ① 原版而非 R56  ② interface 的子目录里。
# 用法：powershell -NoProfile -File scan-sov-portraits2.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$Van = 'F:\Hearts of Iron IV'

$chars = @(
    'SOV_lev_trotsky', 'SOV_karl_radek', 'SOV_yevgeny_preobrazhensky', 'SOV_ivar_smilga',
    'SOV_ivan_smirnov', 'SOV_grigory_zinovyev', 'SOV_lev_kamenev', 'SOV_nikolay_bukharin',
    'SOV_aleksey_rykov', 'SOV_mikhail_tomsky', 'SOV_martemyan_ryutin',
    'SOV_grigory_sokolnikov', 'SOV_aleksandr_shlyapnikov'
)

# 分别收集两边的 gfx 文本，并记录每个 sprite 出自哪个文件
Write-Output "=== A. 递归扫描 interface（含子目录），列出所有含 SOV 的人物立绘 sprite ==="
foreach ($root in @($Van, $R56)) {
    Write-Output ""
    Write-Output ("--- " + $root + " ---")
    $files = Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -Recurse -ErrorAction SilentlyContinue
    Write-Output ("   .gfx 文件数（递归）: " + $files.Count)
    $names = @{}
    foreach ($f in $files) {
        $t = [System.IO.File]::ReadAllText($f.FullName)
        foreach ($m in [regex]::Matches($t, 'name\s*=\s*"(GFX_[A-Za-z0-9_]*[Pp]ortrait[A-Za-z0-9_]*SOV[A-Za-z0-9_]*)"')) {
            $n = $m.Groups[1].Value
            if (-not $names.ContainsKey($n)) { $names[$n] = $f.Name }
        }
    }
    Write-Output ("   含 SOV 的 portrait sprite 共 " + $names.Count + " 个")
    foreach ($n in ($names.Keys | Sort-Object)) {
        Write-Output ("      {0,-52} ({1})" -f $n, $names[$n])
    }
}

Write-Output ""
Write-Output "=== B. 逐个角色确认立绘 sprite（两边合起来找）==="
$all = New-Object System.Text.StringBuilder
foreach ($root in @($Van, $R56)) {
    foreach ($f in Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -Recurse -ErrorAction SilentlyContinue) {
        [void]$all.Append([System.IO.File]::ReadAllText($f.FullName))
    }
}
$allText = $all.ToString()
Write-Output ("合并 gfx 文本 " + $allText.Length + " 字符")

foreach ($c in $chars) {
    $cands = @()
    foreach ($suffix in @('', '_small', '_advisor', '_general')) {
        $n = 'GFX_portrait_' + $c + $suffix
        if ($allText -match ('name\s*=\s*"' + [regex]::Escape($n) + '"')) { $cands += $n }
    }
    Write-Output ("  {0,-38} -> {1}" -f $c, $(if ($cands.Count) { $cands -join ' , ' } else { '（未找到）' }))
}

Write-Output ""
Write-Output "=== C. 看看 R56 里 SOV 角色立绘到底叫什么（抽样 40 个 SOV portrait）==="
$sample = @()
foreach ($m in [regex]::Matches($allText, 'name\s*=\s*"(GFX_[A-Za-z0-9_]*portrait[A-Za-z0-9_]*)"')) {
    $n = $m.Groups[1].Value
    if ($n -match 'SOV') { $sample += $n }
}
$sample | Sort-Object -Unique | Select-Object -First 40 | ForEach-Object { Write-Output ("   " + $_) }

Write-Output ""
Write-Output "=== D. 关键线索：R56 里名字含 'Trotsky' / 'Bukharin' 的一切 sprite ==="
foreach ($kw in @('Trotsky', 'Bukharin', 'Tomsky', 'Rykov', 'Radek', 'Smirnov', 'Sinovyev', 'Zinovyev', 'Kamenev', 'Smilga', 'Preobrazhensky', 'Ryutin', 'Sokolnikov', 'Shlyapnikov')) {
    $hits = @()
    foreach ($m in [regex]::Matches($allText, 'name\s*=\s*"(GFX_[A-Za-z0-9_]*' + $kw + '[A-Za-z0-9_]*)"')) {
        $hits += $m.Groups[1].Value
    }
    $hits = $hits | Sort-Object -Unique
    if ($hits.Count -gt 0) { Write-Output ("   {0,-18} -> {1}" -f $kw, ($hits -join ' , ')) }
    else { Write-Output ("   {0,-18} -> 无" -f $kw) }
}

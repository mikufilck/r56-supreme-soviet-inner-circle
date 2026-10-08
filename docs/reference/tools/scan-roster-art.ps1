# scan-roster-art.ps1
# 目的：为「核心圈席位候选」逐个确认立绘可用性，并给出可直接注册的 texturefile 路径。
#       输出即 S3 的角色名册依据。
# 用法：powershell -NoProfile -File scan-roster-art.ps1

$ErrorActionPreference = 'Stop'
$R56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$Van = 'F:\Hearts of Iron IV'

# 候选：13 名反对派 + 谢列布里亚科夫(§2.2.2) + 体制方几名
$roster = [ordered]@{
    'lev_trotsky'          = @('Leon_Trotsky','Leon_Trotsky_2','trotsky')
    'grigory_zinovyev'     = @('grigory_zinovyev','Grigory_Zinovyev')
    'lev_kamenev'          = @('lev_kamenev','Lev_Kamenev')
    'nikolay_bukharin'     = @('nikolay_bukharin','Nikolay_Bukharin','Bukharin')
    'aleksey_rykov'        = @('aleksey_rykov','Aleksey_Rykov','Rykov')
    'ivan_smirnov'         = @('ivan_smirnov','Ivan_Smirnov')
    'leonid_serebryakov'   = @('Leonid_Serebryakov')
    'karl_radek'           = @('karl_radek','Karl_Radek','Radek')
    'yevgeny_preobrazhensky' = @('Preobrazhensky','preobrazhensky')
    'ivar_smilga'          = @('ivar_smilga','Smilga')
    'mikhail_tomsky'       = @('mikhail_tomsky','Tomsky')
    'martemyan_ryutin'     = @('martemyan_ryutin','Ryutin')
    'grigory_sokolnikov'   = @('grigory_sokolnikov','Sokolnikov')
    'aleksandr_shlyapnikov'= @('aleksandr_shlyapnikov','Shlyapnikov')
    'lavrenty_beriya'      = @('lavrenty_beriya','Beriya')
    'mikhail_tukhachevsky' = @('Mikhail_Tukhachevsky','mikhail_tukhachevsky')
    'nikolay_yezhov'       = @('Nikolai_Yezhov','nikolay_yezhov')
    'maksim_litvinov'      = @('maksim_litvinov','Litvinov')
}

# 1) 把所有立绘 DDS 的（文件名 -> 相对路径）建索引
$index = @{}
foreach ($root in @($Van, $R56)) {
    foreach ($f in Get-ChildItem (Join-Path $root 'gfx\leaders') -Recurse -Filter '*.dds' -File -ErrorAction SilentlyContinue) {
        $rel = $f.FullName.Substring($root.Length).TrimStart('\') -replace '\\', '/'
        $base = $f.Name -replace '\.dds$', ''
        if (-not $index.ContainsKey($base)) { $index[$base] = @() }
        $index[$base] += $rel
    }
}
Write-Output ("gfx/leaders 下立绘文件: {0} 个不同 basename" -f $index.Count)

# 2) 对所有已注册 sprite 名建集合，判断是否需要我们自己注册
$gfxText = New-Object System.Text.StringBuilder
foreach ($root in @($Van, $R56)) {
    foreach ($f in Get-ChildItem (Join-Path $root 'interface') -Filter '*.gfx' -File -Recurse -ErrorAction SilentlyContinue) {
        [void]$gfxText.Append([System.IO.File]::ReadAllText($f.FullName))
    }
}
$gfxAll = $gfxText.ToString()

Write-Output ""
Write-Output "=== 候选角色立绘可用性 ==="
Write-Output ("{0,-24} {1,-8} {2,-46} {3}" -f '角色', '状态', 'texturefile（可直接写进我们的 .gfx）', '同名 sprite 已注册?')
Write-Output ('-' * 132)

foreach ($k in $roster.Keys) {
    $hit = $null
    foreach ($guess in $roster[$k]) {
        if ($index.ContainsKey($guess)) { $hit = $index[$guess][0]; break }
        # 模糊：忽略大小写与 r56_ 前缀
        foreach ($b in $index.Keys) {
            if ($b -replace '^r56_', '' -replace '^portrait_', '' -ieq $guess) { $hit = $index[$b][0]; break }
        }
        if ($hit) { break }
    }
    if (-not $hit) {
        Write-Output ("{0,-24} {1,-8} {2,-46} {3}" -f $k, '无立绘', '-', '-')
        continue
    }
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($hit)
    $dispName = 'GFX_portrait_SOV_' + $k
    $altName  = 'GFX_' + $basename
    $reg = if ($gfxAll -match ('name\s*=\s*"' + [regex]::Escape($dispName) + '"')) { '是(标准名)' }
           elseif ($gfxAll -match ('name\s*=\s*"' + [regex]::Escape($altName) + '"')) { '是(按文件名)' }
           else { '否 → 需我们注册' }
    Write-Output ("{0,-24} {1,-8} {2,-46} {3}" -f $k, '有立绘', $hit, $reg)
}

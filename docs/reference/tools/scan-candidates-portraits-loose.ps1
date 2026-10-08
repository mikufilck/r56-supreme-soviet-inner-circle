# scan-candidates-portraits-loose.ps1
# 宽松复核：只用【姓氏】匹配文件名，防止 "grigory_ordzhonikidze" 这类全名匹配漏掉
# "r56_portrait_SOV_Ordzhonikidze.dds"。同时对被判定"无立绘"的 8 人做 R56 角色块宽松搜索。
$ErrorActionPreference = 'Stop'
$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$MOD  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
$ROOTS = @($MOD, $R56, $HOI4)

# 疑点名单：全名匹配失败的 8 人 + 只找到小图的人（复查有没有姓名的其它大图命名）
$probe = [ordered]@{
    'ordzhonikidze' = 'grigory_ordzhonikidze'
    'dzerzhinsky'   = 'felix_dzerzhinsky'
    'kuibyshev'     = 'valerian_kuibyshev'
    'kirov'         = 'sergei_kirov'
    'mikoyan'       = 'anastas_mikoyan'
    'pyatakov'      = 'grigory_pyatakov'
    'muralov'       = 'nikolai_muralov'
    'kollontai'     = 'alexandra_kollontai'
    'trotsky'       = 'lev_trotsky'
    'preobrazhensky'= 'yevgeny_preobrazhensky'
    'radek'         = 'karl_radek'
    'smilga'        = 'ivar_smilga'
    'bukharin'      = 'nikolay_bukharin'
    'rykov'         = 'aleksey_rykov'
    'tomsky'        = 'mikhail_tomsky'
    'ryutin'        = 'martemyan_ryutin'
    'shlyapnikov'   = 'aleksandr_shlyapnikov'
    'kalinin'       = 'mikhail_kalinin'
    'litvinov'      = 'maksim_litvinov'
    'sokolnikov'    = 'grigory_sokolnikov'
    'voznesensky'   = 'nikolay_voznesensky'
    'serebryakov'   = 'leonid_serebryakov'
}

# 全盘索引 dds 文件名（leaders + ideas）
$allDds = @()
foreach ($root in $ROOTS) {
    foreach ($sub in @('gfx\leaders', 'gfx\interface\ideas')) {
        $p = Join-Path $root $sub
        if (Test-Path $p) { $allDds += Get-ChildItem $p -Recurse -File -Filter *.dds -ErrorAction SilentlyContinue }
    }
}
Write-Output ("全盘 dds 索引：{0} 个" -f $allDds.Count)
Write-Output ''
Write-Output ("{0,-18} {1,-28} {2}" -f '姓氏', '对应全名', '命中文件')
Write-Output ('-' * 110)
foreach ($sn in $probe.Keys) {
    $hits = @($allDds | Where-Object { $_.Name -imatch $sn })
    if ($hits.Count -eq 0) {
        Write-Output ("{0,-18} {1,-28} ★ 无任何文件名命中" -f $sn, $probe[$sn])
    } else {
        Write-Output ("{0,-18} {1,-28} {2} 个" -f $sn, $probe[$sn], $hits.Count)
        foreach ($h in $hits) { Write-Output ("      {0}" -f $h.FullName) }
    }
}

Write-Output ''
Write-Output '=== R56 角色块里是否存在这 8 人的名字（宽泛文本搜索）==='
$names = @('Ordzhonikidze','Dzerzhinsky','Kuibyshev','Kirov','Mikoyan','Pyatakov','Muralov','Kollontai')
$charDirs = @()
foreach ($root in $ROOTS) {
    $p = Join-Path $root 'common\characters'
    if (Test-Path $p) { $charDirs += $p }
}
foreach ($n in $names) {
    $found = @()
    foreach ($d in $charDirs) {
        $found += Select-String -Path (Join-Path $d '*.txt') -Pattern $n -SimpleMatch -ErrorAction SilentlyContinue |
                  ForEach-Object { "{0}:{1}" -f (Split-Path $_.Path -Leaf), $_.LineNumber }
    }
    if ($found.Count -eq 0) { Write-Output ("{0,-16} 角色文件中无提及" -f $n) }
    else { Write-Output ("{0,-16} {1}" -f $n, ($found -join ' | ')) }
}

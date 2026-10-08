# scan-sov-portrait-inventory.ps1
# 列出全盘 SOV 大图/小图清单，用于核心圈候选池对照（docs/10 §2.4.2.1）
$ErrorActionPreference = 'Stop'
$ROOTS = @(
    'F:\Hearts of Iron IV',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125',
    'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
)

Write-Output '===== A. SOV 大图  (gfx/leaders/SOV/*.dds) ====='
foreach ($r in $ROOTS) {
    $p = Join-Path $r 'gfx\leaders\SOV'
    Write-Output ("--- {0}" -f $r)
    if (Test-Path $p) {
        Get-ChildItem $p -File -Filter *.dds | ForEach-Object { Write-Output ("    " + $_.Name) }
    } else { Write-Output '    (无此目录)' }
}

Write-Output ''
Write-Output '===== B. 其它 tag 目录里含 sergo/dzerzh/kuiby/mikoyan/pyatak/kollont/muralov 的大图 ====='
$kw = 'sergo|ordzhon|dzerzh|kuiby|kuyby|mikoyan|mikojan|pyatak|kollont|muralov|ryutin|tomsky|smilga|radek|preobrazh|shlyapn|sokolnik|voznesen|litvinov|serebryak|kalinin|kirov'
foreach ($r in $ROOTS) {
    $p = Join-Path $r 'gfx\leaders'
    if (-not (Test-Path $p)) { continue }
    $hits = Get-ChildItem $p -Recurse -File -Filter *.dds | Where-Object { $_.Name -imatch $kw }
    Write-Output ("--- {0}  ({1} 个)" -f $r, @($hits).Count)
    foreach ($h in $hits) { Write-Output ("    " + ($h.FullName.Substring($r.Length + 1))) }
}

Write-Output ''
Write-Output '===== C. SOV 小图  (gfx/interface/ideas/**) ====='
foreach ($r in $ROOTS) {
    $p = Join-Path $r 'gfx\interface\ideas'
    if (-not (Test-Path $p)) { continue }
    $hits = Get-ChildItem $p -Recurse -File -Filter *.dds | Where-Object { $_.Name -imatch 'SOV_|kalinin|tukhachevsky|pyotr_smirnov' }
    Write-Output ("--- {0}  ({1} 个)" -f $r, @($hits).Count)
    foreach ($h in $hits) { Write-Output ("    " + $h.Name) }
}

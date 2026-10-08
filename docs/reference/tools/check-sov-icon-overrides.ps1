# 检查苏联参考图标是否也存在 DLC 覆盖版（按文件名，全 root）
$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
    @{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' },
    @{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)
$names = @(
    'focus_SOV_the_supreme_soviet.dds', 'focus_SOV_builder_of_the_red_army.dds',
    'focus_SOV_the_path_of_marxism_leninism.dds', 'focus_SOV_socialism_in_one_country.dds',
    'focus_SOV_ally_bukharinists.dds', 'focus_SOV_ally_zinovyevists.dds',
    'focus_SOV_organize_wreckers.dds', 'focus_SOV_breadbasket_of_the_union.dds',
    'focus_SOV_military_purge.dds', 'focus_SOV_the_last_purge.dds',
    'focus_SOV_approach_tukahchevsky.dds', 'focus_SOV_the_comecon.dds'
)
foreach ($n in $names) {
    Write-Host "==== $n"
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r.Dir)) { continue }
        $hit = Get-ChildItem -LiteralPath $r.Dir -Recurse -File -Filter $n -ErrorAction SilentlyContinue
        foreach ($h in $hit) {
            Write-Host ("  [{0,-6}] {1}  ({2} B)" -f $r.Tag, $h.FullName, $h.Length)
        }
    }
}

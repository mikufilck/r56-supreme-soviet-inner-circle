# =============================================================================
# SOP 第 0 步（续）：把季诺维也夫的现成内容摊开，判定「有没有成体系的线」
# =============================================================================
$ErrorActionPreference = 'Continue'

$van = 'F:\Hearts of Iron IV'
$r56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

$jobs = @(
    @{ Tag = '原版 角色块 SOV_grigory_zinovyev'; File = "$van\common\characters\SOV.txt";                            Pat = 'SOV_grigory_zinovyev = \{'; Before = 2;  After = 45 },
    @{ Tag = '原版 领袖特质 #ZINOVYEV';          File = "$van\common\country_leader\00_traits.txt";                 Pat = '#ZINOVYEV';                 Before = 3;  After = 30 },
    @{ Tag = 'R56 角色块（覆盖版？）';            File = "$r56\common\characters\SOV.txt";                            Pat = 'SOV_grigory_zinovyev';      Before = 2;  After = 40 },
    @{ Tag = 'R56 领袖特质 #ZINOVYEV';           File = "$r56\common\country_leader\00_traits.txt";                 Pat = '#ZINOVYEV';                 Before = 3;  After = 30 },
    @{ Tag = '原版 民族精神 idea_SOV_grigory_zinovyev'; File = "$van\common\ideas\SOV.txt";                          Pat = 'idea_SOV_grigory_zinovyev|SOV_grigory_zinovyev'; Before = 2; After = 25 },
    @{ Tag = '原版 季诺维也夫派国策簇';           File = "$van\common\national_focus\soviet.txt";                    Pat = 'zinovyevists|zinovyevite';  Before = 8;  After = 55 },
    @{ Tag = 'R56 季诺维也夫派国策簇';            File = "$r56\common\national_focus\soviet.txt";                    Pat = 'zinovyevists|zinovyevite';  Before = 8;  After = 55 },
    @{ Tag = '原版 角色引用处（谁排掉他）';        File = "$van\common\scripted_effects\SOV_scripted_effects.txt";     Pat = 'SOV_grigory_zinovyev';      Before = 8;  After = 20 }
)

$out = @()
foreach ($j in $jobs) {
    $out += '================================================================'
    $out += "  $($j.Tag)"
    $out += "  $($j.File)"
    $out += '================================================================'
    if (-not (Test-Path $j.File)) { $out += '  (文件不存在)'; $out += ''; continue }
    $m = @(Select-String -LiteralPath $j.File -Pattern $j.Pat -ErrorAction SilentlyContinue | Select-Object -First 4)
    if ($m.Count -eq 0) { $out += '  (未命中)'; $out += ''; continue }
    $lines = [System.IO.File]::ReadAllLines($j.File)
    foreach ($hit in $m) {
        $s = [Math]::Max(0, $hit.LineNumber - 1 - $j.Before)
        $e = [Math]::Min($lines.Count - 1, $hit.LineNumber - 1 + $j.After)
        $out += ("  --- 命中于 L{0} ---" -f $hit.LineNumber)
        for ($i = $s; $i -le $e; $i++) { $out += ('  {0,6}  {1}' -f ($i + 1), $lines[$i]) }
        $out += ''
    }
}

# 这些国策 id 到底定义在哪个文件（原版可能拆在别的 focus 文件里）
$out += '================================================================'
$out += '  这些 id 定义在哪（全 national_focus 目录扫）'
$out += '================================================================'
foreach ($id in @('SOV_ally_zinovyevists','SOV_zinovyevists','SOV_purge_zinovyevists','SOV_the_zinovyevite_terrorist_center')) {
    foreach ($root in @(@{N='原版';P=$van}, @{N='R56';P=$r56})) {
        $d = Join-Path $root.P 'common\national_focus'
        if (-not (Test-Path $d)) { continue }
        $files = @(Get-ChildItem -LiteralPath $d -Recurse -File -Filter '*.txt' | Select-Object -ExpandProperty FullName)
        $m = @(Select-String -Path $files -Pattern ("id = " + $id) -ErrorAction SilentlyContinue)
        foreach ($x in $m) { $out += ('  [{0}] {1}  L{2}' -f $root.N, $x.Path.Replace($root.P + '\', ''), $x.LineNumber) }
    }
}
$out += ''

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 's0-zin-detail.txt') -Encoding utf8
Write-Host ('输出 ' + $out.Count + ' 行 -> build/s0-zin-detail.txt')

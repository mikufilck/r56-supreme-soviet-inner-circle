# SOP 第 0 步（续）：把命中的现成内容摊开看，判定「有没有成体系的线」
$ErrorActionPreference = 'Continue'

$jobs = @(
    @{ Tag = '原版 soviet.txt  #Rykov';        File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';                    Pat = '#Rykov';  Before = 6;  After = 40 },
    @{ Tag = '原版 推广为领袖的效果';           File = 'F:\Hearts of Iron IV\common\scripted_effects\SOV_scripted_effects.txt';   Pat = 'SOV_promote_to_country_leader_rykov'; Before = 2; After = 25 },
    @{ Tag = '原版 领袖特质 #RYKOV';            File = 'F:\Hearts of Iron IV\common\country_leader\00_traits.txt';                Pat = '#RYKOV'; Before = 2; After = 22 },
    @{ Tag = '原版 角色块';                     File = 'F:\Hearts of Iron IV\common\characters\SOV.txt';                          Pat = 'SOV_aleksey_rykov = \{'; Before = 1; After = 30 },
    @{ Tag = 'R56 soviet.txt #Rykov';          File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet.txt'; Pat = '#Rykov'; Before = 6; After = 40 },
    @{ Tag = 'R56 领袖特质 #RYKOV';            File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\country_leader\00_traits.txt'; Pat = '#RYKOV'; Before = 2; After = 22 }
)

$out = @()
foreach ($j in $jobs) {
    $out += "================================================================"
    $out += "  $($j.Tag)"
    $out += "  $($j.File)"
    $out += "================================================================"
    if (-not (Test-Path $j.File)) { $out += '  (文件不存在)'; $out += ''; continue }
    $m = Select-String -LiteralPath $j.File -Pattern $j.Pat -ErrorAction SilentlyContinue | Select-Object -First 3
    if (-not $m) { $out += '  (未命中)'; $out += ''; continue }
    $lines = [System.IO.File]::ReadAllLines($j.File)
    foreach ($hit in $m) {
        $s = [Math]::Max(0, $hit.LineNumber - 1 - $j.Before)
        $e = [Math]::Min($lines.Count - 1, $hit.LineNumber - 1 + $j.After)
        $out += ("  --- 命中于 L{0} ---" -f $hit.LineNumber)
        for ($i = $s; $i -le $e; $i++) { $out += ('  {0,6}  {1}' -f ($i + 1), $lines[$i]) }
        $out += ''
    }
    $out += ''
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 's0-rykov-detail.txt') -Encoding utf8
Write-Host ('输出 ' + $out.Count + ' 行')

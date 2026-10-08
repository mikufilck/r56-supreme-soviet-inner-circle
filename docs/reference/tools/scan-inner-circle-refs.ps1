# 定点搜索核心圈相关标识（避开 -Include/-LiteralPath 的坑，只扫相关目录）
$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
    @{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' }
)
$subs = @('common\dynamic_modifiers', 'common\scripted_effects', 'common\scripted_triggers',
          'common\scripted_localisation', 'common\national_focus', 'common\ideas', 'events')
$needles = @('GER_the_inner_circle_dm', 'GER_ascended_advisor', 'GER_inner_circle_set_ascension_cd',
             'GER_inner_circle_is_ascension_cd_over', 'GER_ascending_advisor')

foreach ($r in $roots) {
    $files = New-Object System.Collections.ArrayList
    foreach ($s in $subs) {
        $d = Join-Path $r.Dir $s
        if (-not (Test-Path -LiteralPath $d)) { continue }
        Get-ChildItem -LiteralPath $d -Recurse -File | Where-Object { $_.Extension -eq '.txt' } |
            ForEach-Object { [void]$files.Add($_.FullName) }
    }
    Write-Host "######## [$($r.Tag)] 待扫文件数 = $($files.Count)"
    if ($files.Count -eq 0) { continue }
    foreach ($n in $needles) {
        $hits = Select-String -Path $files -SimpleMatch -Pattern $n
        Write-Host "  ====== $n  ($($hits.Count) 处)"
        foreach ($h in $hits) {
            Write-Host ("      " + $h.Path.Substring($r.Dir.Length).TrimStart('\') + "  L" + $h.LineNumber + " : " + $h.Line.Trim())
        }
    }
    Write-Host ''
}

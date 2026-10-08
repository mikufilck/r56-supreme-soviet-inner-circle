# 找出德国核心圈事件文件，并导出关键块
$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
    @{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' }
)

Write-Host '################ A) 含 GER_inner_circle 的事件文件'
foreach ($r in $roots) {
    $d = Join-Path $r.Dir 'events'
    if (-not (Test-Path -LiteralPath $d)) { continue }
    Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt | ForEach-Object {
        $t = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        if ($t -match 'GER_inner_circle') {
            $n = ([regex]::Matches($t, 'GER_inner_circle')).Count
            Write-Host ("  [{0}] {1}   （{2} 处）" -f $r.Tag, $_.FullName.Substring($r.Dir.Length).TrimStart('\'), $n)
        }
    }
}

Write-Host "`n################ B) 冷却相关脚本效果/触发器"
$targets = @('GER_inner_circle_set_ascension_cd', 'GER_inner_circle_is_ascension_cd_over')
foreach ($r in $roots) {
    foreach ($s in @('common\scripted_effects', 'common\scripted_triggers')) {
        $d = Join-Path $r.Dir $s
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in (Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt)) {
            $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8
            for ($i = 0; $i -lt $lines.Count; $i++) {
                foreach ($t in $targets) {
                    if ($lines[$i] -match ("^\s*" + [regex]::Escape($t) + "\s*=\s*\{")) {
                        $depth = 0; $e = $i
                        for ($j = $i; $j -lt $lines.Count; $j++) {
                            $depth += ([regex]::Matches($lines[$j], '\{')).Count
                            $depth -= ([regex]::Matches($lines[$j], '\}')).Count
                            if ($depth -eq 0) { $e = $j; break }
                        }
                        Write-Host ("  --- [{0}] {1}  L{2}..L{3}" -f $r.Tag, $f.FullName.Substring($r.Dir.Length).TrimStart('\'), ($i + 1), ($e + 1))
                        for ($j = $i; $j -le $e; $j++) { Write-Host ("      " + $lines[$j]) }
                        Write-Host ''
                    }
                }
            }
        }
    }
}

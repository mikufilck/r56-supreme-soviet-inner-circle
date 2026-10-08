# 找 GER_the_inner_circle_dm 的定义并整块导出
$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
    @{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' }
)
$target = 'GER_the_inner_circle_dm'

foreach ($r in $roots) {
    $d = Join-Path $r.Dir 'common\dynamic_modifiers'
    if (-not (Test-Path -LiteralPath $d)) { continue }
    foreach ($f in (Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt)) {
        $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match ("^\s*" + [regex]::Escape($target) + "\s*=\s*\{")) {
                $depth = 0; $e = $i
                for ($j = $i; $j -lt $lines.Count; $j++) {
                    $depth += ([regex]::Matches($lines[$j], '\{')).Count
                    $depth -= ([regex]::Matches($lines[$j], '\}')).Count
                    if ($depth -eq 0) { $e = $j; break }
                }
                Write-Host "################ [$($r.Tag)] $($f.FullName)  (L$($i+1)..L$($e+1))"
                for ($j = $i; $j -le $e; $j++) { Write-Host $lines[$j] }
                Write-Host ''
            }
        }
    }
}

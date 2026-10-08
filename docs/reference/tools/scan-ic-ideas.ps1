# 打印德国核心圈的角色专属 idea，作为我们核心圈 idea 的【修正词条模板】。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-ic-ideas.ps1

$roots = @(
    "F:\Hearts of Iron IV",
    "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125"
)
$ids = @(
    'GER_todt_reich_engineer', 'GER_organization_todt', 'GER_speer_reich_architect',
    'GER_goring_overseer_four_year_plan', 'GER_himmler_chief_of_german_police',
    'GER_goebbels_reich_minister_of_propaganda', 'GER_hess_party_chancellor',
    'GER_bormann_secretary_to_the_fuhrer', 'GER_walter_dornberger'
)

foreach ($r in $roots) {
    $d = Join-Path $r "common\ideas"
    if (-not (Test-Path -LiteralPath $d)) { continue }
    foreach ($f in (Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue)) {
        $lines = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        for ($i = 0; $i -lt $lines.Count; $i++) {
            foreach ($id in $ids) {
                if ($lines[$i] -match ("^\s*" + [regex]::Escape($id) + "\s*=\s*\{")) {
                    $src = if ($f.FullName.StartsWith("F:\")) { "原版" } else { "R56 " }
                    Write-Host ("`n======== [{0}] {1}  {2} L{3} ========" -f $src, $f.Name, $id, ($i + 1))
                    # 块尾
                    $depth = 0; $end = $i
                    for ($j = $i; $j -lt [Math]::Min($i + 60, $lines.Count); $j++) {
                        $depth += ([regex]::Matches($lines[$j], '\{')).Count
                        $depth -= ([regex]::Matches($lines[$j], '\}')).Count
                        if ($j -gt $i -and $depth -le 0) { $end = $j; break }
                    }
                    for ($j = $i; $j -le $end; $j++) { $lines[$j] }
                }
            }
        }
    }
}

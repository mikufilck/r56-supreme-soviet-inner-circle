# 挖德国核心圈用的脚本常量与样式，作为我们核心圈个人线的成本基准。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-ic-consts.ps1

$roots = @(
    "F:\Hearts of Iron IV",
    "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125"
)
$needles = @('inner_circle_time_tier', 'inner_circle_focus_style', 'inner_circle_days_to_start_focus', 'inner_circle_random_days')

foreach ($n in $needles) {
    Write-Host "`n=== $n ==="
    $hit = 0
    foreach ($r in $roots) {
        if (-not (Test-Path -LiteralPath $r)) { continue }
        $files = Get-ChildItem -LiteralPath $r -Recurse -File -Include *.txt -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            try { $ls = Get-Content -LiteralPath $f.FullName -Encoding UTF8 -ErrorAction Stop } catch { continue }
            for ($i = 0; $i -lt $ls.Count; $i++) {
                if ($ls[$i] -match $n) {
                    $rel = $f.FullName.Substring($r.Length).TrimStart('\')
                    "{0,-70} L{1,-6} {2}" -f $rel, ($i + 1), $ls[$i].Trim()
                    $hit++
                    if ($hit -ge 25) { break }
                }
            }
            if ($hit -ge 25) { break }
        }
        if ($hit -ge 25) { break }
    }
    if ($hit -eq 0) { Write-Host "  (无命中)" }
}

Write-Host "`n=== 相关 script_constants 文件 ==="
foreach ($r in $roots) {
    $d = Join-Path $r "common\script_constants"
    if (Test-Path -LiteralPath $d) {
        Write-Host "--- $d"
        Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue | ForEach-Object { "    " + $_.Name }
    }
}

# 打印指定的苏联角色块，看他们有没有可用身份（将领/顾问/首脑）。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-officer-roles.ps1

$target = "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\characters\SOV.txt"
if (-not (Test-Path -LiteralPath $target)) { Write-Host "找不到 R56 SOV.txt"; exit 1 }

$ids = @(
    'SOV_boris_shaposhnikov', 'SOV_aleksandr_yegorov', 'SOV_mikhail_tukhachevsky',
    'SOV_august_kork', 'SOV_aleksandr_verkhovsky', 'SOV_aleksandr_prokofyev_seversky',
    'SOV_konstantin_rodzayevsky', 'SOV_vasily_blyukher', 'SOV_aleksandr_verkhovsky',
    'SOV_lev_trotsky'
) | Select-Object -Unique

$lines = Get-Content -LiteralPath $target -Encoding UTF8
Write-Host "文件行数: $($lines.Count)`n"

foreach ($id in $ids) {
    $start = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ("^\s*" + [regex]::Escape($id) + "\s*=\s*\{")) { $start = $i; break }
    }
    Write-Host ("======== {0}  (L{1}) ========" -f $id, ($start + 1))
    if ($start -lt 0) { Write-Host "  ！未找到"; continue }

    # 缩进计数求块尾
    $depth = 0; $end = $start
    for ($i = $start; $i -lt [Math]::Min($start + 200, $lines.Count); $i++) {
        $depth += ([regex]::Matches($lines[$i], '\{')).Count
        $depth -= ([regex]::Matches($lines[$i], '\}')).Count
        if ($i -gt $start -and $depth -le 0) { $end = $i; break }
    }

    # 只打印关键字段
    for ($i = $start; $i -le $end; $i++) {
        $l = $lines[$i]
        if ($l -match '^\s*(name|portraits|corps_commander|field_marshal|navy_leader|advisor|country_leader|is_female|gender|soviet_general|skill|attack_skill|defense_skill|planning_skill|logistics_skill|traits|corps_commander\s*=\s*\{)\s*=') { $l }
    }
    Write-Host ("  (块 L{0}-L{1}, 共 {2} 行)`n" -f ($start + 1), ($end + 1), ($end - $start + 1))
}

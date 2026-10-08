# 打印德国核心圈的「汇合国策」（分支走完后合并给强力 buff 的那种）。
# 用法: powershell -NoProfile -ExecutionPolicy Bypass -File docs/reference/scan-ic-merge.ps1

$g = "D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\germany.txt"
$lines = Get-Content -LiteralPath $g -Encoding UTF8
$targets = @('GER_a_strong_successor', 'GER_loyalty_to_the_fuhrer', 'GER_hegemony_of_the_ss', 'GER_fuhrerprinzip', 'GER_form_organization_todt')

foreach ($t in $targets) {
    $hit = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ("^\s*id\s*=\s*" + [regex]::Escape($t) + "\s*$")) { $hit = $i; break }
    }
    Write-Host "`n======== $t  (L$($hit+1)) ========"
    if ($hit -lt 0) { Write-Host "  未找到"; continue }
    # 找到该 focus 块的结束（缩进法）
    $depth = 0; $end = $hit
    for ($i = $hit; $i -lt [Math]::Min($hit + 120, $lines.Count); $i++) {
        $depth += ([regex]::Matches($lines[$i], '\{')).Count
        $depth -= ([regex]::Matches($lines[$i], '\}')).Count
        if ($depth -le 0 -and $i -gt $hit) { $end = $i; break }
    }
    # 只打印关键字段，跳过 available 里的长篇 tooltip
    for ($i = $hit; $i -le $end; $i++) {
        $l = $lines[$i]
        if ($l -match '^\s*(id|icon|prerequisite|mutually_exclusive|relative_position_id|x|y|cost|search_filters|text_icon|cancel_if_invalid|continue_if_invalid)\s*=') { $l }
        if ($l -match 'completion_reward\s*=\s*\{') { $l; Write-Host "        ...[奖励正文]..." }
    }
    Write-Host "  (块范围 L$($hit+1)-L$($end+1))"
}

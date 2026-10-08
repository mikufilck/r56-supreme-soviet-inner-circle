# 从 WUW_Germany.txt 里导出指定事件的完整块（先回退到外层 country_event = { 再配平）
$ErrorActionPreference = 'SilentlyContinue'
$f = 'F:\Hearts of Iron IV\events\WUW_Germany.txt'
if (-not (Test-Path -LiteralPath $f)) { Write-Host "找不到 $f"; exit }
$lines = Get-Content -LiteralPath $f -Encoding UTF8
Write-Host "总行数 = $($lines.Count)"

$ids = @('GER_inner_circle_todt.02', 'GER_inner_circle.02')

foreach ($id in $ids) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch ("^\s*id\s*=\s*" + [regex]::Escape($id) + "\s*$")) { continue }
        # 回退到最近的外层事件起头
        $b = $i
        while ($b -ge 0 -and $lines[$b] -notmatch '^\s*(country_event|news_event|state_event|unit_leader_event)\s*=\s*\{') { $b-- }
        $depth = 0; $e = $i
        for ($j = $b; $j -lt $lines.Count; $j++) {
            $depth += ([regex]::Matches($lines[$j], '\{')).Count
            $depth -= ([regex]::Matches($lines[$j], '\}')).Count
            if ($depth -eq 0 -and $j -gt $b) { $e = $j; break }
        }
        Write-Host "`n======== $id   (L$($b+1)..L$($e+1)) ========"
        for ($j = $b; $j -le $e; $j++) { Write-Host $lines[$j] }
    }
}

# 1) 抽取德国核心圈相关国策块原文（括号配平）  2) 找相关的 dynamic_modifier 定义
$ErrorActionPreference = 'SilentlyContinue'

$roots = [ordered]@{
    'R56'  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
    '原版' = 'F:\Hearts of Iron IV'
}

$ids = @(
    'GER_fuhrerprinzip',
    'GER_ascension_of_todt',
    'GER_form_organization_todt',
    'GER_todt_reich_engineer',
    'GER_a_strong_successor',
    'GER_loyalty_to_the_fuhrer'
)

foreach ($tag in $roots.Keys) {
    $f = Join-Path $roots[$tag] 'common\national_focus\germany.txt'
    if (-not (Test-Path -LiteralPath $f)) { continue }
    Write-Host "################ $tag : $f"
    $lines = Get-Content -LiteralPath $f -Encoding UTF8
    Write-Host ("     总行数: " + $lines.Count)

    foreach ($id in $ids) {
        $start = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match ("^\s*id\s*=\s*" + [regex]::Escape($id) + "\s*$")) { $start = $i; break }
        }
        if ($start -lt 0) { Write-Host "`n  --- $id : 未找到"; continue }
        # 从 id 行向前找 focus = {
        $b = $start
        while ($b -ge 0 -and $lines[$b] -notmatch '^\s*focus\s*=\s*\{') { $b-- }
        # 从 focus = { 向后配平括号
        $depth = 0; $e = $b
        for ($j = $b; $j -lt $lines.Count; $j++) {
            $depth += ([regex]::Matches($lines[$j], '\{')).Count
            $depth -= ([regex]::Matches($lines[$j], '\}')).Count
            if ($depth -eq 0) { $e = $j; break }
        }
        Write-Host "`n======== $id   (L$($b+1)..L$($e+1)) ========"
        for ($j = $b; $j -le $e; $j++) { Write-Host $lines[$j] }
    }
    break   # 只处理第一个存在的（R56 优先）
}

Write-Host "`n`n################ dynamic_modifiers 文件清单"
foreach ($tag in $roots.Keys) {
    $d = Join-Path $roots[$tag] 'common\dynamic_modifiers'
    if (-not (Test-Path -LiteralPath $d)) { Write-Host "  [$tag] 无 $d"; continue }
    Write-Host "  --- [$tag] $d"
    Get-ChildItem -LiteralPath $d -Recurse -File | ForEach-Object { Write-Host ("      " + $_.Name) }
}

Write-Host "`n################ dynamic_modifiers 里含 GER / inner_circle / fuhrer / ascension 的文件"
foreach ($tag in $roots.Keys) {
    $d = Join-Path $roots[$tag] 'common\dynamic_modifiers'
    if (-not (Test-Path -LiteralPath $d)) { continue }
    Get-ChildItem -LiteralPath $d -Recurse -File -Filter *.txt | ForEach-Object {
        $t = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
        if ($t -match 'inner_circle|fuhrerprinzip|ascension|GER_') {
            Write-Host ("  [$tag] " + $_.FullName)
        }
    }
}

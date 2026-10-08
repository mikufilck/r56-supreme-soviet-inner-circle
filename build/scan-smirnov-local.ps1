# 本地语料里「斯米尔诺夫」的命中：逐条带上下文，便于分人（4 个斯米尔诺夫）
$ErrorActionPreference = 'Continue'
$root = Join-Path $PSScriptRoot '..\tmp'
$o = @()
$o += '=== 本地 tmp/ 语料中「斯米尔」命中（含上下文，用于分人）==='
$files = Get-ChildItem -LiteralPath $root -Recurse -File -Include *.txt, *.md -ErrorAction SilentlyContinue
$total = 0
$byDir = @{}
foreach ($f in $files) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName, [System.Text.Encoding]::UTF8)
    $hits = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '斯米尔') {
            $c = $lines[$i].Trim()
            if ($c.Length -gt 180) { $c = $c.Substring(0, 180) + '…' }
            $hits += ('    L{0,-6} {1}' -f ($i + 1), $c)
        }
    }
    if ($hits.Count -gt 0) {
        $rel = $f.FullName.Substring($root.Length + 1)
        $o += ''
        $o += ('--- {0}  （{1} 处）' -f $rel, $hits.Count)
        $o += $hits
        $total += $hits.Count
        $d = ($rel -split '\\')[0]
        if (-not $byDir.ContainsKey($d)) { $byDir[$d] = 0 }
        $byDir[$d] += $hits.Count
    }
}
$o = @('=== 合计 {0} 处 ===' -f $total) + ($byDir.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object { '  {0,-14} {1}' -f $_.Key, $_.Value }) + $o
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'smirnov-local-hits.txt'), $o, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('合计 {0} 处 -> build\smirnov-local-hits.txt' -f $total)

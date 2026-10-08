# 列出所有含 armor / tank / combat_width / slot 的 token（跨两份报告）
$ErrorActionPreference = 'Stop'

$files = @(
    (Join-Path $PSScriptRoot '..\docs\reference\reports\modifier-words-2.txt'),
    (Join-Path $PSScriptRoot '..\docs\reference\reports\modifier-words-3.txt')
)

foreach ($f in $files) {
    if (-not (Test-Path -LiteralPath $f)) { continue }
    Write-Output "===== $(Split-Path $f -Leaf) ====="
    foreach ($l in [System.IO.File]::ReadAllLines($f)) {
        if ($l -match '^\| `([a-z0-9_]+)` \| (\d+) \|') {
            $t = $Matches[1]
            if ($t -match 'armor|tank|panzer') { Write-Output ("  {0,-70} x{1}" -f $t, $Matches[2]) }
        }
    }
    Write-Output ''
}

Write-Output '===== combat_width 用在哪（是否出现在 ideas / dynamic_modifiers）====='
foreach ($r in @('D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125',
                 'F:\Hearts of Iron IV')) {
    foreach ($sd in @('common\ideas', 'common\dynamic_modifiers', 'common\unit_leader', 'common\combat_tactics')) {
        $d = Join-Path $r $sd
        if (-not (Test-Path -LiteralPath $d)) { continue }
        foreach ($f in Get-ChildItem -LiteralPath $d -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
            $lines = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^\s*combat_width\s*=') {
                    $rel = $f.FullName.Replace($r, '').TrimStart('\')
                    Write-Output ("  $rel : $($i+1)   " + $lines[$i].Trim())
                }
            }
        }
    }
}

Write-Output ''
Write-Output '===== 资源 / 建筑位 相关 token（全量）====='
foreach ($l in [System.IO.File]::ReadAllLines($files[1])) {
    if ($l -match '^\| `([a-z0-9_]+)` \| (\d+) \|') {
        $t = $Matches[1]
        if ($t -match 'resources|slots|building') { Write-Output ("  {0,-70} x{1}" -f $t, $Matches[2]) }
    }
}

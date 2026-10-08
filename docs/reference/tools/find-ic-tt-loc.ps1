# 只在 localisation 目录里找 GER_the_inner_circle_dm_tt（含 dlc 下的 localisation）
$ErrorActionPreference = 'SilentlyContinue'
$bases = @('F:\Hearts of Iron IV', 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125')
foreach ($b in $bases) {
    $ldirs = New-Object System.Collections.ArrayList
    $d = Join-Path $b 'localisation'
    if (Test-Path -LiteralPath $d) { [void]$ldirs.Add($d) }
    $dlc = Join-Path $b 'dlc'
    if (Test-Path -LiteralPath $dlc) {
        Get-ChildItem -LiteralPath $dlc -Directory | ForEach-Object {
            $x = Join-Path $_.FullName 'localisation'
            if (Test-Path -LiteralPath $x) { [void]$ldirs.Add($x) }
        }
    }
    Write-Host "######## $b  (localisation 目录数 = $($ldirs.Count))"
    foreach ($ld in $ldirs) {
        $files = Get-ChildItem -LiteralPath $ld -Recurse -File | Where-Object { $_.Extension -eq '.yml' }
        if ($files.Count -eq 0) { continue }
        $hits = Select-String -Path $files.FullName -SimpleMatch -Pattern 'GER_the_inner_circle_dm_tt' -Encoding UTF8
        foreach ($h in $hits) {
            Write-Host ("  " + $h.Path)
            Write-Host ("    L" + $h.LineNumber + ": " + $h.Line.Trim())
        }
    }
    Write-Host ''
}

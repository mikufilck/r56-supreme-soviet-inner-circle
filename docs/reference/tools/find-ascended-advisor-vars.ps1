# 找 GetAscendedAdvisor1 / GetAscendedAdvisorDesc1 的定义（遍历所有名含 scripted_localisation 的目录，含 dlc）
$ErrorActionPreference = 'SilentlyContinue'
$roots = @('F:\Hearts of Iron IV', 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125')
$needles = @('GetAscendedAdvisor1', 'GetAscendedAdvisorDesc1', 'GetAscendedAdvisorTrait1')

foreach ($b in $roots) {
    Write-Host "################ $b"
    $dirs = Get-ChildItem -LiteralPath $b -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq 'scripted_localisation' }
    Write-Host "  找到 scripted_localisation 目录 $($dirs.Count) 个"
    foreach ($d in $dirs) {
        $files = Get-ChildItem -LiteralPath $d.FullName -File | Where-Object { $_.Extension -eq '.txt' }
        if ($files.Count -eq 0) { continue }
        foreach ($n in $needles) {
            $hits = Select-String -Path $files.FullName -SimpleMatch -Pattern ("name = " + $n) -Encoding UTF8
            foreach ($h in $hits) {
                Write-Host ("  [{0}] {1}  L{2}" -f $n, $h.Path.Substring($b.Length).TrimStart('\'), $h.LineNumber)
                $lines = Get-Content -LiteralPath $h.Path -Encoding UTF8
                $i = $h.LineNumber - 1
                $b2 = $i
                while ($b2 -ge 0 -and $lines[$b2] -notmatch 'defined_text\s*=\s*\{') { $b2-- }
                $depth = 0; $e = $b2
                for ($j = $b2; $j -lt $lines.Count; $j++) {
                    $depth += ([regex]::Matches($lines[$j], '\{')).Count
                    $depth -= ([regex]::Matches($lines[$j], '\}')).Count
                    if ($depth -eq 0 -and $j -gt $b2) { $e = $j; break }
                }
                for ($j = $b2; $j -le [Math]::Min($e, $b2 + 40); $j++) { Write-Host ("      " + $lines[$j]) }
                if ($e - $b2 -gt 40) { Write-Host "      ... (块更长，共 $($e-$b2+1) 行)" }
                Write-Host ''
            }
        }
    }
}

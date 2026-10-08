# 找 GetAscendedAdvisor1/2/3 的 defined_text 定义
$ErrorActionPreference = 'SilentlyContinue'
$roots = @(
    @{ Tag = 'R56'; Dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' },
    @{ Tag = '原版'; Dir = 'F:\Hearts of Iron IV' }
)
foreach ($r in $roots) {
    $d = Join-Path $r.Dir 'common\scripted_localisation'
    if (-not (Test-Path -LiteralPath $d)) { Write-Host "[$($r.Tag)] 无 $d"; continue }
    Write-Host "######## [$($r.Tag)] $d"
    Get-ChildItem -LiteralPath $d -Recurse -File | Where-Object { $_.Extension -eq '.txt' } | ForEach-Object {
        $lines = Get-Content -LiteralPath $_.FullName -Encoding UTF8
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'GetAscendedAdvisor') {
                Write-Host ("  {0}  L{1}" -f $_.FullName.Substring($r.Dir.Length).TrimStart('\'), ($i + 1))
                # 往上找 defined_text 起头
                $b = $i
                while ($b -ge 0 -and $lines[$b] -notmatch 'defined_text\s*=\s*\{') { $b-- }
                $depth = 0; $e = $b
                for ($j = $b; $j -lt $lines.Count; $j++) {
                    $depth += ([regex]::Matches($lines[$j], '\{')).Count
                    $depth -= ([regex]::Matches($lines[$j], '\}')).Count
                    if ($depth -eq 0 -and $j -gt $b) { $e = $j; break }
                }
                Write-Host "  ---- 定义块 L$($b+1)..L$($e+1)"
                for ($j = $b; $j -le $e; $j++) { Write-Host ("      " + $lines[$j]) }
                Write-Host ''
            }
        }
    }
}

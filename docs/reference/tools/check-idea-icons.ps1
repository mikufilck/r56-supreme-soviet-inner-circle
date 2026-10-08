# 1) 找可用的 idea 图标 sprite（communism / political 系列）
# 2) 确认 clear_variable 效果是否存在
$ErrorActionPreference = 'SilentlyContinue'
$roots = @('F:\Hearts of Iron IV', 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125')

Write-Host '################ A) 候选 idea 图标 sprite'
$pat = 'GFX_idea_generic_(communism|political|soviet)[A-Za-z0-9_]*'
$seen = @{}
foreach ($b in $roots) {
    foreach ($sub in @('interface', 'gfx\interface')) {
        $d = Join-Path $b $sub
        if (-not (Test-Path -LiteralPath $d)) { continue }
        Get-ChildItem -LiteralPath $d -Recurse -File | Where-Object { $_.Extension -eq '.gfx' } | ForEach-Object {
            $t = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
            foreach ($m in [regex]::Matches($t, ('name\s*=\s*"' + $pat + '"'))) {
                $n = [regex]::Match($m.Value, '"[^"]+"').Value.Trim('"')
                if (-not $seen.ContainsKey($n)) { $seen[$n] = $_.FullName.Substring($b.Length).TrimStart('\') }
            }
        }
    }
}
$seen.Keys | Sort-Object | ForEach-Object { Write-Host ("  {0,-58} {1}" -f $_, $seen[$_]) }

Write-Host "`n################ B) clear_variable / clear_array / set_variable 文档"
$f = 'F:\Hearts of Iron IV\documentation\effects_documentation.md'
$lines = Get-Content -LiteralPath $f -Encoding UTF8
foreach ($w in @('clear_variable', 'set_variable')) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ("^##\s+" + [regex]::Escape($w) + "\s*$")) {
            Write-Host "======== $w  (L$($i+1))"
            for ($j = $i; $j -lt [Math]::Min($i + 26, $lines.Count); $j++) {
                if ($j -gt $i -and $lines[$j] -match '^##\s') { break }
                Write-Host $lines[$j]
            }
            Write-Host ''
        }
    }
}

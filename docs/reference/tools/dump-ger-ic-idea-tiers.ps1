# Dump the modifier blocks of ALL tiers of the German Inner Circle office ideas,
# so we can measure the INCREMENT added by each swap_ideas upgrade.
$ErrorActionPreference = 'Stop'

$roots = @(
    @{ tag = 'R56';     dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\ideas' },
    @{ tag = 'VANILLA'; dir = 'F:\Hearts of Iron IV\common\ideas' }
)

$nameRe = '^\s*(GER_(?:todt|speer|goring|himmler|goebbels|hess|bormann|reichswerke|philipp_holzmann|organization_todt|walter_dornberger|leni_riefenstahl)[A-Za-z0-9_]*)\s*=\s*\{'

function Get-BlockEnd($lines, $startIdx) {
    $depth = 0
    for ($i = $startIdx; $i -lt $lines.Count; $i++) {
        foreach ($ch in $lines[$i].ToCharArray()) {
            if ($ch -eq '{') { $depth++ }
            elseif ($ch -eq '}') { $depth--; if ($depth -eq 0) { return $i } }
        }
    }
    return -1
}

$out = New-Object System.Collections.ArrayList
[void]$out.Add("# German Inner Circle office ideas - ALL TIERS, with modifiers")
[void]$out.Add("# used to measure the per-swap INCREMENT of a personal line")
[void]$out.Add("")

foreach ($r in $roots) {
    if (-not (Test-Path -LiteralPath $r.dir)) { Write-Output "skip (missing): $($r.dir)"; continue }
    foreach ($f in Get-ChildItem -LiteralPath $r.dir -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
        if ($f.FullName -match '\\ideas\\') {
            $lines = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $lines.Count; $i++) {
                $m = [regex]::Match($lines[$i], $nameRe)
                if ($m.Success) {
                    $end = Get-BlockEnd $lines $i
                    if ($end -lt 0) { continue }
                    $block = $lines[$i..$end]
                    $nm = $m.Groups[1].Value
                    [void]$out.Add("======== [$($r.tag)] $nm   ($($f.Name) L$($i+1)) ========")
                    $inMod = $false
                    $modDepth = 0
                    foreach ($ln in $block) {
                        if (-not $inMod -and $ln -match 'modifier\s*=\s*\{') {
                            $inMod = $true
                            $modDepth = 1
                            [void]$out.Add("  modifier = {")
                            continue
                        }
                        if ($inMod) {
                            foreach ($ch in $ln.ToCharArray()) {
                                if ($ch -eq '{') { $modDepth++ }
                                elseif ($ch -eq '}') { $modDepth-- }
                            }
                            if ($modDepth -le 0) { $inMod = $false; [void]$out.Add("  }"); continue }
                            [void]$out.Add("  $($ln.TrimEnd())")
                            continue
                        }
                        if ($ln -match '(?m)^\s*(cost|picture|traits|research_bonus|allowed|visible|removal_cost|name)\s*=') {
                            [void]$out.Add("  [meta] $($ln.Trim())")
                        }
                    }
                    [void]$out.Add("")
                }
            }
        }
    }
}

$dst = Join-Path (Join-Path $PSScriptRoot '..\reports') 'ger-ic-idea-tiers.txt'
[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst ($($out.Count) lines)"

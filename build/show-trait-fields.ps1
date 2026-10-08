# 确认：unit leader trait 能否带 modifier、图标怎么指定
$ErrorActionPreference = 'Stop'

$files = @(
    'F:\Hearts of Iron IV\common\unit_leader\00_traits.txt',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\unit_leader\r56_traits.txt'
)

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

$shown = 0
foreach ($f in $files) {
    if (-not (Test-Path -LiteralPath $f)) { continue }
    $lines = [System.IO.File]::ReadAllLines($f)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*([A-Za-z][A-Za-z0-9_]*)\s*=\s*\{' -and $lines[$i] -notmatch '^\s*(modifier|allowed|gain_xp|ai_will_do|new_commander_weight|trait_type|type|sprite|effect|remove|OR|AND|NOT|FROM|ROOT|if|else)') {
            $end = Get-BlockEnd $lines $i
            if ($end -lt 0) { continue }
            $blob = ($lines[$i..$end] -join "`n")
            if ($blob -match 'modifier\s*=\s*\{' -and $blob -match '(army_|production_|research_|supply_)' ) {
                $shown++
                Write-Output ("---- $([System.IO.Path]::GetFileName($f)) L$($i+1) : " + $Matches[1] + " ----")
                $s = [Math]::Max(0, $i)
                $e = [Math]::Min($lines.Count - 1, $i + 34)
                for ($k = $s; $k -le $e; $k++) { Write-Output ("  " + $lines[$k]) }
                Write-Output ''
            }
            if ($shown -ge 2) { break }
        }
    }
    if ($shown -ge 2) { break }
}

Write-Output '===== 两处 trait 目录里出现过的字段名（含 sprite ?）====='
$fields = @{}
foreach ($f in (Get-ChildItem -LiteralPath 'F:\Hearts of Iron IV\common\unit_leader' -Filter '*.txt' -File -ErrorAction SilentlyContinue) +
               (Get-ChildItem -LiteralPath 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\unit_leader' -Filter '*.txt' -File -ErrorAction SilentlyContinue)) {
    foreach ($l in [System.IO.File]::ReadAllLines($f.FullName)) {
        $m = [regex]::Match($l, '^\s{1,3}([a-z][a-z0-9_]{2,})\s*=')
        if ($m.Success) { $fields[$m.Groups[1].Value] = 1 }
    }
}
Write-Output ("  " + (($fields.Keys | Sort-Object) -join '  '))

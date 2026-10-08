# 1) 打印 add_skill_level / add_unit_leader_trait 的真实上下文（确认作用域写法）
# 2) 打印兵种/将领两组 token，便于挑词条
$ErrorActionPreference = 'Stop'

$roots = @(
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common',
    'F:\Hearts of Iron IV\common'
)

Write-Output '===== add_skill_level 上下文（前 3 例）====='
$n = 0
foreach ($r in $roots) {
    if ($n -ge 3) { break }
    foreach ($f in Get-ChildItem -LiteralPath $r -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
        if ($n -ge 3) { break }
        $lines = [System.IO.File]::ReadAllLines($f.FullName)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'add_skill_level') {
                $n++
                Write-Output ("---- $($f.FullName) L$($i+1) ----")
                $s = [Math]::Max(0, $i - 8)
                $e = [Math]::Min($lines.Count - 1, $i + 3)
                for ($k = $s; $k -le $e; $k++) { Write-Output ("  " + $lines[$k]) }
                Write-Output ''
                if ($n -ge 3) { break }
            }
        }
    }
}

Write-Output ''
Write-Output '===== add_unit_leader_trait 上下文（前 2 例）====='
$n = 0
foreach ($r in $roots) {
    if ($n -ge 2) { break }
    foreach ($f in Get-ChildItem -LiteralPath $r -Filter '*.txt' -File -Recurse -ErrorAction SilentlyContinue) {
        if ($n -ge 2) { break }
        $lines = [System.IO.File]::ReadAllLines($f.FullName)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'add_unit_leader_trait') {
                $n++
                Write-Output ("---- $($f.FullName) L$($i+1) ----")
                $s = [Math]::Max(0, $i - 6)
                $e = [Math]::Min($lines.Count - 1, $i + 2)
                for ($k = $s; $k -le $e; $k++) { Write-Output ("  " + $lines[$k]) }
                Write-Output ''
                if ($n -ge 2) { break }
            }
        }
    }
}

Write-Output ''
Write-Output '===== 兵种进攻类 token 全表（按类型）====='
$src = Join-Path $PSScriptRoot '..\docs\reference\reports\modifier-words-2.txt'
foreach ($l in [System.IO.File]::ReadAllLines($src)) {
    if ($l -match '^\| `(modifier_army_sub_unit_[a-z0-9_]+)` \| (\d+) \|') {
        Write-Output ("  {0,-72} x{1}" -f $Matches[1], $Matches[2])
    }
}

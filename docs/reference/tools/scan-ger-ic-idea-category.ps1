# scan-ger-ic-idea-category.ps1
# ---------------------------------------------------------------------------
# 核实两件事：
#   1. 德国的「职务 idea」（GER_todt_reich_engineer 等）挂在哪个 category？
#      如果挂在某个非隐藏 category，它就会在民族精神条里显示成【独立精神】。
#   2. 容器精神 GER_the_inner_circle_dm 到底有没有数值 / 变量？在哪里被 add？
#
# 产出（建议）：docs/reference/reports/ger-ic-idea-category.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$HOI4 = 'F:\Hearts of Iron IV'

# ---------------------------------------------------------------------------
Write-Output '################################################################################'
Write-Output '# 1. 职务 idea 的祖先链（看它属于哪个 category）'
Write-Output '################################################################################'

$f = Join-Path $R56 'common\ideas\GER.txt'
$lines = [System.IO.File]::ReadAllLines($f)

$targets = @('GER_todt_reich_engineer', 'GER_himmler_chief_of_german_police', 'GER_hess_party_chancellor')

foreach ($t in $targets) {
    $found = $false
    for ($i = 0; $i -lt $lines.Count -and -not $found; $i++) {
        if ($lines[$i] -match ('^\s*' + [regex]::Escape($t) + '\s*=\s*\{')) {
            $found = $true
            $ownIndent = ([regex]::Match($lines[$i], '^\t*')).Value.Length
            Write-Output ''
            Write-Output ("### {0}   L{1}   （自身缩进 = {2} 个 Tab）" -f $t, ($i + 1), $ownIndent)
            for ($j = $i - 1; $j -ge 0; $j--) {
                $mm = [regex]::Match($lines[$j], '^(\t*)([A-Za-z_0-9]+)\s*=\s*\{')
                if ($mm.Success) {
                    $ind = $mm.Groups[1].Value.Length
                    if ($ind -lt $ownIndent) {
                        Write-Output ("     ↑ 祖先（缩进 {0}）：L{1}  {2}" -f $ind, ($j + 1), $lines[$j].Trim())
                        $ownIndent = $ind
                        if ($ind -eq 0) { break }
                    }
                }
            }
        }
    }
    if (-not $found) { Write-Output ("### {0}  —— 本文件里没找到" -f $t) }
}

Write-Output ''
Write-Output '### 该文件里所有「缩进 0 或 1 个 Tab」的块头（即 category 与顶层块）'
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^(\t{0,1})([A-Za-z_0-9]+)\s*=\s*\{\s*$') {
        Write-Output ("  L{0}: {1}" -f ($i + 1), $lines[$i].Trim())
    }
}

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '################################################################################'
Write-Output '# 2. 容器精神 GER_the_inner_circle_dm：有没有数值？在哪里被 add？'
Write-Output '################################################################################'

$dirs = @('common', 'events', 'history')
foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    foreach ($d in $dirs) {
        $p = Join-Path $root $d
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem $p -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue | ForEach-Object {
            $ff = $_.FullName
            $ls = [System.IO.File]::ReadAllLines($ff)
            for ($i = 0; $i -lt $ls.Count; $i++) {
                if ($ls[$i] -like '*GER_the_inner_circle_dm*') {
                    Write-Output ("[{0}] {1} L{2}: {3}" -f $label, $ff.Replace($root + '\', ''), ($i + 1), $ls[$i].Trim())
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '################################################################################'
Write-Output '# 3. GER_the_inner_circle_dm_tt 本地化原文（看这个名字是怎么来的）'
Write-Output '################################################################################'

foreach ($root in @($HOI4, $R56)) {
    $p = Join-Path $root 'localisation'
    if (-not (Test-Path $p)) { continue }
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    Get-ChildItem $p -Recurse -File -Filter *.yml -ErrorAction SilentlyContinue | ForEach-Object {
        $ff = $_.FullName
        $ls = [System.IO.File]::ReadAllLines($ff)
        for ($i = 0; $i -lt $ls.Count; $i++) {
            if ($ls[$i] -match 'GER_the_inner_circle_dm') {
                Write-Output ("[{0}] {1} L{2}: {3}" -f $label, (Split-Path $ff -Leaf), ($i + 1), $ls[$i].Trim())
            }
        }
    }
}

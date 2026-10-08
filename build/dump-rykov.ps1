# 导出李可夫实装结果供人工核对（2026-09-16）
$out = @()

# ---------- A. 李可夫 5 个国策块 ----------
$out += '========== A. 李可夫 5 个国策块 =========='
$L = [System.IO.File]::ReadAllLines((Join-Path $PWD 'build\inject-sov-seats.txt'))
$cap = $false
for ($i = 0; $i -lt $L.Count; $i++) {
    $line = $L[$i]
    if ($line -match '^\s*id = hof_ic_rykov_') { $cap = $true }
    if ($cap) { $out += ('{0,6}: {1}' -f ($i + 1), $line) }
    # 国策块以顶层的单独一行 } 结束
    if ($cap -and $line -match '^\}$') { $cap = $false; $out += '' }
}
$out += ''

# ---------- B. 三个个人数值容器 ----------
$out += '========== B. 个人数值容器 =========='
foreach ($f in @('hof_ic_trotsky_dm.txt', 'hof_ic_bukharin_dm.txt', 'hof_ic_aleksey_rykov_dm.txt')) {
    $p = Join-Path $PWD "mod\heart_of_iron\common\dynamic_modifiers\$f"
    $out += "--- $f ---"
    if (Test-Path -LiteralPath $p) { $out += [System.IO.File]::ReadAllLines($p) } else { $out += '  (缺文件)' }
    $out += ''
}

# ---------- C. 李可夫的 idea 分级（含 Lv 反查出来的 Add）----------
$out += '========== C. hof_ic_ideas.txt 里李可夫那一段 =========='
$L3 = [System.IO.File]::ReadAllLines((Join-Path $PWD 'mod\heart_of_iron\common\ideas\hof_ic_ideas.txt'))
$cap2 = $false
for ($i = 0; $i -lt $L3.Count; $i++) {
    if ($L3[$i] -match '阿列克谢·李可夫') { $cap2 = $true }
    if ($cap2) { $out += ('{0,6}: {1}' -f ($i + 1), $L3[$i]) }
    if ($cap2 -and $L3[$i] -match '^\t\t\}$') { $cap2 = $false; $out += '' }
}
$out += ''

# ---------- D. swap_ideas 的 From/To（升官衔 tooltip）----------
$out += '========== D. 升官衔 tooltip 的 swap_ideas（三人）=========='
foreach ($k in @('lev_trotsky', 'nikolay_bukharin', 'aleksey_rykov')) {
    $out += "--- $k ---"
    $L4 = [System.IO.File]::ReadAllLines((Join-Path $PWD 'build\inject-sov-seats.txt'))
    for ($i = 0; $i -lt $L4.Count; $i++) {
        if ($L4[$i] -match "hof_ic_idea_${k}_sync_rank = yes") {
            $s = [Math]::Max(0, $i - 9); $e = [Math]::Min($L4.Count - 1, $i)
            for ($j = $s; $j -le $e; $j++) { $out += ('  {0,6}: {1}' -f ($j + 1), $L4[$j]) }
            $out += ''
        }
    }
}

# ---------- E. 李可夫的本地化 ----------
$out += '========== E. 本地化（李可夫段）=========='
$L5 = [System.IO.File]::ReadAllLines((Join-Path $PWD 'mod\heart_of_iron\localisation\simp_chinese\hof_ic_roster_l_simp_chinese.yml'))
$cap3 = $false
foreach ($l in $L5) {
    if ($l -match '李可夫个人线') { $cap3 = $true }
    if ($cap3) { $out += $l }
    if ($cap3 -and $l -match '# -{10,}\s*$' -and $l -notmatch '李可夫个人线') { }
}
foreach ($l in $L5) {
    if ($l -match 'hof_ic_idea_aleksey_rykov') { $out += $l }
    if ($l -match 'hof_ic_rykov_extra_effects_tt') { $out += $l }
    if ($l -match 'hof_ic_aleksey_rykov_dm') { $out += $l }
}

[System.IO.File]::WriteAllLines((Join-Path $PWD 'build\rykov-out.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output ('lines=' + $out.Count)

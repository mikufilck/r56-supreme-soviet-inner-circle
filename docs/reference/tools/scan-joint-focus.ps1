# =============================================================================
# 摸清 joint_focus / shared_focus 机制（需求 B：中苏联合国策 的前置查证）
# -----------------------------------------------------------------------------
# 要回答的问题：
#   1. joint_focus 定义写在【哪个文件、哪一层级】？（树内还是根级）
#   2. shared_focus 怎么在树里引用？
#   3. joint_trigger 怎么写"我与对方同阵营"？
#
# 原则（AGENTS.md 第 7 条）：禁止臆造语法，必须读原版/ R56 的现成写法。
# 官方中国系正好是重灾区，china_communist.txt 也正是需求 B 要改的文件。
#
# 输出写到 docs/reference/joint-focus-report.txt
# =============================================================================

$ErrorActionPreference = 'Stop'

$vanilla = 'F:\Hearts of Iron IV'
$r56     = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$outPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\docs\reference\joint-focus-report.txt'

$out = New-Object System.Text.StringBuilder
function Say([string]$s) { $null = $out.AppendLine($s) }

Say '============================================================================='
Say ' joint_focus / shared_focus 机制勘查'
Say '============================================================================='
Say ''

# -----------------------------------------------------------------------------
Say '############ 1. 哪些国策文件含 joint_focus 块 ############'
Say ''

$candidates = @()
foreach ($root in @($vanilla, $r56)) {
    $label = if ($root -eq $vanilla) { '原版' } else { 'R56' }
    $dir = Join-Path $root 'common\national_focus'
    if (-not (Test-Path $dir)) { continue }
    foreach ($f in (Get-ChildItem $dir -Filter '*.txt' -File -ErrorAction SilentlyContinue)) {
        $L = [System.IO.File]::ReadAllLines($f.FullName)
        $j = 0; $s = 0
        foreach ($ln in $L) {
            if ($ln -match '^\s*joint_focus\s*=\s*\{') { $j++ }
            if ($ln -match '^\s*shared_focus\s*=')    { $s++ }
        }
        if ($j -gt 0) {
            $candidates += [pscustomobject]@{ Root = $label; Name = $f.Name; Lines = $L.Count; J = $j; S = $s; Full = $f.FullName }
        }
    }
    Say ("  [{0}] 扫描 {1} 完毕" -f $label, $dir)
}

Say ''
Say ("  含 joint_focus 块的文件共 {0} 个，按块数排序（前 20）：" -f $candidates.Count)
Say ''
Say ('  {0,-6} {1,-42} {2,8} {3,6} {4,6}' -f '来源', '文件', '行数', 'joint', 'shared')
foreach ($c in ($candidates | Sort-Object -Property J -Descending | Select-Object -First 20)) {
    Say ('  {0,-6} {1,-42} {2,8} {3,6} {4,6}' -f $c.Root, $c.Name, $c.Lines, $c.J, $c.S)
}

# -----------------------------------------------------------------------------
Say ''
Say '############ 2. 一个完整的 joint_focus 范例 ############'
Say ''

# 优先挑跟中国系有关的、且 joint_focus 块较少的文件（短=好读）
$pick = $candidates |
        Where-Object { $_.Name -match 'china' } |
        Sort-Object -Property J |
        Select-Object -First 1
if (-not $pick) {
    $pick = $candidates | Sort-Object -Property J | Select-Object -First 1
}

if ($pick) {
    Say ("  文件: [{0}] {1}" -f $pick.Root, $pick.Name)
    Say ("  绝对路径: {0}" -f $pick.Full)
    Say ''

    $L = [System.IO.File]::ReadAllLines($pick.Full)
    $start = -1
    for ($i = 0; $i -lt $L.Count; $i++) {
        if ($L[$i] -match '^\s*joint_focus\s*=\s*\{') { $start = $i; break }
    }

    if ($start -ge 0) {
        # 括号配平取出整块
        $depth = 0
        $end = $start
        for ($i = $start; $i -lt $L.Count; $i++) {
            $clean = ($L[$i] -replace '#.*$', '')
            $depth += ([regex]::Matches($clean, '\{')).Count
            $depth -= ([regex]::Matches($clean, '\}')).Count
            if ($depth -le 0 -and $i -gt $start) { $end = $i; break }
            if ($i -eq $L.Count - 1) { $end = $i }
        }
        Say ("  第 {0} .. {1} 行：" -f ($start + 1), ($end + 1))
        Say ''
        for ($i = $start; $i -le $end; $i++) {
            Say ("  {0,6}: {1}" -f ($i + 1), $L[$i].TrimEnd())
        }
    } else {
        Say '  （没找到 joint_focus 块开头，跳过）'
    }
} else {
    Say '  没有找到任何含 joint_focus 的文件。'
}

# -----------------------------------------------------------------------------
Say ''
Say '############ 3. shared_focus 在树内怎么引用 ############'
Say ''

$cf = Join-Path $vanilla 'common\national_focus\china_communist.txt'
if (Test-Path $cf) {
    $L = [System.IO.File]::ReadAllLines($cf)
    Say ("  文件: {0}（{1} 行）" -f $cf, $L.Count)
    Say ''
    $hits = @()
    for ($i = 0; $i -lt $L.Count; $i++) {
        if ($L[$i] -match '^\s*shared_focus\s*=') { $hits += $i }
    }
    Say ("  shared_focus 引用共 {0} 处，前 3 处带上下文：" -f $hits.Count)
    Say ''
    foreach ($h in ($hits | Select-Object -First 3)) {
        $s = [Math]::Max(0, $h - 8)
        $e = [Math]::Min($L.Count - 1, $h + 8)
        for ($i = $s; $i -le $e; $i++) {
            $mark = if ($i -eq $h) { ' >>' } else { '   ' }
            Say ("{0}{1,6}: {2}" -f $mark, ($i + 1), $L[$i].TrimEnd())
        }
        Say ''
    }
} else {
    Say "  找不到 $cf"
}

# -----------------------------------------------------------------------------
Say ''
Say '############ 4. joint_trigger 里"同一阵营"的现成写法 ############'
Say ''

# 把所有 joint_trigger 块里的行都抓出来，看官方用过哪些触发器
$triggerHits = @()
foreach ($root in @($vanilla, $r56)) {
    $label = if ($root -eq $vanilla) { '原版' } else { 'R56' }
    $dir = Join-Path $root 'common\national_focus'
    if (-not (Test-Path $dir)) { continue }
    foreach ($f in (Get-ChildItem $dir -Filter '*.txt' -File -ErrorAction SilentlyContinue)) {
        $L = [System.IO.File]::ReadAllLines($f.FullName)
        $inJt = $false
        $depth = 0
        for ($i = 0; $i -lt $L.Count; $i++) {
            $clean = ($L[$i] -replace '#.*$', '')
            if (-not $inJt) {
                if ($clean -match '^\s*joint_trigger\s*=\s*\{') {
                    $inJt = $true
                    $depth = ([regex]::Matches($clean, '\{')).Count - ([regex]::Matches($clean, '\}')).Count
                    continue
                }
                continue
            }
            $depth += ([regex]::Matches($clean, '\{')).Count
            $depth -= ([regex]::Matches($clean, '\}')).Count
            $t = $clean.Trim()
            if ($t -ne '' -and $t -notmatch '^[\{\}]+$') {
                $triggerHits += [pscustomobject]@{ Root = $label; File = $f.Name; Text = $t }
            }
            if ($depth -le 0) { $inJt = $false }
        }
    }
}

Say ("  joint_trigger 内共采集到 {0} 行触发器写法。" -f $triggerHits.Count)
Say ''
Say '  按出现频次归类（看官方最常用哪些）：'
Say ''

# 取每行的"触发器名"（= 号或空格前的第一个词）
$names = @{}
foreach ($h in $triggerHits) {
    $n = ($h.Text -split '=')[0].Trim()
    $n = ($n -split '\s+')[0]
    if ($n) {
        if (-not $names.ContainsKey($n)) { $names[$n] = 0 }
        $names[$n]++
    }
}
foreach ($kv in ($names.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 25)) {
    Say ('    {0,-42} {1,5}' -f $kv.Key, $kv.Value)
}

Say ''
Say '  全部原始行（去重，前 60 条）：'
Say ''
foreach ($t in ($triggerHits | ForEach-Object { $_.Text } | Sort-Object -Unique | Select-Object -First 60)) {
    Say ("    {0}" -f $t)
}

[System.IO.File]::WriteAllText($outPath, $out.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "报告已写出: $outPath"
Write-Output ("行数 = {0}" -f (([regex]::Matches($out.ToString(), "`n")).Count + 1))

# scan-dynamic-modifier-rules.ps1
# ---------------------------------------------------------------------------
# 勘查 dynamic_modifier 的「引擎规则」—— 这些是写核心圈个人线前必须钉死的事实：
#
#   1. DM 块内合法的一层字段有哪些（尤其：有没有 name 字段）
#   2. 显示名是不是只能等于 DM id 对应的本地化键
#   3. 数值刷新机制（每天自动？能不能强制刷新？）
#   4. 有没有 has_dynamic_modifier 触发器（条件移除要用）
#   5. 能不能用 scripted localisation 让 DM 名字动态化（判断有无先例）
#
# 产出（建议）：docs/reference/reports/dynamic-modifier-rules.txt
#   例：powershell -NoProfile -File docs\reference\tools\scan-dynamic-modifier-rules.ps1 |
#         Out-File -LiteralPath docs\reference\reports\dynamic-modifier-rules.txt -Encoding utf8
#
# 结论已摘进 docs/11 §4.2.1；落地方案见 docs/22 §8.2.1。
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$DOC  = Join-Path $HOI4 'documentation'

$MOD_ROOTS = @($HOI4, $R56)

# ===========================================================================
Write-Output '##### 1. DM 块内「一层」字段名（按出现次数降序）#####'
Write-Output '# 说明：只统计恰好一个 Tab 缩进的 key，即 dynamic_modifiers = { <id> = { ... } } 里那一层'
Write-Output ''
$dmRoots = @()
foreach ($r in $MOD_ROOTS) {
    $p = Join-Path $r 'common\dynamic_modifiers'
    if (Test-Path $p) { $dmRoots += $p }
}
$fields = @{}
$dmFiles = 0
foreach ($r in $dmRoots) {
    Get-ChildItem $r -Recurse -File -Filter *.txt | ForEach-Object {
        $dmFiles++
        foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
            if ($line -match '^\t([a-zA-Z_][a-zA-Z_0-9]*)\s*=') {
                $k = $Matches[1]
                if ($fields.ContainsKey($k)) { $fields[$k] = $fields[$k] + 1 } else { $fields[$k] = 1 }
            }
        }
    }
}
Write-Output ("（共扫 {0} 个 DM 文件）" -f $dmFiles)
Write-Output ''
$fields.GetEnumerator() | Sort-Object Value -Descending |
    ForEach-Object { "  {0,-58} {1}" -f $_.Key, $_.Value }

# ===========================================================================
Write-Output ''
Write-Output '##### 2. 全部 DM 文件里出现 `name =` 的行（原样列出）#####'
Write-Output '# 若为空 → DM 没有 name 字段 → 显示名只能是 id 的本地化键，静态'
Write-Output ''
foreach ($r in $dmRoots) {
    Get-ChildItem $r -Recurse -File -Filter *.txt | ForEach-Object {
        $n = $_.FullName
        Select-String -LiteralPath $n -Pattern 'name\s*=' | ForEach-Object {
            "  {0} L{1}: {2}" -f (Split-Path $n -Leaf), $_.LineNumber, $_.Line.Trim()
        }
    }
}

# ===========================================================================
Write-Output ''
Write-Output '##### 3. dynamic_modifier 相关的效果效果（非修饰符）的权威定义 #####'
Write-Output ''
$effDoc = Join-Path $DOC 'effects_documentation.md'
$want = @('## add_dynamic_modifier', '## force_update_dynamic_modifier', '## remove_dynamic_modifier')
$lines = [System.IO.File]::ReadAllLines($effDoc)
for ($i = 0; $i -lt $lines.Count; $i++) {
    foreach ($w in $want) {
        if ($lines[$i].Trim() -eq $w) {
            Write-Output ("  --- {0}（L{1}）---" -f $w, ($i + 1))
            $j = $i
            $printed = 0
            while ($j -lt $lines.Count -and $printed -lt 20) {
                Write-Output ('      ' + $lines[$j])
                $j++
                $printed++
                if ($printed -gt 1 -and $lines[$j] -match '^## ') { break }
            }
            Write-Output ''
        }
    }
}

# ===========================================================================
Write-Output ''
Write-Output '##### 4. has_dynamic_modifier 触发器是否存在、用得多不多 #####'
Write-Output ''
$trgDoc = Join-Path $DOC 'triggers_documentation.md'
$tl = [System.IO.File]::ReadAllLines($trgDoc)
for ($i = 0; $i -lt $tl.Count; $i++) {
    if ($tl[$i].Trim() -eq '## has_dynamic_modifier') {
        for ($j = $i; $j -lt $tl.Count -and $j -lt $i + 20; $j++) {
            Write-Output ('    ' + $tl[$j])
            if ($j -gt $i + 1 -and $tl[$j] -match '^## ') { break }
        }
    }
}
Write-Output ''
foreach ($r in $MOD_ROOTS) {
    $label = 'vanilla'
    if ($r -eq $R56) { $label = 'R56' }
    $hit = 0
    Get-ChildItem (Join-Path $r 'common') -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue |
        ForEach-Object {
            $hit += (Select-String -LiteralPath $_.FullName -Pattern 'has_dynamic_modifier' -ErrorAction SilentlyContinue).Count
        }
    Write-Output ("  [{0}] has_dynamic_modifier 出现 {1} 处" -f $label, $hit)
}

# ===========================================================================
Write-Output ''
Write-Output '##### 5. scripted localisation 会不会被用来给 DM / idea 改名 #####'
Write-Output '# 判据：defined_text 的名字与 common/ideas 里的 id 有没有交集'
Write-Output ''
$names = New-Object System.Collections.Generic.List[string]
foreach ($r in $MOD_ROOTS) {
    $p = Join-Path $r 'common\scripted_localisation'
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -File | ForEach-Object {
        foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
            if ($line -match '^\s*name\s*=\s*([a-zA-Z_0-9]+)') { $names.Add($Matches[1]) }
        }
    }
}
Write-Output ("  defined_text 总数：{0}" -f $names.Count)

$ideaIds = @{}
foreach ($r in $MOD_ROOTS) {
    $p = Join-Path $r 'common\ideas'
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -File -Filter *.txt | ForEach-Object {
        foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
            if ($line -match '^\t+([a-zA-Z_][a-zA-Z_0-9]*)\s*=\s*\{') { $ideaIds[$Matches[1]] = 1 }
        }
    }
}
Write-Output ("  ideas 目录候选 id 总数：{0}" -f $ideaIds.Count)
$inter = 0
foreach ($n in $names) {
    if ($ideaIds.ContainsKey($n)) { Write-Output ("  ★ 交集：{0}" -f $n); $inter++ }
}
Write-Output ("  交集数：{0}  → 交集为 0 则说明【没有任何 DM / idea 用过脚本本地化改名】" -f $inter)

# ===========================================================================
Write-Output ''
Write-Output '##### 6. 一句话结论 #####'
Write-Output '  · DM 的「数值」靠 add_to_variable 改，每天自动重算，force_update_dynamic_modifier 可立即刷新'
Write-Output '  · DM 的「显示名」= id 的本地化键，静态；没有 name 字段，也没有脚本本地化的先例'
Write-Output '  · => 想在升级时改官衔名，只能换 DM id；但这跟数值完全无关'
Write-Output '  · 移除旧 id 时用 has_dynamic_modifier 条件块包起来，避免残留'

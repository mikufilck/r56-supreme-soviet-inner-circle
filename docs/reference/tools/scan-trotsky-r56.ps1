# =============================================================================
# 摸清 R56 现有的「反对派系统」——特别是托洛茨基相关的一切
# -----------------------------------------------------------------------------
# 为什么要查：
#   核心圈要写「个人线国策」，但 R56 很可能早就为这些人做了角色旗标、
#   洗白/流放/监禁状态、以及相关国策与事件。
#   直接接进去，好过另起一套平行机制（后者会互相打架且难维护）。
#
# 输出：docs/reference/trotsky-r56-report.txt
# =============================================================================

$ErrorActionPreference = 'Stop'

$r56     = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$outPath = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\docs\reference\trotsky-r56-report.txt'

$out = New-Object System.Text.StringBuilder
function Say([string]$s) { $null = $out.AppendLine($s) }

Say '============================================================================='
Say ' R56 里的托洛茨基 / 左翼反对派 家底勘查'
Say '============================================================================='
Say ''

# -----------------------------------------------------------------------------
Say '############ 1. 出现 "trotsky" 的文件（按文件统计命中数）############'
Say ''

$scanDirs = @('common', 'events')
$hits = @()

foreach ($d in $scanDirs) {
    $dir = Join-Path $r56 $d
    if (-not (Test-Path $dir)) { continue }
    foreach ($f in (Get-ChildItem $dir -Recurse -Include *.txt -File -ErrorAction SilentlyContinue)) {
        $L = [System.IO.File]::ReadAllLines($f.FullName)
        $n = 0
        for ($i = 0; $i -lt $L.Count; $i++) {
            if ($L[$i] -match '(?i)trotsky') {
                $n++
                $hits += [pscustomobject]@{ File = $f.FullName.Replace($r56 + '\', ''); Line = $i + 1; Text = $L[$i].Trim() }
            }
        }
        if ($n -gt 0) {
            Say ("  {0,-58} {1,5} 处" -f $f.FullName.Replace($r56 + '\', ''), $n)
        }
    }
}

Say ''
Say ("  合计 {0} 处，分布在 {1} 个文件。" -f $hits.Count, (($hits | ForEach-Object { $_.File } | Sort-Object -Unique).Count))

# -----------------------------------------------------------------------------
Say ''
Say '############ 2. 左翼 / 右翼反对派的状态旗标系统 ############'
Say ''

$flagNames = @(
    'SOV_aligned_left_opposition_flag', 'SOV_aligned_right_opposition_flag',
    'SOV_imprisoned_flag', 'SOV_exiled_flag', 'SOV_set_as_aligned_to_left_oppo',
    'SOV_is_left_opposition', 'SOV_is_right_opposition',
    'SOV_potential_target_flag', 'SOV_factionalism_modifier'
)

foreach ($fn in $flagNames) {
    $found = $hits | Where-Object { $_.Text -match [regex]::Escape($fn) }
    Say ("  --- {0} ---  命中 {1} 处" -f $fn, $found.Count)
    $shown = 0
    foreach ($h in $found) {
        if ($shown -ge 6) { Say '      …（略）'; break }
        Say ("      {0} : L{1} : {2}" -f $h.File, $h.Line, $h.Text)
        $shown++
    }
    Say ''
}

# -----------------------------------------------------------------------------
Say '############ 3. 名字里含 trotsky 的 idea / 修正 / 事件 ############'
Say ''

$named = @()
foreach ($root in @($r56)) {
    foreach ($d in @('common\ideas', 'common\dynamic_modifiers', 'common\scripted_effects', 'common\scripted_triggers', 'common\characters', 'events')) {
        $dir = Join-Path $root $d
        if (-not (Test-Path $dir)) { continue }
        foreach ($f in (Get-ChildItem $dir -Recurse -Include *.txt -File -ErrorAction SilentlyContinue)) {
            $L = [System.IO.File]::ReadAllLines($f.FullName)
            for ($i = 0; $i -lt $L.Count; $i++) {
                # 抓"定义行"：顶层 名字 = {  且名字里含 trotsky
                if ($L[$i] -match '^\s*([A-Za-z0-9_]*[Tt]rotsky[A-Za-z0-9_]*)\s*=\s*\{') {
                    $named += [pscustomobject]@{ Name = $Matches[1]; File = $f.FullName.Replace($r56 + '\', ''); Line = $i + 1 }
                }
            }
        }
    }
}

Say ("  找到 {0} 个含 trotsky 的命名定义：" -f $named.Count)
Say ''
foreach ($n in ($named | Sort-Object -Property Name -Unique)) {
    Say ("    {0,-52} {1} : L{2}" -f $n.Name, $n.File, $n.Line)
}

# -----------------------------------------------------------------------------
Say ''
Say '############ 4. 苏联树里与反对派/平反相关的国策 id ############'
Say ''

$sovFile = Join-Path $r56 'common\national_focus\soviet.txt'
if (Test-Path $sovFile) {
    $L = [System.IO.File]::ReadAllLines($sovFile)
    Say ("  文件: common\national_focus\soviet.txt（{0} 行）" -f $L.Count)
    Say ''
    $focusIds = @()
    for ($i = 0; $i -lt $L.Count; $i++) {
        if ($L[$i] -match '^\s*id\s*=\s*(SOV_[A-Za-z0-9_]+)\s*$') {
            $focusIds += [pscustomobject]@{ Id = $Matches[1]; Line = $i + 1 }
        }
    }
    Say ("  树内共 {0} 个 SOV_* 国策。下面是名字里带政治/反对派意味的：" -f $focusIds.Count)
    Say ''
    $kw = 'opposition|trotsky|zinoviev|zinovyev|kamenev|bukharin|rykov|smirnov|serebryakov|democracy|destalin|purge|amnesty|rehabilit|party|soviet|union|council|faction'
    foreach ($f in $focusIds) {
        if ($f.Id -match "(?i)($kw)") {
            Say ("    {0,-58} L{1}" -f $f.Id, $f.Line)
        }
    }
}

[System.IO.File]::WriteAllText($outPath, $out.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Output "报告已写出: $outPath"
Write-Output ("行数 = {0}" -f (([regex]::Matches($out.ToString(), "`n")).Count + 1))

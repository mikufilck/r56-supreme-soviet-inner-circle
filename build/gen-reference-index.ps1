# =============================================================================
# 生成 docs/reference/INDEX.md —— 勘查脚本 <-> 产出报告 的对照索引
# -----------------------------------------------------------------------------
# 为什么不手写索引：手写的会过期。这里每次跑都从文件本身重新抽取
#   - 脚本：取头部注释里第一句有意义的描述
#   - 报告：取首行 + 行数 + 大小
# 于是「我以后还找得到吗」这个问题由文件自己回答。
# =============================================================================
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$ref  = Join-Path $root 'docs\reference'
$tools   = Join-Path $ref 'tools'
$reports = Join-Path $ref 'reports'

function Get-Headline([string]$path) {
    $lines = [System.IO.File]::ReadAllLines($path)
    $i = 0
    while ($i -lt $lines.Count -and $i -lt 40) {
        $s = $lines[$i].Trim()
        if ($s -match '^#\s*[=*\-]{3,}\s*$') { $i++; continue }          # 分隔线
        if ($s -match '^#\s*(.*)$') {
            $d = $Matches[1].Trim()
            if ($d -ne '' -and $d -notmatch '^!') { return $d }
        }
        $i++
    }
    return ''
}

function Get-ReportHeadline([string]$path) {
    try {
        $lines = [System.IO.File]::ReadAllLines($path)
        foreach ($l in ($lines | Select-Object -First 6)) {
            $s = $l.Trim()
            if ($s -ne '') {
                if ($s.Length -gt 110) { $s = $s.Substring(0, 109) + '…' }
                return $s
            }
        }
    } catch { }
    return ''
}

if (-not (Test-Path -LiteralPath $tools))   { throw "缺目录: $tools" }
if (-not (Test-Path -LiteralPath $reports)) { throw "缺目录: $reports" }

$scriptFiles = Get-ChildItem -LiteralPath $tools -File -Recurse | Sort-Object Name
$reportFiles = Get-ChildItem -LiteralPath $reports -File -Recurse | Sort-Object Name

# 报告名 -> 文件，用于「脚本 -> 产出」匹配
$reportByStem = @{}
foreach ($r in $reportFiles) {
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($r.Name)
    $reportByStem[$stem] = $r.Name
}

function Find-Reports([string]$scriptName) {
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($scriptName)
    $hits = @()
    foreach ($k in @($stem, "$stem-report", ($stem -replace '^(scan|dump|verify|check|find|get|list|calibrate)-', ''))) {
        if ($reportByStem.ContainsKey($k)) { $hits += $reportByStem[$k] }
    }
    # 模糊：报告名里含脚本关键片段
    $core = ($stem -replace '^(scan|dump|verify|check|find|get|list|calibrate|make)-', '')
    if ($core.Length -ge 4) {
        foreach ($r in $reportFiles) {
            if ($r.Name -like "*$core*" -and $hits -notcontains $r.Name) { $hits += $r.Name }
        }
    }
    return ($hits | Select-Object -Unique)
}

$out = New-Object System.Collections.ArrayList
[void]$out.Add('# docs/reference 索引（自动生成）')
[void]$out.Add('')
[void]$out.Add('> 本文件由 `build/gen-reference-index.ps1` 生成，**不要手改**。')
[void]$out.Add('> 重排/新增脚本后重跑该脚本即可刷新。生成时间：' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
[void]$out.Add('')
[void]$out.Add('## 目录约定')
[void]$out.Add('')
[void]$out.Add('| 目录 | 放什么 | 规则 |')
[void]$out.Add('| --- | --- | --- |')
[void]$out.Add('| `tools/` | 勘查脚本（`.ps1` / `.py`） | 只读游戏/mod 文件，把结论打到 stdout 或 `../reports/` |')
[void]$out.Add('| `reports/` | 脚本的产出（`.txt`） | 文件名与被引用的文档一一对应 |')
[void]$out.Add('| `notes/` | 知识性笔记（`.md`） | 不是程序产出，是整理过的结论 |')
[void]$out.Add('| `images/` | 参考图（`.png`） | 从游戏 DDS 转出来的对照图 |')
[void]$out.Add('| `wiki/` | Paradox 官方 wiki 离线快照 | 32 页纯文本，用 `Ctrl+Shift+F` 全局搜 |')
[void]$out.Add('| 根目录 | 只留 `README.md` | 任何散落文件都应归入上面某一类 |')
[void]$out.Add('')
[void]$out.Add('**命名约定（新脚本请遵守）**：`<scan|dump|verify|check|find|get>-<主题>-<对象>.ps1`，产出 `<主题>-<对象>-report.txt`。')
[void]$out.Add('')
[void]$out.Add('---')
[void]$out.Add('')
[void]$out.Add("## 脚本 → 产出（共 $($scriptFiles.Count) 个脚本）")
[void]$out.Add('')
[void]$out.Add('| 脚本 | 用途（取自脚本头部注释） | 主要产出 |')
[void]$out.Add('| --- | --- | --- |')

foreach ($s in $scriptFiles) {
    $head  = Get-Headline $s.FullName
    $reps  = Find-Reports $s.Name
    $repTxt = if ($reps.Count -gt 0) { (($reps | Select-Object -First 3) | ForEach-Object { "``$_``" }) -join ' ' } else { '—' }
    [void]$out.Add("| ``$($s.Name)`` | $head | $repTxt |")
}

[void]$out.Add('')
[void]$out.Add("## 产出报告一览（共 $($reportFiles.Count) 个）")
[void]$out.Add('')
[void]$out.Add('| 报告 | 行数 | 首行 |')
[void]$out.Add('| --- | --- | --- |')

foreach ($r in $reportFiles) {
    $n = 0
    try { $n = ([System.IO.File]::ReadAllLines($r.FullName)).Count } catch { }
    $kb = [math]::Round($r.Length / 1KB, 1)
    [void]$out.Add("| ``$($r.Name)`` | $n ($kb KB) | $(Get-ReportHeadline $r.FullName) |")
}

$dst = Join-Path $ref 'INDEX.md'
[System.IO.File]::WriteAllLines($dst, $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Output "wrote $dst  ($($out.Count) lines : $($scriptFiles.Count) 脚本, $($reportFiles.Count) 报告)"

# =============================================================================
# 重排 docs/reference/ —— 把「散落一地」变成 tools / reports / notes / images
# -----------------------------------------------------------------------------
# 为什么可以自动化：
#   1. 分桶规则只看扩展名（.ps1/.py -> tools，.txt -> reports），无需人工判断
#   2. 平铺目录里文件名唯一，所以「旧名 -> 新路径」的字符串替换是安全的
#   3. 唯一的真实耦合是 .vscode/tasks.json 里的 108 处路径 + docs/*.md 里的引用，
#      两者都是纯文本路径，一并改写即可
#
# 不做的事：
#   - 不删除任何文件（归档另行决定）
#   - 不动 reference/wiki/（官方 wiki 快照，本来就是子目录）
#   - 不动 reference/README.md（它留在根，重排后单独重写）
# =============================================================================
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$ref  = Join-Path $root 'docs\reference'

if (-not (Test-Path -LiteralPath $ref)) { throw "not found: $ref" }

# ---------- 分桶 ----------
$buckets = @{
    'tools'   = @('.ps1', '.py')
    'reports' = @('.txt')
}

$moves = New-Object System.Collections.ArrayList   # @{ From; To; Bucket; Name }

foreach ($f in Get-ChildItem -LiteralPath $ref -File) {
    if ($f.Name -eq 'README.md') { continue }
    if ($f.Name -eq 'INDEX.md')  { continue }   # 索引留在根目录当作门厅，不归入 notes
    if ($f.Name -like 'reorg-manifest*') { continue }

    $bucket = $null
    if ($f.Name -like '*.md') {
        $bucket = 'notes'
    } else {
        foreach ($k in $buckets.Keys) {
            if ($buckets[$k] -contains $f.Extension.ToLower()) { $bucket = $k; break }
        }
    }
    if (-not $bucket) { Write-Output "  ⚠ 未分类（保持原位）: $($f.Name)"; continue }

    [void]$moves.Add(@{ From = $f.FullName; To = (Join-Path (Join-Path $ref $bucket) $f.Name); Bucket = $bucket; Name = $f.Name })
}

# 子目录：images <- icon-refs-png
$imgSrc = Join-Path $ref 'icon-refs-png'
$imgDst = Join-Path $ref 'images'
if (Test-Path -LiteralPath $imgSrc) { [void]$moves.Add(@{ From = $imgSrc; To = $imgDst; Bucket = 'images'; Name = 'icon-refs-png' }) }

Write-Output ("计划移动 {0} 项" -f $moves.Count)

# ---------- 建目录 + 移动 ----------
foreach ($b in @('tools', 'reports', 'notes', 'images')) {
    $d = Join-Path $ref $b
    if (-not (Test-Path -LiteralPath $d)) { [void][System.IO.Directory]::CreateDirectory($d) }
}

$done = 0
$failed = New-Object System.Collections.ArrayList
$okMoves = New-Object System.Collections.ArrayList
foreach ($m in $moves) {
    if (-not (Test-Path -LiteralPath $m.From)) { continue }   # 已移动过 -> 幂等
    try {
        $isDir = (Get-Item -LiteralPath $m.From -Force).PSIsContainer
        if ($isDir) { [System.IO.Directory]::Move($m.From, $m.To) }
        else        { [System.IO.File]::Move($m.From, $m.To) }
        $done++
        [void]$okMoves.Add($m)
    } catch {
        [void]$failed.Add($m.Name)   # 被占用（多半是 VS Code 里开着标签页）
    }
}
Write-Output ("实际移动 {0} 项，失败 {1} 项" -f $done, $failed.Count)
if ($failed.Count -gt 0) {
    Write-Output '  ⚠ 以下文件被别的进程占用，未移动 —— 关掉 VS Code 里对应的标签页后【重跑本脚本】即可（幂等）：'
    foreach ($n in $failed) { Write-Output "      $n" }
}

# ---------- 生成路径替换表 ----------
# ⚠️ 表格必须来自【当前已经在桶里的全部文件】，而不是本轮的 $moves。
#    因为本脚本会被分几次跑（文件被占用时），只看 $moves 的话，
#    前面几轮搬走的文件永远不会被改写引用 —— 这个坑实际踩到两次。
$pairs = @()
foreach ($b in @('tools', 'reports', 'notes')) {
    $d = Join-Path $ref $b
    if (-not (Test-Path -LiteralPath $d)) { continue }
    foreach ($f in Get-ChildItem -LiteralPath $d -File -Recurse) {
        $pairs += , @("reference/$($f.Name)", "reference/$b/$($f.Name)")
        $pairs += , @("reference\$($f.Name)", "reference\$b\$($f.Name)")
    }
}
if (Test-Path -LiteralPath (Join-Path $ref 'images')) {
    $pairs += , @('reference/icon-refs-png', 'reference/images')
    $pairs += , @('reference\icon-refs-png', 'reference\images')
}
Write-Output ("替换表 {0} 条规则（覆盖已归位的全部文件）" -f ($pairs.Count / 2))

function Rewrite-Paths([string]$text) {
    $n = 0
    foreach ($p in $pairs) {
        if ($text.Contains($p[0])) {
            $n += ([regex]::Matches($text, [regex]::Escape($p[0]))).Count
            $text = $text.Replace($p[0], $p[1])
        }
    }
    return [pscustomobject]@{ Text = $text; N = $n }
}

# ---------- 改写 .vscode/tasks.json ----------
$tasks = Join-Path $root '.vscode\tasks.json'
if (Test-Path -LiteralPath $tasks) {
    $orig = [System.IO.File]::ReadAllText($tasks)
    $r = Rewrite-Paths $orig
    if ($r.N -gt 0) {
        try { $null = $r.Text | ConvertFrom-Json; $okJson = $true } catch { $okJson = $false }
        if (-not $okJson) { throw "改写后 tasks.json 不是合法 JSON，已中止（原文件未动）" }
        [System.IO.File]::WriteAllText($tasks, $r.Text, (New-Object System.Text.UTF8Encoding($false)))
        Write-Output ("tasks.json：改写 {0} 处路径，JSON 校验通过" -f $r.N)
    } else {
        Write-Output 'tasks.json：无需改写'
    }
}

# ---------- 改写 docs 下的 .md ----------
$mdTotal = 0
foreach ($f in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -Filter '*.md' -File -Recurse) {
    if ($f.FullName -like "*\reference\wiki\*") { continue }
    $orig = [System.IO.File]::ReadAllText($f.FullName)
    $r = Rewrite-Paths $orig
    if ($r.N -gt 0) {
        [System.IO.File]::WriteAllText($f.FullName, $r.Text, (New-Object System.Text.UTF8Encoding($false)))
        $mdTotal += $r.N
        Write-Output ("  {0}: {1} 处" -f $f.Name, $r.N)
    }
}
Write-Output ("docs/*.md 共改写 {0} 处" -f $mdTotal)

# ---------- 清单 ----------
$manifest = New-Object System.Collections.ArrayList
[void]$manifest.Add('# docs/reference 重排清单')
[void]$manifest.Add('')
[void]$manifest.Add('| 原位置 | 新位置 |')
[void]$manifest.Add('| --- | --- |')
foreach ($m in ($moves | Sort-Object { $_.Bucket }, { $_.Name })) {
    [void]$manifest.Add("| ``reference/$($m.Name)`` | ``reference/$($m.Bucket)/$($m.Name)`` |")
}
[System.IO.File]::WriteAllLines((Join-Path $ref 'reorg-manifest.txt'), $manifest, (New-Object System.Text.UTF8Encoding($false)))

Write-Output ''
Write-Output '---- 结果 ----'
foreach ($b in @('tools', 'reports', 'notes', 'images')) {
    $d = Join-Path $ref $b
    $c = if (Test-Path -LiteralPath $d) { (Get-ChildItem -LiteralPath $d -File -Recurse -ErrorAction SilentlyContinue).Count } else { 0 }
    Write-Output ("  reference/{0,-8} {1} 个文件" -f $b, $c)
}
$left = (Get-ChildItem -LiteralPath $ref -File).Count
Write-Output ("  reference/ 根目录剩 {0} 个文件（应只剩 README.md 与 reorg-manifest.txt）" -f $left)

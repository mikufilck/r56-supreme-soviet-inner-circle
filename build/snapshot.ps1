# snapshot.ps1
# ---------------------------------------------------------------------------
# 零依赖的【本地整仓快照】—— 在没有 git 的机器上给出「可回滚点」。
#
# 为什么需要它：本仓是「整文件覆盖」开发（mod 里大量文件是 R56 的副本），
# 一次误改可能覆盖掉整份文件；而本机**没有安装 git**（已核实常见路径全无）。
# VS Code 的 Local History（Timeline 视图）只能按文件回滚单次编辑，
# 不能给「整仓在某个时刻的样子」，这个脚本补的就是那一层。
#
# 用法：
#   powershell -NoProfile -File build\snapshot.ps1                 # 打一个快照
#   powershell -NoProfile -File build\snapshot.ps1 -Tag 改数值前    # 带说明
#   powershell -NoProfile -File build\snapshot.ps1 -List            # 列出已有快照
#   powershell -NoProfile -File build\snapshot.ps1 -Keep 30         # 只留最近 30 个
#
# 内容 = 【文本资产】：mod/ build/ docs/ old/ art/focus 里的 README 与提示词、
#        AGENTS.md、.gitignore。
# ⛔ 不含 tmp/（草稿）与 .venv/（环境），也**不含美术二进制图**（510 MB，
#    它们另有交付记录 art/focus/*/README.md，且体积不适合打快照）。
# ---------------------------------------------------------------------------

[CmdletBinding()]
param(
    # ⚠️ 这里【不要】用 $PSScriptRoot 当 param 默认值 ——
    #    2026-09-25 实测：以 `powershell -File build\snapshot.ps1` 方式调用时，
    #    param 绑定阶段 $PSScriptRoot 是【空】的 ⇒ Split-Path 报
    #    "ParameterArgumentValidationErrorEmptyStringNotAllowed"、脚本直接跑不起来。
    #    ✅ 改成先在（脚本体里）解析，再兜 $PSScriptRoot。
    [string]$Root = '',
    [string]$Tag = '',
    [int]$Keep = 20,
    [switch]$List
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $here = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $PSScriptRoot }
            else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $Root = Split-Path -Parent $here
}

$snapDir = Join-Path $Root 'snapshots'
$indexPath = Join-Path $snapDir 'INDEX.md'

if ($List) {
    if (-not (Test-Path $indexPath)) { Write-Output '还没有任何快照。'; return }
    Get-Content -LiteralPath $indexPath -Encoding UTF8
    return
}

if (-not (Test-Path $snapDir)) { New-Item -ItemType Directory -Path $snapDir -Force | Out-Null }

# --- 收集要打包的文件（只收文本资产）---------------------------------------
$textExt = @('.txt', '.yml', '.gfx', '.gui', '.mod', '.json', '.md', '.ps1', '.py', '.csv', '.lua', '.sh', '.bat', '.gitignore')
$scanDirs = @('mod', 'build', 'docs', 'old')
$scanFiles = @('AGENTS.md', '.gitignore')

# 排除项：快照夹自己 + Python 环境 + 系统垃圾
$exclRe = '(?i)\\(snapshots|\.venv|__pycache__|tmp)\\'

$files = New-Object System.Collections.Generic.List[string]
foreach ($f in $scanFiles) {
    $fp = Join-Path $Root $f
    if (Test-Path $fp) { $files.Add($fp) }
}
foreach ($d in $scanDirs) {
    $dp = Join-Path $Root $d
    if (-not (Test-Path $dp)) { continue }
    foreach ($f in Get-ChildItem $dp -Recurse -File -ErrorAction SilentlyContinue) {
        if ($f.FullName -match $exclRe) { continue }
        if ($textExt -contains $f.Extension.ToLower() -or ($f.Name -eq '.gitignore')) { $files.Add($f.FullName) }
    }
}
if ($files.Count -eq 0) { throw '没有收集到任何文件 —— 路径写错了？' }

# --- 打 zip -----------------------------------------------------------------
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$safeTag = if ($Tag) { '_' + ($Tag -replace '[\\/:*?"<>|\s]', '') } else { '' }
$zipPath = Join-Path $snapDir ("hof_{0}{1}.zip" -f $stamp, $safeTag)

$staging = Join-Path $env:TEMP ("hof_snap_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging -Force | Out-Null
foreach ($f in $files) {
    $rel = $f.Substring($Root.Length).TrimStart('\', '/')
    $dst = Join-Path $staging $rel
    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    Copy-Item -LiteralPath $f -Destination $dst -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($staging, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
Remove-Item -LiteralPath $staging -Recurse -Force

$sizeMB = [Math]::Round((Get-Item $zipPath).Length / 1MB, 1)

# --- 写索引 -----------------------------------------------------------------
if (-not (Test-Path $indexPath)) {
    $head = @(
        '# 快照索引（由 `build/snapshot.ps1` 自动追加）',
        '',
        '> 本机**没有 git**，这是「整仓文本资产」的可回滚点。',
        '> 回滚办法：把对应 zip 解到工作区根目录（同名文件会被覆盖 —— 这正是我们要的）。',
        '> ⛔ 快照**不含**美术二进制图与 `tmp/`。',
        '',
        '| 时间 | 说明 | 文件 | 体积 | 打包文件数 |',
        '| --- | --- | --- | --- | --- |'
    )
    Set-Content -LiteralPath $indexPath -Value $head -Encoding UTF8
}

$line = ('| {0} | {1} | `{2}` | {3} MB | {4} |' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $(if ($Tag) { $Tag } else { '—' }), (Split-Path $zipPath -Leaf), $sizeMB, $files.Count)
Add-Content -LiteralPath $indexPath -Value $line -Encoding UTF8

Write-Output ("快照完成：{0}" -f $zipPath)
Write-Output ("  文件数 {0} · 体积 {1} MB" -f $files.Count, $sizeMB)

# --- 保留最近 $Keep 个 -------------------------------------------------------
$zips = Get-ChildItem $snapDir -Filter 'hof_*.zip' -File | Sort-Object LastWriteTime -Descending
if ($zips.Count -gt $Keep) {
    $old = $zips | Select-Object -Skip $Keep
    foreach ($z in $old) { Remove-Item -LiteralPath $z.FullName -Force; Write-Output ("  已清理旧快照：" + $z.Name) }
}
Write-Output ("当前快照共 {0} 个（上限 {1}）· 索引见 snapshots\INDEX.md" -f ([Math]::Min($zips.Count, $Keep)), $Keep)

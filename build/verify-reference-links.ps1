# =============================================================================
# 验证：docs/reference 重排后没有断链
# -----------------------------------------------------------------------------
# 扫描两类引用者，抽出所有 `reference/<路径>` 形式的引用，逐个验证文件是否存在：
#   1. .vscode/tasks.json（任务定义，重排影响面最大）
#   2. docs/**/*.md    （正文里的交叉引用）
# 有任何一条指向不存在的文件就报 FAIL 并列出。
# =============================================================================
$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$ref  = Join-Path $root 'docs\reference'

$bad = New-Object System.Collections.ArrayList
$total = 0

function Test-Refs([string]$text, [string]$who) {
    foreach ($m in [regex]::Matches($text, 'reference[\\/][A-Za-z0-9_.\-\\/]+')) {
        $rel = $m.Value -replace '/', '\'
        # 剥掉尾随标点。⚠️ 必须包含反斜杠与引号：JSON 里的路径写作
        #   "...reference/x.ps1\""
        # 正则会把转义用的反斜杠也吃进来，不剥掉就会全套误报（已踩过）。
        $rel = $rel.TrimEnd('.', ',', ')', '`', '\', '"', "'")
        $script:total++
        # 文档里的占位示例不算断链
        if ($rel -match 'reference\\wiki\\X\.html$') { continue }
        $full = Join-Path $ref ($rel -replace '^reference\\', '')
        if (-not (Test-Path -LiteralPath $full)) {
            [void]$script:bad.Add("[$who] $rel")
        }
    }
}

# 1) tasks.json
$tasks = Join-Path $root '.vscode\tasks.json'
if (Test-Path -LiteralPath $tasks) {
    Test-Refs ([System.IO.File]::ReadAllText($tasks)) 'tasks.json'
}

# 2) docs/**/*.md
foreach ($f in Get-ChildItem -LiteralPath (Join-Path $root 'docs') -Filter '*.md' -File -Recurse) {
    Test-Refs ([System.IO.File]::ReadAllText($f.FullName)) $f.Name
}

Write-Output ("检查了 {0} 处 reference 引用" -f $total)
if ($bad.Count -eq 0) {
    Write-Output '✅ 全部命中，没有断链'
    exit 0
} else {
    Write-Output ("❌ 断链 {0} 处：" -f $bad.Count)
    foreach ($b in ($bad | Sort-Object -Unique)) { Write-Output "   $b" }
    exit 1
}

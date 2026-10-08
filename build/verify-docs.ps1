# =============================================================================
# verify-docs.ps1 —— 知识库（docs/）结构与链接自检
# =============================================================================
# 🚩 为什么改掉旧版：旧版是【临时脚本】—— 写死了 docs/29..32 那几篇、只输出到
#    build/final-check.txt、不返回退出码。于是「加一篇文档就要手改一次清单」，
#    与 AGENTS 规则 11（别在 120 个文件里瞎翻）的精神相反。
#    → 改为【扫全目录】：新增文档自动纳入，本脚本不用改。
#
# 检查项：
#   ① 每篇 .md 的 ``` 围栏数必须是【偶数】（奇数 = 代码块没闭合，后面全被吞掉）
#   ② 篇内所有指向 .md 的相对链接必须真实存在（防 docs 重排后留下死链）
#   ③ docs/00-index.md（路由表）与 docs/reference/INDEX.md（自动索引）必须存在
#   ④ 仓库记忆文件的行数 / H1 / 节数（只报数，不算失败）
#   ⑤ 打印本轮相关文档的标题结构，便于人工核对
#
# 退出码：有失败项返回 1（便于串进 build 链）
# =============================================================================
$ErrorActionPreference = 'Stop'
$fail = 0
$out  = @()
function Say([string]$s) { $script:out += $s }

$docsRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\docs'))

Say '======== 1. 扫 docs/ 全目录 ========'
$mdFiles = @(Get-ChildItem -LiteralPath $docsRoot -Recurse -File -Filter '*.md' | Sort-Object FullName)
Say ("  共 {0} 篇 .md" -f $mdFiles.Count)
Say ''

# ---------------------------------------------------------------------------
# ① 围栏配平 + ② 相对链接
# ---------------------------------------------------------------------------
Say '======== 2. 围栏配平 + 相对链接 ========'
$linkMissing = New-Object System.Collections.Generic.List[string]
$fenceBad    = New-Object System.Collections.Generic.List[string]
$linkCount   = 0
$fenceOdd    = 0

foreach ($f in $mdFiles) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    $rel   = 'docs\' + $f.FullName.Substring($docsRoot.Length).TrimStart('\')

    # ① 围栏：`` 开头的行数必须是偶数（成对）
    $nFence = @($lines | Where-Object { $_ -match '^``' }).Count
    if ($nFence % 2 -eq 0) {
        $okF = 'OK '
    } else {
        $okF = 'FAIL'; $fail++; $fenceOdd++; $null = $fenceBad.Add($rel)
    }
    Say ("  [{0}] {1,-50} 行={2,-5} 围栏={3}" -f $okF, $rel, $lines.Count, $nFence)

    # ② 相对链接（只查指向 .md 的；跳过带协议的绝对 URL）
    foreach ($m in [regex]::Matches(($lines -join "`n"), '\]\(([^)\s]+\.md)(?:#[^)]*)?\)')) {
        $target = $m.Groups[1].Value
        if ($target -match '^[a-zA-Z]+:') { continue }
        $linkCount++
        $abs = Join-Path $f.DirectoryName ($target -replace '/', '\')
        if (-not (Test-Path -LiteralPath $abs)) {
            $fail++
            $null = $linkMissing.Add("$rel  ->  $target")
        }
    }
}
Say ''
Say ("  相对 .md 链接共 {0} 处" -f $linkCount)
if ($linkMissing.Count -gt 0) {
    Say ("  [FAIL] {0} 处死链：" -f $linkMissing.Count)
    foreach ($l in $linkMissing) { Say "      $l" }
} else {
    Say '  [OK ] 无死链'
}
Say ''

# ---------------------------------------------------------------------------
# ③ 索引入口
# ---------------------------------------------------------------------------
Say '======== 3. 索引入口 ========'
foreach ($pair in @(@('docs\00-index.md', '按任务查读哪篇（AGENTS 规则 11 的入口）'),
                    @('docs\reference\INDEX.md', '脚本 <-> 产出对照，由 gen-reference-index.ps1 生成'))) {
    $p  = Join-Path $PSScriptRoot "..\$($pair[0])"
    $ok = if (Test-Path -LiteralPath $p) { 'OK ' } else { $fail++; 'FAIL' }
    Say ("  [{0}] {1,-28} {2}" -f $ok, $pair[0], $pair[1])
}
Say ''

# ---------------------------------------------------------------------------
# ③b 编码：BOM 不许被脚本整篇重写时【静默丢掉】
# ---------------------------------------------------------------------------
# 🚩 实测（2026-09-25）：docs/ 下 102 篇编号文档里 **85 带 BOM / 17 不带**
#    （01–22 与 99 不带 BOM；23 之后新建的都带）⇒ **这里刻意【不立全局规则】**，
#    否则会对着 17 篇历史文件永远报错。
#    但 `docs/00-index.md`（路由入口）**从建库起一直带 BOM，而且经常被脚本整篇重写**
#    ⇒ 只对它做断言：被脚本丢了 BOM 就报错。
#    （本项目 2026-09-25 真踩过：用脚本重写 docs/00-index.md 时 BOM 没了，而没有一条断言发现。）
Say '======== 3b. 编码：BOM 不许静默丢失 ========'
$bomTargets = @('docs\00-index.md')
foreach ($relBom in $bomTargets) {
    $pBom = Join-Path $PSScriptRoot "..\$relBom"
    if (-not (Test-Path -LiteralPath $pBom)) {
        $fail++; Say ("  [FAIL] {0}  不存在" -f $relBom); continue
    }
    $b3 = [byte[]](Get-Content -LiteralPath $pBom -Encoding Byte -TotalCount 3)
    if ($b3.Length -eq 3 -and $b3[0] -eq 0xEF -and $b3[1] -eq 0xBB -and $b3[2] -eq 0xBF) {
        Say ("  [OK ] {0}  带 BOM" -f $relBom)
    } else {
        $fail++
        Say ("  [FAIL] {0}  丢了 BOM（用脚本整篇重写时最容易丢）" -f $relBom)
    }
}
Say ''

# ---------------------------------------------------------------------------
# ③c 体积守卫：`AGENTS.md`（**每次请求都被整篇注入**）不许再长胖
# ---------------------------------------------------------------------------
# 🚩 2026-09-25 实测：它当时 **220 KB / 125k 字符**，其中 95% 是逐轮施工记录
#    ⇒ 每轮工具往返都在为历史付钱。已把历史整段搬到 `docs/agent-log/2026-09.md`，
#    现在 **14.5 KB**。事后立了「记账纪律」（见 `AGENTS.md` 末节）：**新记录写日志，不回填**。
#    ⇒ 这里做守卫：> 30 KB 提示、> 40 KB 直接 FAIL（说明历史又被堆回来了）。
Say '======== 3c. 体积守卫：AGENTS.md（每轮都被整篇注入）========'
$agentsPath = Join-Path $PSScriptRoot '..\AGENTS.md'
if (-not (Test-Path -LiteralPath $agentsPath)) {
    $fail++; Say '  [FAIL] AGENTS.md 不存在'
} else {
    $agentsKb = [math]::Round((Get-Item -LiteralPath $agentsPath).Length / 1KB, 1)
    if ($agentsKb -gt 40) {
        $fail++
        Say ("  [FAIL] AGENTS.md = {0} KB —— 超过 40 KB 硬线。" -f $agentsKb)
        Say '         历史（逐轮记录）应写 `docs/agent-log/<YYYY-MM>.md`，本文件只留 规则 / 约定 / 状态表 / 判据速查。'
    } elseif ($agentsKb -gt 30) {
        Say ("  [WARN] AGENTS.md = {0} KB —— 已过 30 KB 目标值，下次压缩时考虑开新月份日志。" -f $agentsKb)
    } else {
        Say ("  [OK ] AGENTS.md = {0} KB（目标 <= 30 KB；历史在 docs/agent-log/）" -f $agentsKb)
    }
}
Say ''

# ---------------------------------------------------------------------------
# ③d 行尾守卫：不许出现 `\r\r\n`（CR CR LF）
# ---------------------------------------------------------------------------
# 🚩 2026-09-25 实测：用【Python 文本模式】`open(p,'a')` 追加长文档时，
#    `newline=None` 会把 `\n` 翻成 `os.linesep`（`\r\n`），内容里原有的 `\r\n`
#    就变成 `\r\r\n`（= 每行多一个 CR）。
#    ⚠️⚠️ 经典查法 `raw.count(b'\n') - raw.count(b'\r\n') == 0` **抓不到它**
#       （`\r\n` 仍匹配一次、`\n` 也匹配一次 ⇒ 差值为 0，看着是"干净的"）
#       ⇒ ✅ 必须【单独数】 `\r\r\n`。
#    本轮体检：`AGENTS.md` **280 处** · `docs/agent-log/2026-09.md` **2289 处**（两份都是被追加过的）
#    ⇒ 这里做守卫：> 0 就 FAIL（并提示归一写法）。
Say '======== 3d. 行尾守卫：不许有 CR CR LF（\r\r\n）========'
$eolTargets = @('AGENTS.md', 'docs\agent-log\2026-09.md', 'docs\99-todo-verify.md', 'docs\97-soviet-war-countdown-design.md')
foreach ($relEol in $eolTargets) {
    $pEol = Join-Path $PSScriptRoot "..\$relEol"
    if (-not (Test-Path -LiteralPath $pEol)) {
        $fail++; Say ("  [FAIL] {0}  不存在" -f $relEol); continue
    }
    $txtEol = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes($pEol))
    $nCrCr = ([regex]::Matches($txtEol, "`r`r`n")).Count
    if ($nCrCr -eq 0) {
        Say ("  [OK ] {0}  无 CR CR LF" -f $relEol)
    } else {
        $fail++
        Say ("  [FAIL] {0}  有 {1} 处 `\r\r\n`（Python 文本模式追加的产物）" -f $relEol, $nCrCr)
        Say '         归一写法：body = body.replace(b"`r", b""); 再 b"\r\n".join(body.split(b"\n"))'
    }
}
Say ''

# ---------------------------------------------------------------------------
# ④ 仓库记忆（只报数）
# ---------------------------------------------------------------------------
Say '======== 4. 仓库记忆 ========'
$mem = 'c:\Users\xuwei\AppData\Roaming\Code\User\workspaceStorage\82ec085de9c284eec1fb61bba6fa5acb\GitHub.copilot-chat\memory-tool\memories\repo\hoi4-modding.md'
if (Test-Path -LiteralPath $mem) {
    Say ('  行数={0}  H1={1}  ##节数={2}' -f (Get-Content -LiteralPath $mem).Count,
        (Select-String -LiteralPath $mem -Pattern '^# 仓库记忆').Count,
        (Select-String -LiteralPath $mem -Pattern '^## ').Count)
} else {
    Say "  （未找到记忆文件，跳过）"
}
Say ''

# ---------------------------------------------------------------------------
## ⑤ 最近改动的文档，打印标题结构（便于人工核对）
# ---------------------------------------------------------------------------
# 🚩 这里【不写死清单】—— 按修改时间取最新的 6 篇，写完一篇新文档就自动纳进来。
$watch = @(Get-ChildItem -LiteralPath $docsRoot -Recurse -File -Filter '*.md' |
           Sort-Object LastWriteTime -Descending | Select-Object -First 6 |
           ForEach-Object { 'docs\' + $_.FullName.Substring($docsRoot.Length).TrimStart('\') })
Say '======== 5. 最近改动的 6 篇文档里标题结构 ========'
foreach ($d in $watch) {
    $p = Join-Path $PSScriptRoot "..\$d"
    if (-not (Test-Path -LiteralPath $p)) { Say ("--- {0}  【不存在】" -f $d); continue }
    $L = [System.IO.File]::ReadAllLines($p)
    $c = @($L | Where-Object { $_ -match '^``' }).Count
    Say ('--- {0}  行={1} 围栏={2}{3}' -f $d, $L.Count, $c, $(if ($c % 2 -eq 0) { '' } else { '  🚩奇数！' }))
    foreach ($h in ($L | Where-Object { $_ -match '^#{2,3} ' })) { Say ('  ' + $h) }
    Say ''
}

Say ("==================== 失败项: {0} ====================" -f $fail)

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'doc-check-report.txt'), $out,
    (New-Object System.Text.UTF8Encoding($false)))
$out | ForEach-Object { Write-Output $_ }

if ($fail -gt 0) { exit 1 }

# =============================================================================
# 李可夫：找【可引用的原文】—— 第四批（2026-09-16）
#
# 已排除：
#   · 中文马克思主义文库 李可夫页 —— 不存在（5 个 URL 全 404）
#   · 英文 marxists.org  Rykov 档案 —— /archive/rykov/ 404
#   · 俄文维基语录 —— 只有 4 条，全是 1927 十五大 / 1938 审判供词，与五个节点无关
#   · 俄文维基正文的 «» 引语 —— 全是 1920 年代末的财政之争与 1929「认错」（已砍的节点）
#   · 俄文维基 АИР 那条 —— 是【后人记述】（Память 节），不是历史人物原文
#
# 剩下能走的路（AGENTS 规则 9 的第二档：历史上他人评价或记述的原文）：
#   列宁与托洛茨基都写过 1918–1926 年的经济机关 —— 找他们提到李可夫的地方。
# 另外按 docs/23 第 1b 步，非理论家可退到「命令 / 报告 / 决议」这一档。
# =============================================================================
$proxy = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\rykov\probe2'
$null = New-Item -ItemType Directory -Force -Path $outDir

$queries = [ordered]@{
    'q1_lenin_cn_rykov'  = 'site:marxists.org/chinese 李可夫'
    'q2_rykov_vsnh'      = '%22李可夫%22 最高国民经济委员会 1918'
    'q3_rykov_sto'       = '%22李可夫%22 劳动国防委员会'
    'q4_rykov_food'      = '%22李可夫%22 红军 给养 特派员'
    'q5_lenin_on_rykov'  = 'Lenin quoted Rykov %22moderate%22 1921 food supply'
}

$rows = @()
foreach ($k in $queries.Keys) {
    $f = Join-Path $outDir "$k.html"
    $url = "https://lite.duckduckgo.com/lite/?q=$($queries[$k])"
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' --max-time 60 -o $f -w '%{http_code}' $url 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $rows += ('{0,-20} {1,4} {2,8} 字节' -f $k, $code, $len)
    Write-Host $rows[-1]
}
$rows | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'fetch-rykov4-report.txt') -Encoding utf8

# 顺带把可能含李可夫的列宁文本抓下来（URL 先探，不猜）
$leninCand = [ordered]@{
    'lenin_taxinkind_1921'  = 'https://www.marxists.org/chinese/lenin/1921/04/21.htm'
    'lenin_better_1923'     = 'https://www.marxists.org/chinese/lenin/1923/03/02.htm'
    'lenin_deputies_1922'   = 'https://www.marxists.org/chinese/lenin/1922/12/26.htm'
    'lenin_coop_1923'       = 'https://www.marxists.org/chinese/lenin/1923/01/04.htm'
    'lenin_letters_congress'= 'https://www.marxists.org/chinese/lenin/1922/12/24.htm'
}
Write-Host ''
foreach ($k in $leninCand.Keys) {
    $f = Join-Path $outDir "$k.htm"
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $leninCand[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    Write-Host ('{0,-24} {1,4} {2,8} 字节' -f $k, $code, $len)
}

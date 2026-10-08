# =============================================================================
# 李可夫一手/二手材料抓取（第二批）—— 2026-09-16
# -----------------------------------------------------------------------------
# 目的：docs/29 §5.3 定案后开始实装（5 条国策），描述必须是【节选 + 出处】（AGENTS 规则 9）。
#       李可夫不是理论家 → 按 docs/23 第 1b 步走「他人记述 / 本人报告讲话」。
#       中文马克思主义文库【没有】李可夫页（docs/29 §0 已核，5 个 URL 全 404）
#       → 改抓【英文 marxists.org】的 Right Opposition 档案（里面有他本人的讲话）。
#
# ⚠️ 本机 = TUN 虚拟网卡 + 本地 HTTP 代理 127.0.0.1:7993。
#    curl / PowerShell **不读** Windows 系统代理设置 → 必须显式 -x。
# ⚠️ 一律 -o 写文件，不要管道（管道会丢二进制/编码）。
# =============================================================================
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\rykov\src2'
if (-not (Test-Path -LiteralPath $outDir)) { $null = New-Item -ItemType Directory -Path $outDir -Force }

# name -> url
$targets = [ordered]@{
    'mia_rykov_index'   = 'https://www.marxists.org/archive/rykov/index.htm'
    'mia_right_opp'     = 'https://www.marxists.org/history/etol/document/ussr/right-opposition/index.htm'
    'wiki_en_rykov'     = 'https://en.wikipedia.org/wiki/Alexei_Rykov'
    'wiki_ru_rykov'     = 'https://ru.wikipedia.org/wiki/%D0%A0%D1%8B%D0%BA%D0%BE%D0%B2,_%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B5%D0%B9_%D0%98%D0%B2%D0%B0%D0%BD%D0%BE%D0%B2%D0%B8%D1%87'
    'wiki_ru_vsnh'      = 'https://ru.wikipedia.org/wiki/%D0%92%D1%8B%D1%81%D1%88%D0%B8%D0%B9_%D1%81%D0%BE%D0%B2%D0%B5%D1%82_%D0%BD%D0%B0%D1%80%D0%BE%D0%B4%D0%BD%D0%BE%D0%B3%D0%BE_%D1%85%D0%BE%D0%B7%D1%8F%D0%B9%D1%81%D1%82%D0%B2%D0%B0'
    'wiki_ru_sto'       = 'https://ru.wikipedia.org/wiki/%D0%A1%D0%BE%D0%B2%D0%B5%D1%82_%D1%82%D1%80%D1%83%D0%B4%D0%B0_%D0%B8_%D0%BE%D0%B1%D0%BE%D1%80%D0%BE%D0%BD%D1%8B'
    'wiki_ru_odvf'      = 'https://ru.wikipedia.org/wiki/%D0%9E%D0%94%D0%92%D0%A4'
    'wiki_ru_air'       = 'https://ru.wikipedia.org/wiki/%D0%90%D0%98%D0%A0_(%D1%81%D0%B0%D0%BC%D0%BE%D0%BB%D1%91%D1%82%D1%8B)'
    'wiki_zh_alker'     = 'https://zh.wikipedia.org/wiki/%E9%98%BF%E5%88%97%E5%85%8B%E8%B0%A2%C2%B7%E6%9D%8E%E5%8F%AF%E5%A4%AB'
}

$rows = @()
foreach ($k in $targets.Keys) {
    $url = $targets[$k]
    $f   = Join-Path $outDir "$k.html"
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $url 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $rows += ('{0,-20} {1,4}  {2,8} 字节  {3}' -f $k, $code, $len, $url)
    Write-Host ('{0,-20} {1,4}  {2,8} 字节' -f $k, $code, $len)
}
$rows | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'fetch-rykov2-report.txt') -Encoding utf8
Write-Host ''
Write-Host '--- 报告已写入 build/fetch-rykov2-report.txt ---'

# =============================================================================
# 李可夫素材：第三批探测 —— 找【可引用的原文】（2026-09-16）
#
# 背景（AGENTS 规则 9）：每条国策描述必须是【节选 + 出处】，不能自撰。
#   中文马克思主义文库【没有】李可夫页（已核）
#   → 剩下三条路：① 别人对他的评价/记述原文（列宁、托洛茨基）
#                 ② 他本人的讲话/报告（英文 marxists.org 的右翼反对派档案）
#                 ③ 俄文维基语录页
# =============================================================================
$proxy = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\rykov\probe'
$null = New-Item -ItemType Directory -Force -Path $outDir

$targets = [ordered]@{
    'wq_ru_rykov'      = 'https://ru.wikiquote.org/wiki/%D0%A0%D1%8B%D0%BA%D0%BE%D0%B2,_%D0%90%D0%BB%D0%B5%D0%BA%D1%81%D0%B5%D0%B9_%D0%98%D0%B2%D0%B0%D0%BD%D0%BE%D0%B2%D0%B8%D1%87'
    'wq_en_rykov'      = 'https://en.wikiquote.org/wiki/Alexei_Rykov'
    'mia_rykov_dir'    = 'https://www.marxists.org/archive/rykov/'
    'mia_gloss_rykov'  = 'https://www.marxists.org/glossary/people/r/y.htm'
    'mia_ussr_index'   = 'https://www.marxists.org/history/ussr/index.htm'
    'ddg_rykov_speech' = 'https://html.duckduckgo.com/html/?q=site%3Amarxists.org+Rykov+right+opposition+speech'
    'ddg_rykov_cn'     = 'https://html.duckduckgo.com/html/?q=%E6%9D%8E%E5%8F%AF%E5%A4%AB+%E5%88%97%E5%AE%81+%E8%AF%84%E4%BB%B7+marxists'
    'wiki_zh_alker'    = 'https://zh.wikipedia.org/wiki/%E9%98%BF%E5%88%97%E5%85%8B%E8%B0%A2%C2%B7%E6%9D%8E%E5%8F%AF%E5%A4%AB'
}

$rows = @()
foreach ($k in $targets.Keys) {
    $f = Join-Path $outDir "$k.html"
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' --max-time 60 -o $f -w '%{http_code}' $targets[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $line = ('{0,-18} {1,4} {2,8} 字节' -f $k, $code, $len)
    $rows += $line
    Write-Host $line
}
$rows | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'fetch-rykov3-report.txt') -Encoding utf8

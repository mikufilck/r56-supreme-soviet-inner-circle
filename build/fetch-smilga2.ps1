# 斯米尔加（Idx 10）材料抓取 · 第 2 批
#  ① 维基【源码】(wikitext) —— 要外部链接与参考文献的原始 URL（`Справочник по истории КПСС` 有完整职务年表）
#  ② 英文马克思主义文库 —— 有没有他（或托洛茨基写他的篇章）
#  ③ 机构条目（docs/23 教训：「历任/首任/任期」查【机构】条目，不查人物条目）
# 网络必须显式走代理 127.0.0.1:7993
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smilga\src'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$script:log = @()

function Curl-To {
    param([string]$Url, [string]$File)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $File -w '%{http_code}' $Url 2>$null
    $l = if (Test-Path -LiteralPath $File) { (Get-Item -LiteralPath $File).Length } else { 0 }
    return @{ Code = "$c"; Len = $l }
}

function Wiki-Wikitext {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rvslots=main&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '-wt.json')
    $r  = Curl-To -Url $u -File $jf
    $script:log += ('  [{0}] HTTP {1}  {2:N0} 字节' -f $Tag, $r.Code, $r.Len)
    if ($r.Code -ne '200' -or $r.Len -lt 200) { return }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            $c = $p.Value.revisions[0].slots.main.'*'
            if ($c) {
                [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '-wt.txt')), $c, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('      -> {0}-wt.txt  {1:N0} 字符' -f $Tag, $c.Length)
                # 抽外链
                $links = @()
                foreach ($m in [regex]::Matches($c, '(?i)\[\s*(https?://[^\s\]]+)\s*([^\]]*)\]')) { $links += $m.Groups[1].Value }
                foreach ($m in [regex]::Matches($c, '(?i)\{\{\s*cite\s+web[^}]*url\s*=\s*([^|}\s]+)')) { $links += $m.Groups[1].Value }
                $links = @($links | Sort-Object -Unique)
                [System.IO.File]::WriteAllLines((Join-Path $outDir ($Tag + '-links.txt')), $links, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('      外链 {0} 条 -> {1}-links.txt' -f $links.Count, $Tag)
            }
        }
    } catch { $script:log += ('      JSON 解析失败：' + $_.Exception.Message) }
}

function Wiki-Extract {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $r  = Curl-To -Url $u -File $jf
    $script:log += ('  [{0}] HTTP {1}  {2:N0} 字节  <- {3}' -f $Tag, $r.Code, $r.Len, $Title)
    if ($r.Code -ne '200' -or $r.Len -lt 200) { return }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            if ($p.Value.extract) {
                [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('      -> {0}.txt  {1:N0} 字符   条目 = {2}' -f $Tag, $p.Value.extract.Length, $p.Value.title)
            }
        }
    } catch { $script:log += ('      JSON 解析失败：' + $_.Exception.Message) }
}

# ---- ① wikitext ----
$script:log += '=== ① 维基源码 ==='
Wiki-Wikitext -Lang 'ru' -Title 'Смилга, Ивар Тенисович' -Tag 'ru'
Wiki-Wikitext -Lang 'en' -Title 'Ivar Smilga'             -Tag 'en'

# ---- ② 英文马克思主义文库 ----
$script:log += '=== ② 英文马克思主义文库 ==='
foreach ($u in @('https://www.marxists.org/archive/smilga/index.htm',
                 'https://www.marxists.org/glossary/people/s/m.htm')) {
    $f = Join-Path $outDir ('miaen-' + [Math]::Abs($u.GetHashCode() % 983) + '.html')
    $r = Curl-To -Url $u -File $f
    $script:log += ('  HTTP {0}  {1:N0} 字节  <- {2}' -f $r.Code, $r.Len, $u)
    if ($r.Code -eq '200' -and $r.Len -gt 500 -and $u -match 'glossary') {
        $txt = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
        foreach ($m in [regex]::Matches($txt, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+)"?[^>]*>(.*?)</a>')) {
            $t2 = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
            if ($t2 -match '(?i)smilga') { $script:log += ('      ⭐ {0}  ->  {1}' -f $t2, $m.Groups[1].Value) }
        }
    }
}

# ---- ③ 机构条目（职务年表）----
$script:log += '=== ③ 机构条目（历任 / 首任 / 任期）==='
$null = Wiki-Extract -Lang 'ru' -Title 'Высший совет народного хозяйства СССР'        -Tag 'inst-vsnkh'
$null = Wiki-Extract -Lang 'ru' -Title 'Государственный плановый комитет СССР'        -Tag 'inst-gosplan'
$null = Wiki-Extract -Lang 'ru' -Title 'Революционный военный совет'                   -Tag 'inst-rvsr'
$null = Wiki-Extract -Lang 'ru' -Title 'Центральное статистическое управление СССР'    -Tag 'inst-csu'
$null = Wiki-Extract -Lang 'ru' -Title 'Московский институт народного хозяйства'       -Tag 'inst-minh'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga2-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

# 施利亚普尼科夫（Idx 13）材料抓取 · 第 1 批
#  ① zh 维基 search API —— ⭐ 上一轮教训：条目名猜不到时先 search
#  ② 维基 ru/en/zh 全文 —— 要【完整职务年表】
#  ③ 中文马克思主义文库：他有没有【篇目页】（三/四种拼法）
#  ④ 机构 / 事件条目（docs/23 教训：「历任/首任/任期」查【机构】条目）
#      〈Рабочая оппозиция〉工人反对派是【他自己的纲领】—— 最关键的一条
#      〈Кронштадтское восстание〉喀琅施塔得（他 1921 是镇压者之一？）
#      〈Всесоюзный центральный совет профессиональных союзов〉ВЦСПС 历任
# 蓝本：build/fetch-ryutin.ps1 ｜ 网络必须显式走代理 127.0.0.1:7993
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\shlyapnikov\src'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$script:log = @()

function Curl-To {
    param([string]$Url, [string]$File)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $File -w '%{http_code}' $Url 2>$null
    $l = if (Test-Path -LiteralPath $File) { (Get-Item -LiteralPath $File).Length } else { 0 }
    return @{ Code = "$c"; Len = $l }
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
            } else { $script:log += '      条目存在但 extract 为空' }
        }
    } catch { $script:log += ('      JSON 解析失败：' + $_.Exception.Message) }
}

function Decode-Bytes {
    param([byte[]]$Bytes)
    try {
        $enc = [System.Text.Encoding]::GetEncoding('utf-8',
               [System.Text.EncoderFallback]::ExceptionFallback,
               [System.Text.DecoderFallback]::ExceptionFallback)
        return $enc.GetString($Bytes)
    } catch { return [System.Text.Encoding]::GetEncoding(936).GetString($Bytes) }
}

# ---- ① zh 维基 search API ----
$script:log += '=== ① zh 维基 search API ==='
foreach ($kw in @('工人反对派', '什利亚普尼科夫', '施利亚普尼科夫', '亚·加·施略普尼柯夫')) {
    $u = 'https://zh.wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=8&srsearch=' +
         [uri]::EscapeDataString($kw)
    $f = Join-Path $outDir ('zhsearch-' + [Math]::Abs($kw.GetHashCode() % 997) + '.json')
    $r = Curl-To -Url $u -File $f
    $script:log += ('  [搜索 {0}] HTTP {1}  {2:N0} 字节' -f $kw, $r.Code, $r.Len)
    if ($r.Code -eq '200' -and $r.Len -gt 100) {
        $txt = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
        $titles = @([regex]::Matches($txt, '"title":"(.*?)"') | ForEach-Object { $_.Groups[1].Value })
        foreach ($t in $titles) { $script:log += ('      命中： ' + $t) }
        [System.IO.File]::WriteAllLines((Join-Path $outDir ('zhsearch-' + $kw + '.txt')), $titles, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# ---- ② 维基全文 ----
$script:log += '=== ② 维基全文 ==='
Wiki-Extract -Lang 'ru' -Title 'Шляпников, Александр Гаврилович' -Tag 'ru'
Wiki-Extract -Lang 'en' -Title 'Alexander Shlyapnikov'            -Tag 'en'
Wiki-Extract -Lang 'zh' -Title '亚历山大·什利亚普尼科夫'          -Tag 'zh-a'
Wiki-Extract -Lang 'zh' -Title '工人反对派'                       -Tag 'zh-oppos'

# ---- ③ 中文马克思主义文库 ----
$script:log += '=== ③ 中文马克思主义文库 ==='
foreach ($u in @('https://www.marxists.org/chinese/shlyapnikov/index.htm',
                 'https://www.marxists.org/chinese/shiliapnikov/index.htm',
                 'https://www.marxists.org/chinese/gongrenfanduipai/index.htm',
                 'https://www.marxists.org/chinese/workers-opposition/index.htm')) {
    $f = Join-Path $outDir ('mia-' + [Math]::Abs($u.GetHashCode() % 997) + '.html')
    $r = Curl-To -Url $u -File $f
    $script:log += ('  HTTP {0}  {1:N0} 字节  <- {2}' -f $r.Code, $r.Len, $u)
    if ($r.Code -eq '200' -and $r.Len -gt 500) {
        $txt = Decode-Bytes ([System.IO.File]::ReadAllBytes($f))
        $links = @()
        foreach ($m in [regex]::Matches($txt, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+)"?[^>]*>(.*?)</a>')) {
            $href = $m.Groups[1].Value
            $t2 = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
            if ($href -match '\.htm' -and $href -notmatch '^(#|mailto|javascript)') { $links += ('{0}  ->  {1}' -f $t2, $href) }
        }
        $script:log += ('  ⭐ 抽到 {0} 条篇目链接' -f $links.Count)
        [System.IO.File]::WriteAllLines((Join-Path $outDir 'mia-links.txt'), $links, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# ---- ④ 机构 / 事件条目 ----
$script:log += '=== ④ 机构 / 事件条目 ==='
Wiki-Extract -Lang 'ru' -Title 'Рабочая оппозиция'                        -Tag 'inst-rabopp'
Wiki-Extract -Lang 'ru' -Title 'Кронштадтское восстание'                  -Tag 'inst-kronstadt'
Wiki-Extract -Lang 'ru' -Title 'Всесоюзный центральный совет профессиональных союзов' -Tag 'inst-vcsps'
Wiki-Extract -Lang 'ru' -Title 'Народный комиссариат труда РСФСР'         -Tag 'inst-narkomtrud'
Wiki-Extract -Lang 'ru' -Title 'Металлисты (профсоюз)'                    -Tag 'inst-metal'
Wiki-Extract -Lang 'ru' -Title 'Первый съезд Советов СССР'                -Tag 'inst-sov1'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-shlyapnikov-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $script:log.Count + ' 行')

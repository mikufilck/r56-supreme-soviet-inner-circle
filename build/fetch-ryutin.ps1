# 里亚京（Idx 12）材料抓取 · 第 1 批
#  ① 维基 ru/en/zh 全文 —— 要【完整职务年表】
#  ② 中文马克思主义文库：他有没有【篇目页】
#  ③ 机构 / 事件条目（docs/23 教训：「历任/首任/任期」查【机构】条目）
#      〈Рютин〉《里亚京平台》是 1932 年那份著名文件 —— 单独抓
#      〈Союз марксистов-ленинцев〉马克思主义者-列宁主义者联盟（他 1932 年组织的）
#      〈Рютинская платформа〉
# 蓝本：build/fetch-tomsky.ps1 ｜ 网络必须显式走代理 127.0.0.1:7993
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\ryutin\src'
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

# ---- ① 维基 ----
$script:log += '=== ① 维基全文 ==='
Wiki-Extract -Lang 'ru' -Title 'Рютин, Мартемьян Никитич' -Tag 'ru'
Wiki-Extract -Lang 'en' -Title 'Martemyan Ryutin'          -Tag 'en'
Wiki-Extract -Lang 'zh' -Title '马尔捷米扬·留京'            -Tag 'zh'
Wiki-Extract -Lang 'zh' -Title '马尔特米扬·里亚京'          -Tag 'zh2'

# ---- ② 中文马克思主义文库 ----
$script:log += '=== ② 中文马克思主义文库 ==='
foreach ($u in @('https://www.marxists.org/chinese/ryutin/index.htm',
                 'https://www.marxists.org/chinese/liuting/index.htm')) {
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
        break
    }
}

# ---- ③ 机构 / 事件条目 ----
$script:log += '=== ③ 机构 / 事件条目 ==='
Wiki-Extract -Lang 'ru' -Title 'Рютинская платформа'                -Tag 'inst-platform'
Wiki-Extract -Lang 'ru' -Title 'Союз марксистов-ленинцев'           -Tag 'inst-union'
Wiki-Extract -Lang 'en' -Title 'Ryutin Affair'                      -Tag 'inst-affair'
Wiki-Extract -Lang 'ru' -Title 'Краснопресненский район'            -Tag 'inst-krasnaya-presnya'
Wiki-Extract -Lang 'ru' -Title 'Сибирский краевой комитет ВКП(б)'   -Tag 'inst-sibkraykom'
# 他 1928–1930 是西伯利亚边疆区党委第一书记 —— 机构条目可给精确任期
Wiki-Extract -Lang 'ru' -Title 'Восточно-Сибирский край'            -Tag 'inst-eastsib'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-ryutin-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $script:log.Count + ' 行')

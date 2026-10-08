# 里亚京（Idx 12）材料抓取 · 第 2 批 —— 中文源
#  ① zh 维基：先用 search API 找条目（前面直接查条目名 404）
#  ② 中文马克思主义文库：柳廷 / 留京 / 里亚京 三种拼法
#  ③ 《斯大林评传》中译本里他出现的地方（tmp/smilga/txt 已落盘 04..19 章）—— 复核
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
foreach ($kw in @('柳廷', '留京', '里亚京', '柳廷事件')) {
    $u = 'https://zh.wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=8&srsearch=' +
         [uri]::EscapeDataString($kw)
    $f = Join-Path $outDir ('zhsearch-' + [Math]::Abs($kw.GetHashCode() % 997) + '.json')
    $r = Curl-To -Url $u -File $f
    $script:log += ('  [搜索 {0}] HTTP {1}  {2:N0} 字节' -f $kw, $r.Code, $r.Len)
    if ($r.Code -eq '200' -and $r.Len -gt 100) {
        $txt = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
        $titles = @([regex]::Matches($txt, '"title":"(.*?)"') | ForEach-Object { $_.Groups[1].Value })
        foreach ($t in $titles) { $script:log += ('      命中条目： ' + $t) }
        [System.IO.File]::WriteAllLines((Join-Path $outDir ('zhsearch-' + $kw + '.txt')), $titles, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# ---- ② 中文马克思主义文库 ----
$script:log += '=== ② 中文马克思主义文库 ==='
foreach ($u in @('https://www.marxists.org/chinese/liuting/index.htm',
                 'https://www.marxists.org/chinese/ryutin/index.htm',
                 'https://www.marxists.org/chinese/liujing/index.htm')) {
    $f = Join-Path $outDir ('mia2-' + [Math]::Abs($u.GetHashCode() % 997) + '.html')
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
        [System.IO.File]::WriteAllLines((Join-Path $outDir 'mia2-links.txt'), $links, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# ---- ③ 相关条目（中文维基可能没有 → 补英文机构条目）----
$script:log += '=== ③ 补充条目 ==='
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
Wiki-Extract -Lang 'ru' -Title 'Союзкино'                -Tag 'inst-soyuzkino'
Wiki-Extract -Lang 'ru' -Title 'Красная звезда (газета)' -Tag 'inst-krasnaya-zvezda'
Wiki-Extract -Lang 'ru' -Title 'Угланов, Николай Александрович' -Tag 'p-uglanov'
Wiki-Extract -Lang 'ru' -Title 'Каюров, Василий Николаевич'     -Tag 'p-kayurov'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-ryutin2-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $script:log.Count + ' 行')

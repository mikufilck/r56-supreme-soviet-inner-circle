# 列昂尼德·彼得罗维奇·谢列布里亚科夫（Idx 7）
#  ① 俄/英维基全文 —— 要的是【完整职务年表】（俄文维基通常比中/英都细）
#  ② 中文马克思主义文库目录 —— 他有没有篇目页（非理论家多半没有）
# 蓝本：build/fetch-smirnov.ps1 ｜ 网络必须显式走代理 127.0.0.1:7993
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\sereb\wiki'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$script:log = @()

function Curl-To {
    param([string]$Url, [string]$File)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $File -w '%{http_code}' $Url 2>$null
    $l = if (Test-Path -LiteralPath $File) { (Get-Item -LiteralPath $File).Length } else { 0 }
    return @{ Code = "$c"; Len = $l }
}

function Wiki-Fetch {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $r  = Curl-To -Url $u -File $jf
    $script:log += ('  {0,-4} HTTP {1}  {2:N0} 字节   <- {3}' -f $Tag, $r.Code, $r.Len, $Title)
    if ($r.Code -ne '200' -or $r.Len -lt 200) { return $false }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            if ($p.Value.extract) {
                $tf = Join-Path $outDir ($Tag + '.txt')
                [System.IO.File]::WriteAllText($tf, $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('       -> {0}.txt  {1:N0} 字符   条目名 = {2}' -f $Tag, $p.Value.extract.Length, $p.Value.title)
                return $true
            }
        }
        $script:log += '       条目存在但 extract 为空'
    } catch { $script:log += ('       JSON 解析失败：' + $_.Exception.Message) }
    return $false
}

function Wiki-Search {
    param([string]$Lang, [string]$Query, [string]$Tag)
    $sf = Join-Path $outDir ($Tag + '-search.json')
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=6&srsearch=" +
          [uri]::EscapeDataString($Query)
    $r  = Curl-To -Url $u -File $sf
    $script:log += ('  search HTTP {0}  {1:N0} 字节' -f $r.Code, $r.Len)
    if ($r.Len -lt 50) { return $null }
    try {
        $j = [System.IO.File]::ReadAllText($sf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($s in $j.query.search) { $script:log += ('      命中: ' + $s.title) }
        if ($j.query.search.Count -gt 0) { return $j.query.search[0].title }
    } catch { $script:log += ('       search JSON 解析失败：' + $_.Exception.Message) }
    return $null
}

# ---- ① 按条目名直取 ----
$script:log += '=== ① 按条目名直取 ==='
$okRu = Wiki-Fetch -Lang 'ru' -Title 'Серебряков, Леонид Петрович' -Tag 'ru'
$okEn = Wiki-Fetch -Lang 'en' -Title 'Leonid Serebryakov'          -Tag 'en'

# ---- ② 直取失败则先用 search API 找条目名 ----
if (-not $okRu) {
    $script:log += '=== ② ru search API ==='
    $t = Wiki-Search -Lang 'ru' -Query 'Серебряков Леонид Петрович' -Tag 'ru'
    if ($t) { $okRu = Wiki-Fetch -Lang 'ru' -Title $t -Tag 'ru' }
}
if (-not $okEn) {
    $script:log += '=== ② en search API ==='
    $t = Wiki-Search -Lang 'en' -Query 'Leonid Serebryakov' -Tag 'en'
    if ($t) { $okEn = Wiki-Fetch -Lang 'en' -Title $t -Tag 'en' }
}

# ---- ③ 中文马克思主义文库目录：有没有他的篇目页 ----
$script:log += '=== ③ 中文马克思主义文库目录 ==='
$idx = Join-Path $outDir 'mia-index.html'
$r   = Curl-To -Url 'https://www.marxists.org/chinese/index.html' -File $idx
$script:log += ('  文库目录 HTTP {0}  {1:N0} 字节' -f $r.Code, $r.Len)
$hits = @()
if ($r.Len -gt 0) {
    $html = [System.IO.File]::ReadAllText($idx, [System.Text.Encoding]::GetEncoding(936))
    foreach ($m in [regex]::Matches($html, '(?is)<a\s+[^>]*href\s*=\s*"([^"]+)"[^>]*>(.*?)</a>')) {
        $href = $m.Groups[1].Value
        $text = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
        if ($text -match '谢列布里亚科夫' -or $href -match 'sereb') { $hits += ('{0}  ->  {1}' -f $text, $href) }
    }
    $script:log += ('  「谢列布里亚科夫」命中 {0} 条' -f $hits.Count)
}

$all = @('=== 抓取报告（谢列布里亚科夫）===') + $script:log + @('') + @('=== 文库中文目录命中 ===') + $hits
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-sereb-report.txt'), $all, (New-Object System.Text.UTF8Encoding($false)))
Write-Host '报告 -> fetch-sereb-report.txt'

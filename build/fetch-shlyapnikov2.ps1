# 施利亚普尼科夫（Idx 13）材料抓取 · 第 2 批 —— 中文源
#  ① 中文马克思主义文库：柯伦泰（与她同组）、工人反对派
#  ② 中文文库：列宁《论工会》系列（含对「工人反对派」的中文批评表述）
#  ③ zh 维基 search：柯伦泰 / 十人纲领 / 工会讨论
#  ④ 另外两位领袖（Lutovinov / Medvedev）—— 划清「谁是谁」
# 蓝本：build/fetch-ryutin2.ps1 ｜ 网络必须显式走代理 127.0.0.1:7993
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\shlyapnikov\src'
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

# ---- ① 中文马克思主义文库 ----
$script:log += '=== ① 中文马克思主义文库 ==='
foreach ($u in @('https://www.marxists.org/chinese/kollontai/index.htm',
                 'https://www.marxists.org/chinese/alexandra-kollontai/index.htm',
                 'https://www.marxists.org/chinese/workers-opposition/index.htm',
                 'https://www.marxists.org/chinese/lenin/1920/12/index.htm')) {
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
        [System.IO.File]::WriteAllLines((Join-Path $outDir ('mia2-links-' + [Math]::Abs($u.GetHashCode() % 97) + '.txt')), $links, (New-Object System.Text.UTF8Encoding($false)))
    }
}

# ---- ② zh 维基 search ----
$script:log += '=== ② zh 维基 search ==='
foreach ($kw in @('柯伦泰', '十人纲领', '工会讨论', '俄共（布）第十次代表大会')) {
    $u = 'https://zh.wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=8&srsearch=' +
         [uri]::EscapeDataString($kw)
    $f = Join-Path $outDir ('zhsearch2-' + [Math]::Abs($kw.GetHashCode() % 997) + '.json')
    $r = Curl-To -Url $u -File $f
    $script:log += ('  [搜索 {0}] HTTP {1}' -f $kw, $r.Code)
    if ($r.Code -eq '200' -and $r.Len -gt 100) {
        $txt = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
        $titles = @([regex]::Matches($txt, '"title":"(.*?)"') | ForEach-Object { $_.Groups[1].Value })
        foreach ($t in $titles) { $script:log += ('      命中： ' + $t) }
    }
}

# ---- ③ 维基补充条目 ----
$script:log += '=== ③ 维基补充条目 ==='
Wiki-Extract -Lang 'zh' -Title '亚历山德拉·柯伦泰'          -Tag 'zh-kollontai'
Wiki-Extract -Lang 'ru' -Title 'Лутовинов, Юрий Христофорович' -Tag 'p-lutovinov'
Wiki-Extract -Lang 'ru' -Title 'Медведев, Сергей Павлович'     -Tag 'p-medvedev'
Wiki-Extract -Lang 'ru' -Title 'Невский, Владимир Иванович'    -Tag 'p-nevsky'
Wiki-Extract -Lang 'zh' -Title '工人反对派'                    -Tag 'zh-oppos2'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-shlyapnikov2-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $script:log.Count + ' 行')

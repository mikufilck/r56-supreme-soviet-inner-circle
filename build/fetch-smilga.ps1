# 斯米尔加（Idx 10）材料抓取 · 第 1 批
#  ① 维基 ru/en/zh 全文 —— 要【完整职务年表】
#  ② 中文马克思主义文库：他有没有【篇目页】（docs/28 §135 记他「中英双全」）
# 蓝本：build/fetch-radek.ps1 ｜ 网络必须显式走代理 127.0.0.1:7993
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

function Wiki-Extract {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $r  = Curl-To -Url $u -File $jf
    $script:log += ('  [{0}] HTTP {1}  {2:N0} 字节  <- {3}' -f $Tag, $r.Code, $r.Len, $Title)
    if ($r.Code -ne '200' -or $r.Len -lt 200) { return $false }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            if ($p.Value.extract) {
                [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('      -> {0}.txt  {1:N0} 字符   条目 = {2}' -f $Tag, $p.Value.extract.Length, $p.Value.title)
                return $true
            }
        }
        $script:log += '      条目存在但 extract 为空'
    } catch { $script:log += ('      JSON 解析失败：' + $_.Exception.Message) }
    return $false
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
$null = Wiki-Extract -Lang 'ru' -Title 'Смилга, Ивар Тенисович'  -Tag 'ru'
$null = Wiki-Extract -Lang 'en' -Title 'Ivar Smilga'              -Tag 'en'
$null = Wiki-Extract -Lang 'zh' -Title '伊瓦尔·斯米尔加'          -Tag 'zh'
$null = Wiki-Extract -Lang 'zh' -Title '伊瓦爾·斯米爾加'          -Tag 'zh-tw'

# ---- ② 中文马克思主义文库：人物页 ----
$script:log += '=== ② 中文马克思主义文库 ==='
foreach ($u in @('https://www.marxists.org/chinese/smilga/index.htm',
                 'https://www.marxists.org/chinese/ivar-smilga/index.htm',
                 'https://www.marxists.org/chinese/smilga/index.html')) {
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
        $script:log += ('  抽到 {0} 条篇目链接' -f $links.Count)
        [System.IO.File]::WriteAllLines((Join-Path $outDir 'mia-links.txt'), $links, (New-Object System.Text.UTF8Encoding($false)))
        [System.IO.File]::WriteAllText((Join-Path $outDir 'mia-index.txt'), $txt, (New-Object System.Text.UTF8Encoding($false)))
        break
    }
}

# ---- ③ 文库总索引里找「斯米尔加」 ----
$script:log += '=== ③ 文库索引检索 ==='
foreach ($u in @('https://www.marxists.org/chinese/index.html',
                 'https://www.marxists.org/chinese/maoindex/index.htm',
                 'https://www.marxists.org/chinese/subject/soviet/index.htm')) {
    $f = Join-Path $outDir ('miaidx-' + [Math]::Abs($u.GetHashCode() % 991) + '.html')
    $r = Curl-To -Url $u -File $f
    $script:log += ('  HTTP {0}  {1:N0} 字节  <- {2}' -f $r.Code, $r.Len, $u)
    if ($r.Code -eq '200' -and $r.Len -gt 500) {
        $txt = Decode-Bytes ([System.IO.File]::ReadAllBytes($f))
        $hits = @()
        foreach ($m in [regex]::Matches($txt, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+)"?[^>]*>(.*?)</a>')) {
            $t2 = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
            if ($t2 -match '斯米尔加|斯米爾加') { $hits += ('{0}  ->  {1}' -f $t2, $m.Groups[1].Value) }
        }
        if ($hits.Count -gt 0) {
            $script:log += ('  ⭐ 命中 {0} 条：' -f $hits.Count)
            foreach ($h in $hits) { $script:log += ('      ' + $h) }
        }
    }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

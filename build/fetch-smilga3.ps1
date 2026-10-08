# 斯米尔加（Idx 10）材料抓取 · 第 3 批
#  ① Справочник по истории КПСС（knowbysight.info）人物页 —— ⭐ 完整职务年表
#  ② 机构条目补充：ВСНХ РСФСР（en 维基说他 1921-1928 是副主席，ru 说只是主席团委员 → 要核实）
#  ③ 背景条目：Трудовые армии（劳动军 —— 他反对的那件事）
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

function Decode-Bytes {
    param([byte[]]$Bytes)
    try {
        $enc = [System.Text.Encoding]::GetEncoding('utf-8',
               [System.Text.EncoderFallback]::ExceptionFallback,
               [System.Text.DecoderFallback]::ExceptionFallback)
        return $enc.GetString($Bytes)
    } catch { return [System.Text.Encoding]::GetEncoding(1251).GetString($Bytes) }
}

# ---- ① knowbysight 人物页 ----
$script:log += '=== ① Справочник по истории КПСС（人物页）==='
$u = 'http://www.knowbysight.info/2_KPSS/07178.asp'
$f = Join-Path $outDir 'knowbysight.html'
$r = Curl-To -Url $u -File $f
$script:log += ('  HTTP {0}  {1:N0} 字节  <- {2}' -f $r.Code, $r.Len, $u)
if ($r.Code -eq '200' -and $r.Len -gt 500) {
    $txt = Decode-Bytes ([System.IO.File]::ReadAllBytes($f))
    # 保留换行，去标签
    $t2 = $txt -replace '(?i)<br\s*/?>', "`n" -replace '(?i)</p>', "`n" -replace '(?i)</tr>', "`n" -replace '(?i)<[^>]+>', ' '
    $t2 = $t2 -replace '&nbsp;', ' ' -replace '&amp;', '&' -replace '&laquo;', '«' -replace '&raquo;', '»'
    $lines = @($t2 -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    [System.IO.File]::WriteAllLines((Join-Path $outDir 'knowbysight.txt'), $lines, (New-Object System.Text.UTF8Encoding($false)))
    $script:log += ('      抽出 {0} 行 -> knowbysight.txt' -f $lines.Count)
}

function Wiki-Extract {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u2 = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $r2 = Curl-To -Url $u2 -File $jf
    $script:log += ('  [{0}] HTTP {1}  {2:N0} 字节  <- {3}' -f $Tag, $r2.Code, $r2.Len, $Title)
    if ($r2.Code -ne '200' -or $r2.Len -lt 200) { return }
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

# ---- ② 机构 / 背景 ----
$script:log += '=== ② 机构与背景条目 ==='
Wiki-Extract -Lang 'ru' -Title 'Высший совет народного хозяйства РСФСР'      -Tag 'inst-vsnkh-rsfsr'
Wiki-Extract -Lang 'ru' -Title 'Трудовые армии'                             -Tag 'bg-labor-army'
Wiki-Extract -Lang 'ru' -Title 'Левая оппозиция в РКП(б)'                   -Tag 'bg-left-opp'
Wiki-Extract -Lang 'en' -Title 'Left Opposition'                            -Tag 'bg-left-opp-en'
Wiki-Extract -Lang 'ru' -Title 'Главное управление по топливу'             -Tag 'inst-glavtop'
Wiki-Extract -Lang 'ru' -Title 'Минусинская ссылка'                         -Tag 'bg-minusinsk'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga3-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

# 把抓到的 JSON 转成纯文本（加里宁 Idx 14）
$ErrorActionPreference = 'Continue'
$ws = Split-Path $PSScriptRoot -Parent
$dst = Join-Path $ws 'tmp\kalinin'
$txt = Join-Path $dst 'txt'
if (-not (Test-Path $txt)) { New-Item -ItemType Directory -Path $txt -Force | Out-Null }

$out = @()

function Save-Extract($jsonPath, $outPath, $label) {
    if (-not (Test-Path $jsonPath)) { return "  (缺) $jsonPath" }
    try {
        $j = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch { return "  ❌ $label 解析失败：$($_.Exception.Message)" }
    $pages = $j.query.pages
    $lines = @()
    foreach ($p in $pages.PSObject.Properties) {
        $pg = $p.Value
        $lines += ('### ' + $label + ' :: ' + $pg.title)
        $lines += ''
        if ($pg.extract) { $lines += $pg.extract } else { $lines += '(无 extract)' }
        $lines += ''
    }
    [System.IO.File]::WriteAllLines($outPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
    return ('  已写 ' + $outPath + '  ' + (Get-Item $outPath).Length + ' 字节')
}

$map = @(
    @{ J = 'wiki\zh-extract.json';                O = 'zh-wiki.txt';            L = 'zh 维基' },
    @{ J = 'wiki\en-extract.json';                O = 'en-wiki.txt';            L = 'en 维基' },
    @{ J = 'wiki\ru-extract.json';                O = 'ru-wiki.txt';            L = 'ru 维基' },
    @{ J = 'inst\ru-cik-ussr.json';               O = 'inst-cik-ussr.txt';      L = 'ru 机构·苏联中央执行委员会' },
    @{ J = 'inst\ru-vcik-rsfsr.json';             O = 'inst-vcik-rsfsr.txt';    L = 'ru 机构·全俄中央执行委员会' },
    @{ J = 'inst\ru-presidium-vs.json';           O = 'inst-presidium-vs.txt';  L = 'ru 机构·最高苏维埃主席团' },
    @{ J = 'inst\en-vecik-rsfsr.json';            O = 'inst-en-vecik.txt';      L = 'en 机构·全俄中央执行委员会' },
    @{ J = 'inst\zh-zhongyang-zhiwei.json';       O = 'inst-zh-vcik.txt';       L = 'zh 机构·全俄中央执行委员会' }
)
foreach ($m in $map) {
    $r = Save-Extract (Join-Path $dst $m.J) (Join-Path $txt $m.O) $m.L
    $out += $r
}

# 中文文库首页里的链接（找有没有加里宁的篇目页）
$mi = Join-Path $dst 'wiki\cn-mia-index.htm'
if (Test-Path $mi) {
    $h = [System.IO.File]::ReadAllText($mi, [System.Text.Encoding]::GetEncoding('gb18030'))
    $out += ''
    $out += '=== 中文文库首页里所有 href（找 kalinin / 加里宁）==='
    $ms = [regex]::Matches($h, '(?i)href\s*=\s*"([^"#]+)"')
    $seen = @{}
    foreach ($m in $ms) {
        $v = $m.Groups[1].Value
        if (-not $seen.ContainsKey($v)) { $seen[$v] = 1; $out += ('  ' + $v) }
    }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'kalinin-extract-report.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $out.Count + ' 行')

# SOP 第 0 步（补）· 抓一手材料 + 定位 idea 定义
# 目标人物：米哈伊尔·伊万诺维奇·加里宁（Idx 14）
# 🚩 网络：TUN + 本地 HTTP 代理 127.0.0.1:7993，curl 必须显式 -x
# 🚩 curl 用 -o 直接写文件（别让 PowerShell 按行拆数组）
$ErrorActionPreference = 'Continue'

$V = 'F:\Hearts of Iron IV'
$R = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$ws = Split-Path $PSScriptRoot -Parent
$dst = Join-Path $ws 'tmp\kalinin'
foreach ($d in @($dst, (Join-Path $dst 'txt'), (Join-Path $dst 'wiki'), (Join-Path $dst 'inst'))) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$out = @()
$out += '==== 加里宁 第 0 步补扫 + 一手材料抓取 ===='
$out += ('时间：' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$out += ''

# ============================================================ 1. idea mikhail_kalinin 定义在哪
$out += '==================== 1. idea mikhail_kalinin 的定义位置 ===================='
foreach ($root in @($V, $R)) {
    $id = Join-Path $root 'common\ideas'
    if (Test-Path $id) {
        $m = @(Select-String -Path (Join-Path $id '*.txt') -Pattern 'mikhail_kalinin' -ErrorAction SilentlyContinue)
        $out += "  [common\ideas\*.txt] $root → $($m.Count) 处"
    }
}
# 全盘（含 dlc）搜 idea 名
foreach ($root in @($V, (Join-Path $V 'dlc'), $R)) {
    if (-not (Test-Path $root)) { continue }
    $files = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter *.txt -ErrorAction SilentlyContinue |
               Where-Object { $_.FullName -match '\\common\\ideas\\' } |
               Select-Object -ExpandProperty FullName)
    if ($files.Count -eq 0) { $out += "  [common\ideas 递归] $root → 无文件"; continue }
    $m = @(Select-String -Path $files -Pattern '\bmikhail_kalinin\b' -ErrorAction SilentlyContinue)
    $out += "  [common\ideas 递归] $root → $($m.Count) 处 / $($files.Count) 文件"
    foreach ($x in $m) {
        $out += ('    ' + $x.Path.Replace($root + '\', '') + ':' + $x.LineNumber)
        $out += ('        ' + $x.Line.Trim())
    }
}
$out += ''

# ============================================================ 2. 原版 00_traits.txt 有没有他的专属特质
$out += '==================== 2. 专属领袖特质检查（00_traits.txt）===================='
foreach ($root in @($V, $R)) {
    $tf = Join-Path $root 'common\country_leader\00_traits.txt'
    if (-not (Test-Path $tf)) { $out += "  (缺) $tf"; continue }
    $m = @(Select-String -Path $tf -Pattern 'kalinin' -ErrorAction SilentlyContinue)
    $out += "  $root → $($m.Count) 处"
    foreach ($x in $m) { $out += ('    ' + $x.LineNumber + ': ' + $x.Line.Trim()) }
}
$out += ''

# ============================================================ 3. 网络探测
$out += '==================== 3. 网络探测 ===================='
$proxy = 'http://127.0.0.1:7993'
foreach ($u in @('https://www.baidu.com', 'https://zh.wikipedia.org', 'https://www.marxists.org')) {
    $code = & curl.exe -s -o NUL -w '%{http_code}' -x $proxy --max-time 20 $u 2>$null
    $rc = $LASTEXITCODE
    $out += "  $u → http=$code rc=$rc"
}
$out += ''

# ============================================================ 4. 中文马克思主义文库：探篇目页
$out += '==================== 4. 中文马克思主义文库：篇目页探测 ===================='
$cands = @(
    'https://www.marxists.org/chinese/kalinin/index.htm',
    'https://www.marxists.org/chinese/kalinin/index.html',
    'https://www.marxists.org/chinese/kalinin/',
    'https://www.marxists.org/chinese/mikhail-kalinin/index.htm',
    'https://www.marxists.org/chinese/kalinin-kalinin/index.htm'
)
foreach ($u in $cands) {
    $code = & curl.exe -s -o NUL -w '%{http_code}' -x $proxy --max-time 25 $u 2>$null
    $out += "  [$code] $u"
    if ($code -eq '200') {
        $f = Join-Path $dst 'wiki\cn-kalinin-index.htm'
        & curl.exe -s -L -x $proxy --max-time 60 -o $f $u 2>$null
        $out += ('      已存 ' + $f + '  ' + (Get-Item $f).Length + ' 字节')
    }
}
$out += ''

# ============================================================ 5. 中文文库站内搜索
$out += '==================== 5. 中文文库索引站内检索（加里宁 / 卡里宁 / 加里寧）===================='
foreach ($kw in @('加里宁', '卡里宁', '加里寧', 'Kalinin')) {
    $u = 'https://www.marxists.org/chinese/search.htm'
    $out += "  （$kw）手工复核用：$u"
}
# 总索引页
$f = Join-Path $dst 'wiki\cn-mia-index.htm'
$code = & curl.exe -s -o NUL -w '%{http_code}' -x $proxy --max-time 30 'https://www.marxists.org/chinese/' 2>$null
$out += "  [中文文库首页] http=$code"
if ($code -eq '200') { & curl.exe -s -L -x $proxy --max-time 60 -o $f 'https://www.marxists.org/chinese/' 2>$null }
$out += ''

# ============================================================ 6. 维基
$out += '==================== 6. 维基条目 ===================='

# --- zh 先 search 找条目名（🚩 猜名字常猜不到）---
$fz = Join-Path $dst 'wiki\zh-search.json'
& curl.exe -s -L -x $proxy --max-time 40 -o $fz 'https://zh.wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=10&srsearch=%E5%8A%A0%E9%87%8C%E5%AE%81' 2>$null
$out += ('  [zh search] ' + $fz + '  ' + (Get-Item $fz -ErrorAction SilentlyContinue).Length + ' 字节')

# --- zh extract ---
$f2 = Join-Path $dst 'wiki\zh-extract.json'
& curl.exe -s -L -x $proxy --max-time 40 -o $f2 'https://zh.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&exlimit=1&format=json&titles=%E7%B1%B3%E5%93%88%E4%BC%8A%E5%B0%94%C2%B7%E5%8A%A0%E9%87%8C%E5%AE%81' 2>$null
$out += ('  [zh extract] ' + $f2 + '  ' + (Get-Item $f2 -ErrorAction SilentlyContinue).Length + ' 字节')

# --- en extract ---
$f3 = Join-Path $dst 'wiki\en-extract.json'
& curl.exe -s -L -x $proxy --max-time 40 -o $f3 'https://en.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&exlimit=1&format=json&titles=Mikhail%20Kalinin' 2>$null
$out += ('  [en extract] ' + $f3 + '  ' + (Get-Item $f3 -ErrorAction SilentlyContinue).Length + ' 字节')

# --- ru extract ---
$f4 = Join-Path $dst 'wiki\ru-extract.json'
& curl.exe -s -L -x $proxy --max-time 40 -o $f4 'https://ru.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&exlimit=1&format=json&titles=%D0%9A%D0%B0%D0%BB%D0%B8%D0%BD%D0%B8%D0%BD%2C%20%D0%9C%D0%B8%D1%85%D0%B0%D0%B8%D0%BB%20%D0%98%D0%B2%D0%B0%D0%BD%D0%BE%D0%B2%D0%B8%D1%87' 2>$null
$out += ('  [ru extract] ' + $f4 + '  ' + (Get-Item $f4 -ErrorAction SilentlyContinue).Length + ' 字节')
$out += ''

# ============================================================ 7. 机构条目（「历任主席」名单）
$out += '==================== 7. 机构条目（⭐「首任/任期」必须查机构）===================='
$inst = @(
    @{ N = 'ru-cik-ussr';  T = '%D0%A6%D0%B5%D0%BD%D1%82%D1%80%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20%D0%B8%D1%81%D0%BF%D0%BE%D0%BB%D0%BD%D0%B8%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20%D0%BA%D0%BE%D0%BC%D0%B8%D1%82%D0%B5%D1%82%20%D0%A1%D0%A1%D0%A1%D0%A0' },
    @{ N = 'ru-vcik-rsfsr'; T = '%D0%92%D1%81%D0%B5%D1%80%D0%BE%D1%81%D1%81%D0%B8%D0%B9%D1%81%D0%BA%D0%B8%D0%B9%20%D1%86%D0%B5%D0%BD%D1%82%D1%80%D0%B0%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20%D0%B8%D1%81%D0%BF%D0%BE%D0%BB%D0%BD%D0%B8%D1%82%D0%B5%D0%BB%D1%8C%D0%BD%D1%8B%D0%B9%20%D0%BA%D0%BE%D0%BC%D0%B8%D1%82%D0%B5%D1%82' },
    @{ N = 'ru-presidium-vs'; T = '%D0%9F%D1%80%D0%B5%D0%B7%D0%B8%D0%B4%D0%B8%D1%83%D0%BC%20%D0%92%D0%B5%D1%80%D1%85%D0%BE%D0%B2%D0%BD%D0%BE%D0%B3%D0%BE%20%D0%A1%D0%BE%D0%B2%D0%B5%D1%82%D0%B0%20%D0%A1%D0%A1%D0%A1%D0%A0' },
    @{ N = 'en-vecik-rsfsr'; T = 'All-Russian%20Central%20Executive%20Committee' },
    @{ N = 'zh-zhongyang-zhiwei'; T = '%E5%85%A8%E4%BF%84%E4%B8%AD%E5%A4%AE%E6%89%A7%E8%A1%8C%E5%A7%94%E5%91%98%E4%BC%9A' }
)
foreach ($i in $inst) {
    $f = Join-Path (Join-Path $dst 'inst') ($i.N + '.json')
    $lang = if ($i.N -like 'ru-*') { 'ru' } elseif ($i.N -like 'zh-*') { 'zh' } else { 'en' }
    $u = "https://$lang.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&exlimit=1&format=json&redirects=1&titles=$($i.T)"
    & curl.exe -s -L -x $proxy --max-time 40 -o $f $u 2>$null
    $sz = (Get-Item $f -ErrorAction SilentlyContinue).Length
    $out += "  [$($i.N)] $sz 字节"
    if ($sz -lt 400) { $out += '      ⚠️ 可能没抓到（条目名不对）' }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-kalinin-report.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $out.Count + ' 行')

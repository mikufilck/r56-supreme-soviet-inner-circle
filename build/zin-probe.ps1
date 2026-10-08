# =============================================================================
# 季诺维也夫：找一手材料（SOP §3 路子，顺序 1 = 中文马克思主义文库）
# -----------------------------------------------------------------------------
# 🚩 教训（docs/23 第 1b 步）：先探有没有他的篇目页，**别默认人人都有**
#    （李可夫就没有：中文文库无他页、英文 marxists 无他档案）
# ⚠️ 本机 = TUN + 本地 HTTP 代理 127.0.0.1:7993 → curl 必须显式 -x
# =============================================================================
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\zinoviev\probe'
$null = New-Item -ItemType Directory -Force -Path $outDir

$cands = [ordered]@{
    'cn_main_index'    = 'https://www.marxists.org/chinese/index.htm'
    'cn_zinoviev'      = 'https://www.marxists.org/chinese/zinoviev/index.htm'
    'cn_zinov'         = 'https://www.marxists.org/chinese/zinov/index.htm'
    'cn_zinn'          = 'https://www.marxists.org/chinese/zinn/index.htm'
    'cn_dictionary'    = 'https://www.marxists.org/chinese/dictionary/index.htm'
    'en_zinoviev'      = 'https://www.marxists.org/archive/zinoviev/index.htm'
    'ru_zinoviev'      = 'https://www.marxists.org/russkij/zinovjev/index.htm'
    'en_comintern'     = 'https://www.marxists.org/history/international/comintern/index.htm'
}

$rows = @()
foreach ($k in $cands.Keys) {
    $f = Join-Path $outDir "$k.html"
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 45 -o $f -w '%{http_code}' $cands[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $line = ('{0,-16} {1,4} {2,9:N0} 字节  {3}' -f $k, $code, $len, $cands[$k])
    $rows += $line
    Write-Host $line
}

# 主索引里搜「季诺维也夫」—— 有链接就说明有页
$main = Join-Path $outDir 'cn_main_index.html'
if (Test-Path -LiteralPath $main) {
    $t = [System.IO.File]::ReadAllText($main, [System.Text.Encoding]::UTF8)
    $rows += ''
    $rows += '=== 中文文库主索引里提到「季诺维也夫」的链接 ==='
    $n = 0
    foreach ($m in [regex]::Matches($t, '(?is)<a[^>]+href="([^"]+)"[^>]*>(.{0,80}?)</a>')) {
        $href = $m.Groups[1].Value; $txt = ($m.Groups[2].Value -replace '<[^>]+>', '')
        if ($txt -match '季诺维也夫|Зиновьев|Zinoviev') { $rows += ('  {0}   ->  {1}' -f $txt.Trim(), $href); $n++ }
    }
    $rows += ("  命中 {0} 条" -f $n)
}
$rows | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'zin-probe-report.txt') -Encoding utf8
Write-Host ''
Write-Host '--- build/zin-probe-report.txt ---'

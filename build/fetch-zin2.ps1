# =============================================================================
# 季诺维也夫：补抓 D 支线要引的一手件（1921 工会提纲）
# -----------------------------------------------------------------------------
# D 支线 = 「党与工会的作用」：
#   D1 《论党在无产阶级革命中的作用》（共产国际二大 1920）
#   D2 《论工会的作用》（俄共十大 1921-03）—— 他自传列为亲自起草的 4 份文件之一
# 索引页把 D2 指向 `../reference-books/su-about-union-1921/`（《论工会在生产中的作用（1921）》）
# =============================================================================
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$base  = 'https://www.marxists.org/chinese/'
$htmlDir = Join-Path $PSScriptRoot '..\tmp\zinoviev\html'
$txtDir  = Join-Path $PSScriptRoot '..\tmp\zinoviev\txt'
$null = New-Item -ItemType Directory -Force -Path $htmlDir, $txtDir

$targets = [ordered]@{
    'd2_union_1921_02' = 'reference-books/su-about-union-1921/02.htm'
    'd2_union_1921_09' = 'reference-books/su-about-union-1921/09.htm'
    'd2_union_1921_12' = 'reference-books/su-about-union-1921/12.htm'
}

function Read-TextAuto([string]$path) {
    $b = [System.IO.File]::ReadAllBytes($path)
    try { $e = New-Object System.Text.UTF8Encoding($false, $true); return $e.GetString($b) }
    catch { return [System.Text.Encoding]::GetEncoding(936).GetString($b) }
}
function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', ''); $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n"); $t = [regex]::Replace($t, '(?i)</p>', "`n`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n`n"); $t = [regex]::Replace($t, '(?i)</li>', "`n")
    $t = [regex]::Replace($t, '(?is)<[^>]+>', ''); $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '[ \t]+', ' '); return ([regex]::Replace($t, '(\r?\n){3,}', "`n`n")).Trim()
}

foreach ($k in $targets.Keys) {
    $hp = Join-Path $htmlDir ($k + '.htm')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $hp -w '%{http_code}' ($base + $targets[$k]) 2>$null
    if ($code -ne '200' -or -not (Test-Path -LiteralPath $hp)) { Write-Host ('  [FAIL] {0} HTTP={1}' -f $k, $code); continue }
    $txt = Convert-HtmlToText (Read-TextAuto $hp)
    [System.IO.File]::WriteAllText((Join-Path $txtDir ($k + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host ('  [OK  ] {0,-20} {1,7:N0} 字符' -f $k, $txt.Length)
}

# ---- 在已有文件里检索 D1 / A2 / A4 的对位段落 ----
$o = @()
$kw = @(
    @{ N = 'A2 加入共产国际的条件'; F = 'ci_192005_urgent'; P = '加入共产国际的条件' },
    @{ N = 'A4 布尔什维克化';       F = 'ci_19250325_persp'; P = '布尔什维克化' },
    @{ N = 'D1 无产阶级革命中的作用'; F = 'ci_192005_urgent'; P = '夺取政权之前和之后|无产阶级革命中的作用' },
    @{ N = 'D1 续 / 党的作用';       F = 'ci_191904_prospect'; P = '党的作用|党的领导|先锋队' },
    @{ N = 'A3 社会法西斯（第三党）'; F = 'ci_19250325_persp'; P = '第三.?党|社会民主党' }
)
foreach ($j in $kw) {
    $p = Join-Path $txtDir ($j.F + '.txt')
    $o += ('======== ' + $j.N + '   [' + $j.F + '] ========')
    if (-not (Test-Path -LiteralPath $p)) { $o += '  (文件不存在)'; $o += ''; continue }
    $L = [System.IO.File]::ReadAllLines($p)
    $n = 0
    for ($i = 0; $i -lt $L.Count; $i++) {
        if ($L[$i] -match $j.P) {
            $t = ($L[$i] -replace '\s+', ' ').Trim()
            if ($t.Length -gt 12) { $o += ('  L{0}: {1}' -f ($i + 1), $t.Substring(0, [Math]::Min(260, $t.Length))); $n++ }
        }
        if ($n -ge 12) { break }
    }
    if ($n -eq 0) { $o += '  (未命中)' }
    $o += ''
}
$o | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'zin-quotes.txt') -Encoding utf8
Write-Host ''
Write-Host '--- build/zin-quotes.txt ---'

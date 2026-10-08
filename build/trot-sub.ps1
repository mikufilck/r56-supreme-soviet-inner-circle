# 从已抓的目录页 HTML 里提取子页链接
$ErrorActionPreference = 'Continue'

function Read-TextAuto([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    try {
        $enc = New-Object System.Text.UTF8Encoding($false, $true)
        return $enc.GetString($bytes)
    } catch {
        return [System.Text.Encoding]::GetEncoding(936).GetString($bytes)
    }
}

$root = Join-Path $PSScriptRoot '..\tmp\trotsky\html'
$keys = @(
    'ii2_permanent_rev_1928', 'ii2_permanent_rev_alt', 'ii1_history_preface_1930',
    'iii2_betrayed_rev_1936', 'iii1_lessons_of_october_1924',
    'v3_fascism_index', 'v3_german_fascism_index', 'e_life_1929book',
    'v2_china_book_index'
)

$out = @()
foreach ($k in $keys) {
    $p = Join-Path $root "$k.htm"
    if (-not (Test-Path $p)) { $out += "[$k] 缺文件"; continue }
    $html = Read-TextAuto $p
    # 该页的 base（用于解析相对链接）
    $base = 'https://www.marxists.org/chinese/trotsky/'
    $out += "===== $k ====="
    $ms = [regex]::Matches($html, '<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', 'IgnoreCase,Singleline')
    foreach ($m in $ms) {
        $href = $m.Groups[1].Value.Trim()
        if ($href -match '^(#|mailto:|javascript:)') { continue }
        if ($href -match '^(https?:)?//' -and $href -notmatch 'marxists\.org') { continue }
        $text = [regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')
        $text = [System.Net.WebUtility]::HtmlDecode($text).Trim() -replace '\s+', ' '
        if ($text -eq '') { continue }
        try { $abs = [Uri]::new([Uri]$base, $href).AbsoluteUri } catch { continue }
        if ($abs -notmatch 'marxists\.org/chinese/trotsky/') { continue }
        if ($abs -eq 'https://www.marxists.org/chinese/trotsky/index.htm') { continue }
        $out += ('  {0}  ::  {1}' -f $abs, $text)
    }
    $out += ''
}

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'trot-sub.txt') -Encoding utf8

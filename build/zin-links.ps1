# 抽中文马克思主义文库【季诺维也夫】专页的篇目链接
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'

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

$dir = Join-Path $PSScriptRoot '..\tmp\zinoviev'
$out = @()

foreach ($u in @('https://www.marxists.org/chinese/zinoviev/index.htm',
                 'https://www.marxists.org/archive/zinoviev/index.htm')) {
    $tag = if ($u -match '/chinese/') { 'cn' } else { 'en' }
    $f = Join-Path $dir "$tag-index.htm"
    $null = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 45 -o $f $u 2>$null
    if (-not (Test-Path -LiteralPath $f)) { continue }
    $h = Read-TextAuto $f
    $out += ('==================== {0}  {1} ====================' -f $tag, $u)
    $out += '--- 正文（前 120 行）---'
    $txt = Convert-HtmlToText $h
    $L = $txt -split "`n"
    $out += ($L | Select-Object -First 120)
    $out += ''
    $out += '--- 链接（含标题）---'
    $n = 0
    foreach ($m in [regex]::Matches($h, '(?is)<a[^>]+href="([^"#]+)"[^>]*>(.{0,120}?)</a>')) {
        $href = $m.Groups[1].Value
        $t = ($m.Groups[2].Value -replace '<[^>]+>', '').Trim()
        if ($t.Length -lt 2) { continue }
        $out += ('  [{0}] {1}   ->   {2}' -f $tag, $t, $href)
        $n++
    }
    $out += ("  链接数 {0}" -f $n)
    $out += ''
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'zin-links-report.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('输出 ' + $out.Count + ' 行 -> build/zin-links-report.txt')

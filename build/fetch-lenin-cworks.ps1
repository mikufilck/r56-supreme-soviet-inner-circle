# =============================================================================
# 列宁全集【书信卷】全文检索「李可夫」（2026-09-16）
# -----------------------------------------------------------------------------
# 为什么要试这一条：李可夫本人无中文文集（中文文库 5 个 URL 全 404），
#   列宁正文卷里 1918-1926 的 22 篇只命中 2 处、且都在【编者注】里（不是列宁原话）。
#   列宁 1921-1923 的书信里频繁讨论经济机关人事 —— 这是最可能出「原话评价」的地方。
# =============================================================================
$proxy = 'http://127.0.0.1:7993'
$root  = Join-Path $PSScriptRoot '..\tmp\rykov\lenin'
$idxDir = Join-Path $root 'cworks-idx'
$htmlDir = Join-Path $root 'html2'
$txtDir  = Join-Path $root 'txt2'
$null = New-Item -ItemType Directory -Force -Path $idxDir, $htmlDir, $txtDir

function Read-TextAuto([string]$path) {
    $b = [System.IO.File]::ReadAllBytes($path)
    try { $e = New-Object System.Text.UTF8Encoding($false, $true); return $e.GetString($b) }
    catch { return [System.Text.Encoding]::GetEncoding(936).GetString($b) }
}
function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', ''); $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n"); $t = [regex]::Replace($t, '(?i)</p>', "`n`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n`n"); $t = [regex]::Replace($t, '(?is)<[^>]+>', '')
    $t = [System.Net.WebUtility]::HtmlDecode($t); $t = [regex]::Replace($t, '[ \t]+', ' ')
    return ([regex]::Replace($t, '(\r?\n){3,}', "`n`n")).Trim()
}

$all = @()
foreach ($v in @(50, 51, 52, 53, 54, 55)) {
    $iu = "https://www.marxists.org/chinese/lenin-cworks/$v/index.htm"
    $if = Join-Path $idxDir "$v.htm"
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 45 -o $if -w '%{http_code}' $iu 2>$null
    if (-not (Test-Path -LiteralPath $if)) { continue }
    $ih = Read-TextAuto $if
    $ls = @()
    foreach ($m in [regex]::Matches($ih, '(?i)href="([^"]+\.htm)"')) {
        $u = $m.Groups[1].Value
        if ($u -match '^https?://') { $ls += $u }
        elseif ($u -match '^\.\./') { $ls += (New-Object System.Uri([uri]"https://www.marxists.org/chinese/lenin-cworks/", $u)).AbsoluteUri }
        else { $ls += (New-Object System.Uri([uri]"https://www.marxists.org/chinese/lenin-cworks/$v/", $u)).AbsoluteUri }
    }
    $ls = @($ls | Where-Object { $_ -notmatch 'pdf|index\.htm$' } | Select-Object -Unique)
    Write-Host ("  卷 {0}: HTTP={1}  链接 {2}" -f $v, $code, $ls.Count)
    $all += $ls
}
$all = @($all | Select-Object -Unique)
Write-Host ("共 {0} 篇，开始下载…" -f $all.Count)

$rep = @()
$hits = @(); $n = 0
foreach ($u in $all) {
    $n++
    $name = ([uri]$u).AbsolutePath.Split('/')[-1]
    if ($name -notmatch '\.htm$') { continue }
    $f = Join-Path $htmlDir $name
    if (-not (Test-Path -LiteralPath $f)) { $null = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 30 -o $f $u 2>$null }
    if (-not (Test-Path -LiteralPath $f) -or (Get-Item -LiteralPath $f).Length -lt 800) { continue }
    $t = Convert-HtmlToText (Read-TextAuto $f)
    [System.IO.File]::WriteAllText((Join-Path $txtDir ($name -replace '\.htm$','.txt')), $t, (New-Object System.Text.UTF8Encoding($false)))
    if ($t -match '李可夫') {
        $hits += "$name`t$u"
        $L = $t -split "`n"
        for ($i = 0; $i -lt $L.Count; $i++) {
            if ($L[$i] -match '李可夫') {
                $s = [Math]::Max(0, $i - 1); $e = [Math]::Min($L.Count - 1, $i + 1)
                $rep += ("[{0}]" -f $name)
                for ($j = $s; $j -le $e; $j++) { $rep += ('   ' + ($L[$j] -replace '\s+', ' ').Trim()) }
                $rep += ''
            }
        }
    }
    if ($n % 25 -eq 0) { Write-Host ("   ...{0}/{1}" -f $n, $all.Count) }
}
$rep = @("命中 {0} / {1} 篇" -f $hits.Count, $all.Count, '') + ($hits -join "`n").Split("`n") + '' + $rep
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'lenin-cworks-rykov-hits.txt'), $rep, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("命中 {0} / {1}" -f $hits.Count, $all.Count)

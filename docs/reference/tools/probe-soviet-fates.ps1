# probe-soviet-fates.ps1
# 核实「反对派胜利」时间线下，斯大林系 9 人的可存活依据。
# ⚠️ 用 curl.exe 下载（PS5.1 的 Invoke-WebRequest 会因 TLS 版本失败），再本地解析。
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$tmp = Join-Path $PSScriptRoot '..\..\..\tmp\probe-fates'
if (-not (Test-Path $tmp)) { New-Item -ItemType Directory -Path $tmp -Force | Out-Null }
$tmp = (Resolve-Path $tmp).Path

$pages = [ordered]@{
    'Khrushchev'   = 'https://en.wikipedia.org/wiki/Nikita_Khrushchev'
    'Malenkov'     = 'https://en.wikipedia.org/wiki/Georgy_Malenkov'
    'Molotov'      = 'https://en.wikipedia.org/wiki/Vyacheslav_Molotov'
    'Voroshilov'   = 'https://en.wikipedia.org/wiki/Kliment_Voroshilov'
    'Yagoda'       = 'https://en.wikipedia.org/wiki/Genrikh_Yagoda'
    'Yezhov'       = 'https://en.wikipedia.org/wiki/Nikolai_Yezhov'
    'Beria'        = 'https://en.wikipedia.org/wiki/Lavrentiy_Beria'
    'Kaganovich'   = 'https://en.wikipedia.org/wiki/Lazar_Kaganovich'
    'MoscowTrials' = 'https://en.wikipedia.org/wiki/Moscow_trials'
}

$kw = 'Trotsky|Bukharin|Right Opposition|New Course|light industry|\bNEP\b|Great Purge|Moscow Trial|Tukhachevsky|rehabilitat|Ukrainian famine|Holodomor|Left Opposition'

foreach ($name in $pages.Keys) {
    Write-Output ('==================== ' + $name + ' ====================')
    $raw = Join-Path $tmp ($name + '.html')
    if (-not (Test-Path $raw)) {
        & curl.exe -s -L --max-time 45 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' -o $raw $pages[$name] 2>$null
    }
    if (-not (Test-Path $raw) -or (Get-Item $raw).Length -lt 5000) {
        Write-Output ('  ✗ 下载失败或内容过小：' + $raw)
        Write-Output ''
        continue
    }
    $t = [System.IO.File]::ReadAllText($raw)
    $t = $t -replace '(?s)<script.*?</script>', ' '
    $t = $t -replace '(?s)<style.*?</style>', ' '
    $t = $t -replace '(?s)<sup.*?</sup>', ' '
    $t = $t -replace '<[^>]+>', ' '
    $t = $t -replace '&#160;|&nbsp;', ' '
    $t = $t -replace '\s+', ' '
    $sent = $t -split '(?<=\. )'
    $hits = @($sent | Where-Object { $_ -match $kw })
    Write-Output ('  命中 {0} 句（最多列 20）' -f $hits.Count)
    $i = 0
    foreach ($h in $hits) {
        if ($i -ge 20) { break }
        $i++
        $s = $h.Trim()
        if ($s.Length -gt 340) { $s = $s.Substring(0, 340) + '…' }
        Write-Output ('  - ' + $s)
    }
    Write-Output ''
}

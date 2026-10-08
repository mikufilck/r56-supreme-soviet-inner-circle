# 季诺维也夫：抓中/俄/英维基（核对职务年表 + 补理论定位）
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\zinoviev\wiki'
$null = New-Item -ItemType Directory -Force -Path $outDir

# 用 API 取纯文本全文（extracts + explaintext）
$jobs = [ordered]@{
    'zh' = 'https://zh.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=%E6%A0%BC%E9%87%8C%E6%88%88%E9%87%8C%C2%B7%E5%AD%A3%E8%AF%BA%E7%BB%B4%E4%B9%9F%E5%A4%AB'
    'ru' = 'https://ru.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=%D0%97%D0%B8%D0%BD%D0%BE%D0%B2%D1%8C%D0%B5%D0%B2%2C_%D0%93%D1%80%D0%B8%D0%B3%D0%BE%D1%80%D0%B8%D0%B9_%D0%95%D0%B2%D1%81%D0%B5%D0%B5%D0%B2%D0%B8%D1%87'
    'en' = 'https://en.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=Grigory_Zinoviev'
    'zh_ci' = 'https://zh.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=%E5%85%B1%E4%BA%A7%E5%9B%BD%E9%99%85'
}
$rep = @()
foreach ($k in $jobs.Keys) {
    $f = Join-Path $outDir ($k + '.json')
    $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $f -w '%{http_code}' $jobs[$k] 2>$null
    $len = if (Test-Path -LiteralPath $f) { (Get-Item -LiteralPath $f).Length } else { 0 }
    $rep += ('{0,-6} {1,4} {2,9:N0} 字节' -f $k, $code, $len)
    Write-Host $rep[-1]
    # JSON -> 纯文本
    if ($code -eq '200' -and $len -gt 200) {
        try {
            $j = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            $pages = $j.query.pages
            foreach ($p in $pages.PSObject.Properties) {
                $txt = $p.Value.extract
                if ($txt) {
                    $out = Join-Path $outDir ($k + '.txt')
                    [System.IO.File]::WriteAllText($out, $txt, (New-Object System.Text.UTF8Encoding($false)))
                    Write-Host ('       -> {0}  {1:N0} 字符' -f ($k + '.txt'), $txt.Length)
                }
            }
        } catch { Write-Host ('       JSON 解析失败：' + $_.Exception.Message) }
    }
}
$rep | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'zin-wiki-report.txt') -Encoding utf8

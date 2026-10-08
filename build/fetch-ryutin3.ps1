# 里亚京（Idx 12）材料抓取 · 第 3 批 —— zh 维基那两个条目（第 2 批 search API 找到的）
# 蓝本：build/fetch-tomsky.ps1 ｜ 网络必须显式走代理 127.0.0.1:7993
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\ryutin\src'
$script:log = @()

function Curl-To {
    param([string]$Url, [string]$File)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $File -w '%{http_code}' $Url 2>$null
    $l = if (Test-Path -LiteralPath $File) { (Get-Item -LiteralPath $File).Length } else { 0 }
    return @{ Code = "$c"; Len = $l }
}

function Wiki-Extract {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $r  = Curl-To -Url $u -File $jf
    $script:log += ('  [{0}] HTTP {1}  {2:N0} 字节  <- {3}' -f $Tag, $r.Code, $r.Len, $Title)
    if ($r.Code -ne '200' -or $r.Len -lt 200) { return }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            if ($p.Value.extract) {
                [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('      -> {0}.txt  {1:N0} 字符   条目 = {2}' -f $Tag, $p.Value.extract.Length, $p.Value.title)
            } else { $script:log += '      条目存在但 extract 为空' }
        }
    } catch { $script:log += ('      JSON 解析失败：' + $_.Exception.Message) }
}

$script:log += '=== zh 维基（第 2 批 search 找到的两条）==='
Wiki-Extract -Lang 'zh' -Title '马特米扬·柳廷' -Tag 'zh-ryutin'
Wiki-Extract -Lang 'zh' -Title '柳廷事件'      -Tag 'zh-affair'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-ryutin3-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $script:log.Count + ' 行')

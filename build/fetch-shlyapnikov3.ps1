# 施利亚普尼科夫（Idx 13）材料抓取 · 第 3 批 —— ⭐⭐ 工人反对派纲领的中译
# 来源：中文马克思主义文库「柯伦泰」篇目页（第 2 批抽到的 20 条链接里）
#   《工人反对派》1920 / 1921 两版 —— 柯伦泰著（她是该派的导师与代言人）
#   第十次全俄女工代表大会上的讲话（1921）—— 含工人民主的内容
#   另：zh 维基〈俄国共产党（布尔什维克）第十次代表大会〉
# 蓝本：build/fetch-ryutin2.ps1 ｜ 网络必须显式走代理 127.0.0.1:7993
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\shlyapnikov\txt'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$script:log = @()

function Decode-Bytes {
    param([byte[]]$Bytes)
    try {
        $enc = [System.Text.Encoding]::GetEncoding('utf-8',
               [System.Text.EncoderFallback]::ExceptionFallback,
               [System.Text.DecoderFallback]::ExceptionFallback)
        return $enc.GetString($Bytes)
    } catch { return [System.Text.Encoding]::GetEncoding(936).GetString($Bytes) }
}

function Fetch-Text {
    param([string]$Url, [string]$Tag)
    $hf = Join-Path $outDir ($Tag + '.html')
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $hf -w '%{http_code}' $Url 2>$null
    $len = if (Test-Path -LiteralPath $hf) { (Get-Item -LiteralPath $hf).Length } else { 0 }
    $script:log += ('  [{0}] HTTP {1}  {2:N0} 字节  <- {3}' -f $Tag, $c, $len, $Url)
    if ("$c" -ne '200' -or $len -lt 500) { return }
    $txt = Decode-Bytes ([System.IO.File]::ReadAllBytes($hf))
    # 去 script/style，去标签，简单转文本
    $txt = [regex]::Replace($txt, '(?is)<script.*?</script>', '')
    $txt = [regex]::Replace($txt, '(?is)<style.*?</style>', '')
    $txt = [regex]::Replace($txt, '(?i)<br\s*/?>', "`n")
    $txt = [regex]::Replace($txt, '(?i)</p>', "`n")
    $txt = [regex]::Replace($txt, '<[^>]+>', '')
    $txt = [System.Net.WebUtility]::HtmlDecode($txt)
    $txt = [regex]::Replace($txt, "(`r?`n){3,}", "`n`n")
    [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
    $script:log += ('      -> {0}.txt  {1:N0} 字符' -f $Tag, $txt.Length)
}

$script:log += '=== ⭐⭐ 柯伦泰《工人反对派》（工人反对派纲领的中译）==='
Fetch-Text -Url 'https://www.marxists.org/chinese/kollontai/marxist.org-chinese-kollontai-1920.htm' -Tag 'ao-1920'
Fetch-Text -Url 'https://www.marxists.org/chinese/kollontai/marxist.org-chinese-kollontai-1921.htm' -Tag 'ao-1921'
Fetch-Text -Url 'https://www.marxists.org/chinese/kollontai/mia-chinese-kollontai-1921.htm'  -Tag 'ao-1921b'
Fetch-Text -Url 'https://www.marxists.org/chinese/kollontai/mia-chinese-kollontai-1921b.htm' -Tag 'ao-1921c'

$script:log += '=== zh 维基〈第十次代表大会〉==='
function Wiki-Extract {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $jf -w '%{http_code}' $u 2>$null
    if ("$c" -ne '200') { $script:log += ('  [{0}] HTTP {1}' -f $Tag, $c); return }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            if ($p.Value.extract) {
                [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('  [{0}] -> {1}.txt  {2:N0} 字符   条目 = {3}' -f $Tag, $Tag, $p.Value.extract.Length, $p.Value.title)
            } else { $script:log += ('  [{0}] extract 为空' -f $Tag) }
        }
    } catch { $script:log += ('  [{0}] JSON 失败：{1}' -f $Tag, $_.Exception.Message) }
}
Wiki-Extract -Lang 'zh' -Title '俄国共产党（布尔什维克）第十次代表大会' -Tag 'zh-cong10'
Wiki-Extract -Lang 'zh' -Title '俄国共产党（布尔什维克）第十一次代表大会' -Tag 'zh-cong11'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-shlyapnikov3-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，' + $script:log.Count + ' 行')

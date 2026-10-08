# 钉死一条机构事实：НКПС РСФСР（1917—1923）的【历任人民委员】
#  目的：核实 docs/21 §6.5 写的「谢列布里亚科夫 1920–21 任交通人民委员」是不是错的
#        （怀疑写成的是【托洛茨基自己】的职务）
#  依据记忆里的教训：历任 / 首任 这类事实必须查【机构】条目
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\sereb\wiki2'
$null   = New-Item -ItemType Directory -Force -Path $outDir

$tag   = 'ru_nkps_rsfsr'
$title = 'Народный комиссариат путей сообщения РСФСР'
$u = 'https://ru.wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=' +
     [uri]::EscapeDataString($title)
$jf = Join-Path $outDir ($tag + '.json')
$code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $jf -w '%{http_code}' $u 2>$null
$len = if (Test-Path -LiteralPath $jf) { (Get-Item -LiteralPath $jf).Length } else { 0 }
Write-Host ("HTTP $code  $len 字节")
if ($code -eq '200' -and $len -gt 200) {
    $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    foreach ($p in $j.query.pages.PSObject.Properties) {
        if ($p.Value.extract) {
            $tf = Join-Path $outDir ($tag + '.txt')
            [System.IO.File]::WriteAllText($tf, $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
            Write-Host ('-> {0}  {1:N0} 字符  条目 = {2}' -f ($tag + '.txt'), $p.Value.extract.Length, $p.Value.title)
        }
    }
}

# 从俄文李可夫条目里抽【与酒类专卖 / 1924-30 政策】相关的段落
$ErrorActionPreference = 'Continue'
$f = Join-Path $PSScriptRoot '..\tmp\rykov\verify\ru_rykov.txt'
$t = [System.IO.File]::ReadAllText($f)
$paras = $t -split "(\r?\n){2,}" | Where-Object { $_.Trim().Length -gt 30 }

$out = @()
$out += '################ 含「酒 / 专卖」的段落 ################'
foreach ($p in $paras) {
    $c = ($p -replace '\s+', ' ').Trim()
    if ($c -match 'рыковк|водк|монопол|вино|спирт|питей') { $out += ('  * ' + $c); $out += '' }
}
$out += ''
$out += '################ 含「1924-1930 政策 / 财政」的段落 ################'
foreach ($p in $paras) {
    $c = ($p -replace '\s+', ' ').Trim()
    if ($c -match 'бюджет|налог|финанс|эмисси|червонец|НЭП|нэп|продналог|кооперац') { $out += ('  * ' + $c); $out += '' }
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'rykov-verify-3.txt') -Encoding utf8

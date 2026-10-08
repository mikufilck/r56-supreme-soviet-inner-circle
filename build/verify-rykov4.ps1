# 抽「Алкогольная монополия」里与 1925 恢复 / 苏联时期有关的段落
$ErrorActionPreference = 'Continue'
$f = Join-Path $PSScriptRoot '..\tmp\rykov\verify\ru_monopoly.txt'
$t = [System.IO.File]::ReadAllText($f)
$paras = $t -split "(\r?\n){2,}" | Where-Object { $_.Trim().Length -gt 30 }

$out = @()
$out += ('全文长度 = ' + $t.Length)
$out += ''
foreach ($p in $paras) {
    $c = ($p -replace '\s+', ' ').Trim()
    if ($c -match '1925|1926|СССР|советск|Рыков|большевик|национализ') {
        $out += ('  * ' + $c)
        $out += ''
    }
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'rykov-verify-4.txt') -Encoding utf8

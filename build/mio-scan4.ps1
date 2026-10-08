# 读「托特组织自治」国策全文 + 雅科夫列夫 MIO 定义
$ErrorActionPreference = 'Continue'
$van = 'F:\Hearts of Iron IV'
$out = @()

# ① 托特组织自治 国策
$f = Join-Path $van 'common\national_focus\germany.txt'
$lines = [System.IO.File]::ReadAllLines($f)
$hits = Select-String -LiteralPath $f -Pattern 'id = GER_autonomous_organization_todt' -ErrorAction SilentlyContinue
foreach ($h in $hits) {
    $s = [Math]::Max(0, $h.LineNumber - 3)
    $e = [Math]::Min($lines.Count - 1, $h.LineNumber + 55)
    $out += ('==================== GER_autonomous_organization_todt  L{0} ====================' -f $h.LineNumber)
    for ($i = $s; $i -le $e; $i++) { $out += ('  {0,7}  {1}' -f ($i + 1), $lines[$i]) }
    $out += ''
}

# ② 雅科夫列夫 MIO 定义
$mf = Join-Path $van 'common\military_industrial_organization\organizations\SOV_organization.txt'
$ml = [System.IO.File]::ReadAllLines($mf)
$mh = Select-String -LiteralPath $mf -Pattern 'SOV_yakovlev_design_bureau_organization = \{' -ErrorAction SilentlyContinue
foreach ($h in $mh) {
    $s = [Math]::Max(0, $h.LineNumber - 2)
    $e = [Math]::Min($ml.Count - 1, $h.LineNumber + 45)
    $out += ('==================== SOV_yakovlev_design_bureau_organization  L{0} ====================' -f $h.LineNumber)
    for ($i = $s; $i -le $e; $i++) { $out += ('  {0,7}  {1}' -f ($i + 1), $ml[$i]) }
    $out += ''
}

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'mio-scan4.txt') -Encoding utf8
Write-Host ('输出 ' + $out.Count + ' 行')

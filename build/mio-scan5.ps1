# 查 MIO 的授予/强化写法 + 托特组织 idea 怎么加上的 + 雅科夫列夫 MIO 全定义
$ErrorActionPreference = 'Continue'
$van = 'F:\Hearts of Iron IV'
$out = @()

# ① 原版里怎么授予 MIO（找 effect 名）
$nfDir = Join-Path $van 'common\national_focus'
$nf = @(Get-ChildItem -LiteralPath $nfDir -Filter '*.txt' -File | Select-Object -ExpandProperty FullName)
$out += '==================== 国策里授予 MIO 的写法 ===================='
foreach ($rx in @('add_military_industrial_organization', 'show_mio_tooltip', 'unlock_mio', 'mio = \{', 'add_mio')) {
    $m = Select-String -Path $nf -Pattern $rx -ErrorAction SilentlyContinue | Select-Object -First 3
    if ($m) {
        $out += "  --- $rx ---"
        foreach ($x in $m) { $out += ('    [' + (Split-Path $x.Path -Leaf) + '] L' + $x.LineNumber + '  ' + $x.Line.Trim()) }
    }
}
$out += ''

# ② 托特组织 idea 在哪定义、怎么加
$out += '==================== GER_organization_todt 的定义与授予 ===================='
$files = @()
foreach ($sd in @('common\ideas', 'common\scripted_effects', 'common\national_focus')) {
    $d = Join-Path $van $sd
    if (Test-Path $d) {
        $files += @(Get-ChildItem -LiteralPath $d -Recurse -File -Filter '*.txt' | Select-Object -ExpandProperty FullName)
    }
}
$m = Select-String -Path $files -Pattern 'GER_organization_todt' -ErrorAction SilentlyContinue | Select-Object -First 12
foreach ($x in $m) { $out += ('    [' + $x.Path.Replace($van + '\', '') + '] L' + $x.LineNumber + '  ' + $x.Line.Trim()) }
$out += ''

# ③ 雅科夫列夫 MIO 全定义
$mf = Join-Path $van 'common\military_industrial_organization\organizations\SOV_organization.txt'
$ml = [System.IO.File]::ReadAllLines($mf)
$h = Select-String -LiteralPath $mf -Pattern '^SOV_yakovlev_design_bureau_organization = \{' -ErrorAction SilentlyContinue
if ($h) {
    $s = $h[0].LineNumber - 1
    $e = [Math]::Min($ml.Count - 1, $s + 70)
    $out += ('==================== 雅科夫列夫 MIO 全定义  L{0} ====================' -f ($s + 1))
    for ($i = $s; $i -le $e; $i++) { $out += ('  {0,7}  {1}' -f ($i + 1), $ml[$i]) }
}
$out += ''

# ④ 恢复雅科夫列夫的决议
$dcDir = Join-Path $van 'common\decisions'
if (Test-Path $dcDir) {
    $dc = @(Get-ChildItem -LiteralPath $dcDir -Recurse -File -Filter '*.txt' | Select-Object -ExpandProperty FullName)
    $m2 = Select-String -Path $dc -Pattern 'SOV_reinstate_yakovlev_design_bureau' -ErrorAction SilentlyContinue | Select-Object -First 2
    if ($m2) {
        foreach ($x in $m2) {
            $dl = [System.IO.File]::ReadAllLines($x.Path)
            $s = [Math]::Max(0, $x.LineNumber - 4)
            $e = [Math]::Min($dl.Count - 1, $x.LineNumber + 25)
            $out += ('==================== 恢复雅科夫列夫决议  [' + (Split-Path $x.Path -Leaf) + '] L' + $x.LineNumber + ' ====================')
            for ($i = $s; $i -le $e; $i++) { $out += ('  {0,7}  {1}' -f ($i + 1), $dl[$i]) }
        }
    }
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'mio-scan5.txt') -Encoding utf8
Write-Host ('输出 ' + $out.Count + ' 行')

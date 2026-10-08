# 精确找「托特组织自治」国策
$ErrorActionPreference = 'Continue'
$van = 'F:\Hearts of Iron IV'
$out = @()

$out += '==================== 全部含 todt 的本地化键（原版+R56）===================='
$roots = @(
    @{ T = '原版'; P = (Join-Path $van 'localisation\simp_chinese') },
    @{ T = 'R56'; P = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\localisation\simp_chinese' }
)
foreach ($r in $roots) {
    if (-not (Test-Path $r.P)) { continue }
    $files = @(Get-ChildItem -LiteralPath $r.P -Filter '*.yml' -File | Select-Object -ExpandProperty FullName)
    $m = Select-String -Path $files -Pattern 'todt' -ErrorAction SilentlyContinue
    $out += "  --- $($r.T)（$($m.Count) 行）---"
    foreach ($x in $m) { $out += ('    ' + $x.Line.Trim()) }
    $out += ''
}

$out += '==================== german.txt 里 id = GER_form_organization_todt 的块 ===================='
$f = Join-Path $van 'common\national_focus\germany.txt'
$lines = [System.IO.File]::ReadAllLines($f)
$hits = Select-String -LiteralPath $f -Pattern 'id = GER_form_organization_todt|id = GER_organization_todt' -ErrorAction SilentlyContinue
if ($hits) {
    foreach ($h in $hits) {
        $s = [Math]::Max(0, $h.LineNumber - 6)
        $e = [Math]::Min($lines.Count - 1, $h.LineNumber + 70)
        $out += ("  --- 命中 L{0} ---" -f $h.LineNumber)
        for ($i = $s; $i -le $e; $i++) { $out += ('  {0,7}  {1}' -f ($i + 1), $lines[$i]) }
        $out += ''
    }
} else {
    $out += '  (未命中 —— 该国策可能不在 german.txt，或 id 不同)'
    $out += '  在全部国策文件里搜 form_organization_todt：'
    $nfDir = Join-Path $van 'common\national_focus'
    $nf = @(Get-ChildItem -LiteralPath $nfDir -Filter '*.txt' -File | Select-Object -ExpandProperty FullName)
    $m2 = Select-String -Path $nf -Pattern 'form_organization_todt' -ErrorAction SilentlyContinue
    foreach ($x in $m2) { $out += ('    [' + (Split-Path $x.Path -Leaf) + '] L' + $x.LineNumber + '  ' + $x.Line.Trim()) }
}
$out += ''
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'mio-scan3.txt') -Encoding utf8
Write-Host ('输出 ' + $out.Count + ' 行')

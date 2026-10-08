# 定位「托特组织自治」国策 + 雅科夫列夫 MIO 定义
$ErrorActionPreference = 'Continue'
$van = 'F:\Hearts of Iron IV'
$out = @()

function DumpAround {
    param([string]$Tag, [string]$File, [string]$Rx, [int]$Before = 4, [int]$After = 40, [int]$Max = 3)
    $script:out += "================================================================"
    $script:out += "  $Tag"
    $script:out += "  $File"
    $script:out += "================================================================"
    if (-not (Test-Path $File)) { $script:out += '  (文件不存在)'; $script:out += ''; return }
    $m = Select-String -LiteralPath $File -Pattern $Rx -ErrorAction SilentlyContinue | Select-Object -First $Max
    if (-not $m) { $script:out += '  (未命中)'; $script:out += ''; return }
    $lines = [System.IO.File]::ReadAllLines($File)
    foreach ($hit in $m) {
        $s = [Math]::Max(0, $hit.LineNumber - 1 - $Before)
        $e = [Math]::Min($lines.Count - 1, $hit.LineNumber - 1 + $After)
        $script:out += ("  --- 命中于 L{0} ---" -f $hit.LineNumber)
        for ($i = $s; $i -le $e; $i++) { $script:out += ('  {0,7}  {1}' -f ($i + 1), $lines[$i]) }
        $script:out += ''
    }
}

# ① 德国「托特组织自治」国策（英文键可能是 autonomy）
DumpAround '德国国策：托特组织相关' (Join-Path $van 'common\national_focus\germany.txt') 'organization_todt|todt_autonomy|GER_todt' 4 45 4

# ② 雅科夫列夫 MIO 定义
DumpAround '雅科夫列夫 MIO 定义' (Join-Path $van 'common\military_industrial_organization\organizations\SOV_organization.txt') 'SOV_yakovlev_design_bureau_organization' 2 60 1

# ③ 本地化：找「自治」相关键
$locDir = Join-Path $van 'localisation\simp_chinese'
$locFiles = @(Get-ChildItem -LiteralPath $locDir -Filter '*.yml' -File | Select-Object -ExpandProperty FullName)
$m = Select-String -Path $locFiles -Pattern 'organization_todt' -ErrorAction SilentlyContinue
$out += '==================== 托特组织相关本地化 ===================='
foreach ($x in $m) { $out += ('  [' + (Split-Path $x.Path -Leaf) + '] ' + $x.Line.Trim()) }
$out += ''

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'mio-scan2.txt') -Encoding utf8
Write-Host ('输出 ' + $out.Count + ' 行')

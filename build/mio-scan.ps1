# 查：① 游戏里有没有「雅科夫列夫」制造商（MIO）② 德国托特组织国策怎么写的
$ErrorActionPreference = 'Continue'

$van = 'F:\Hearts of Iron IV'
$r56 = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$out = @()

function DumpHits {
    param([string]$Tag, [string]$Root, [string]$Rx, [string[]]$Subs, [int]$Max = 12)
    $script:out += "==================== $Tag ===================="
    foreach ($sd in $Subs) {
        $d = Join-Path $Root $sd
        if (-not (Test-Path $d)) { continue }
        $files = @(Get-ChildItem -LiteralPath $d -Recurse -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Extension -in @('.txt', '.yml') } | Select-Object -ExpandProperty FullName)
        if ($files.Count -eq 0) { continue }
        $m = Select-String -Path $files -Pattern $Rx -List -ErrorAction SilentlyContinue
        if ($m) {
            $script:out += "  --- $sd （$($m.Count) 个文件命中）---"
            foreach ($x in ($m | Select-Object -First $Max)) {
                $script:out += ('    ' + $x.Path.Replace($Root + '\', ''))
                $script:out += ('        ' + $x.Line.Trim())
            }
        }
    }
    $script:out += ''
}

# ① 雅科夫列夫（英文/俄文/德文转写都试）
DumpHits '雅科夫列夫 MIO'      $van 'yakovlev|jakowlew|Яковлев' @('common\military_industrial_organization', 'common\companies', 'common\scripted_effects', 'common\national_focus', 'localisation\simp_chinese')
DumpHits '雅科夫列夫 MIO（R56）' $r56 'yakovlev|jakowlew|Яковлев' @('common\military_industrial_organization', 'common\companies', 'common\scripted_effects', 'common\national_focus', 'localisation\simp_chinese')

# ② 德国托特组织
DumpHits '托特组织（原版）'     $van 'organization_todt|todt' @('common\national_focus', 'common\military_industrial_organization', 'common\scripted_effects', 'localisation\simp_chinese', 'events')

# ③ MIO 目录结构（看有哪些制造商）
$mioDir = Join-Path $van 'common\military_industrial_organization'
if (Test-Path $mioDir) {
    $out += '==================== MIO 目录 ===================='
    $out += (Get-ChildItem -LiteralPath $mioDir -Recurse -File -ErrorAction SilentlyContinue |
             Select-Object -First 40 | ForEach-Object { '  ' + $_.FullName.Replace($van + '\', '') })
    $out += ''
}

$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'mio-scan.txt') -Encoding utf8
Write-Host ('输出 ' + $out.Count + ' 行')

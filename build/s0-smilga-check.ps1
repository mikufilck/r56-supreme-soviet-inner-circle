# SOP 第 0 步（续 2）：剩下的几个疑点
$ErrorActionPreference = 'Continue'
$out = @()
$out += '==== 斯米尔加（Idx 10）· 第 0 步疑点复核 ===='
$out += ''

$V = 'F:\Hearts of Iron IV'
$R = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

# --- 1. 原版角色定义全文（含 advisor 块后半 + 是否有 country_leader） ---
$out += '==================== 1. 原版角色定义全文 2755-2870 ===================='
$p = Join-Path $V 'common\characters\SOV.txt'
$L = [System.IO.File]::ReadAllLines($p)
for ($i = 2768; $i -le [Math]::Min(2870, $L.Count); $i++) {
    $out += ('  {0,6}: {1}' -f $i, $L[$i - 1].TrimEnd())
}
$out += ''

# --- 2. soviet_economist 特质被谁用 ---
$out += '==================== 2. soviet_economist 特质的引用 ===================='
foreach ($root in @(@{N='原版';P=$V}, @{N='R56';P=$R})) {
    $d = Join-Path $root.P 'common'
    if (-not (Test-Path $d)) { continue }
    $files = @(Get-ChildItem -LiteralPath $d -Recurse -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Extension -eq '.txt' } | Select-Object -ExpandProperty FullName)
    $m = @(Select-String -Path $files -Pattern 'soviet_economist' -ErrorAction SilentlyContinue)
    $out += "  --- $($root.N) （$($m.Count) 命中）---"
    foreach ($x in $m) {
        $out += ('    {0}:{1}  {2}' -f $x.Path.Replace($root.P + '\', ''), $x.LineNumber, $x.Line.Trim())
    }
}
$out += ''

# --- 3. 是否有 create_country_leader 提到他 ---
$out += '==================== 3. create_country_leader 提到 smilga 的地方 ===================='
foreach ($root in @(@{N='原版';P=$V}, @{N='R56';P=$R})) {
    $files = @(Get-ChildItem -LiteralPath $root.P -Recurse -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Extension -in @('.txt', '.yml') } | Select-Object -ExpandProperty FullName)
    $m = @(Select-String -Path $files -Pattern 'create_country_leader' -ErrorAction SilentlyContinue |
           Where-Object { $_.Line -match 'smilga' })
    $out += "  --- $($root.N) （$($m.Count) 命中）---"
    foreach ($x in $m) {
        $out += ('    {0}:{1}  {2}' -f $x.Path.Replace($root.P + '\', ''), $x.LineNumber, $x.Line.Trim())
    }
}
$out += ''

# --- 4. R56 有没有给他额外的国策（扫所有 focus 文件的 focus id + 他名字） ---
$out += '==================== 4. R56 focus 文件里 smilga 的全部位置 ===================='
$fd = Join-Path $R 'common\national_focus'
$ff = @(Get-ChildItem -LiteralPath $fd -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -eq '.txt' } | Select-Object -ExpandProperty FullName)
$out += "  （R56 national_focus 共 $($ff.Count) 个文件）"
$m = @(Select-String -Path $ff -Pattern 'smilga' -ErrorAction SilentlyContinue)
foreach ($x in $m) {
    $out += ('    {0}:{1}' -f (Split-Path $x.Path -Leaf), $x.LineNumber)
    $out += ('        ' + $x.Line.Trim())
}
$out += ''

# --- 5. 我们的 mod 现在怎么处理 SOV_integrate_smirnovs_bloc ---
$out += '==================== 5. 本项目 mod 里的 smilga / integrate_smirnovs_bloc ===================='
$md = Join-Path $PSScriptRoot '..\mod\heart_of_iron'
$mf = @(Get-ChildItem -LiteralPath $md -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @('.txt', '.yml') } | Select-Object -ExpandProperty FullName)
$out += "  （mod 共 $($mf.Count) 个 txt/yml）"
foreach ($pat in @('smilga', 'integrate_smirnovs_bloc', 'eliminate_the_left')) {
    $m = @(Select-String -Path $mf -Pattern $pat -ErrorAction SilentlyContinue)
    $out += "  --- /$pat/ （$($m.Count) 命中）---"
    foreach ($x in @($m | Select-Object -First 12)) {
        $out += ('    {0}:{1}  {2}' -f $x.Path.Replace((Resolve-Path $md).Path + '\', ''), $x.LineNumber, $x.Line.Trim())
    }
}
$out += ''

# --- 6. 花名册里的斯米尔加现况 ---
$out += '==================== 6. 本项目花名册 Idx 10 ===================='
$gp = Join-Path $PSScriptRoot 'gen-hof-ic-s3.ps1'
$G = [System.IO.File]::ReadAllLines($gp)
for ($i = 470; $i -le 482; $i++) { if ($i -le $G.Count) { $out += ('  {0,6}: {1}' -f $i, $G[$i - 1].TrimEnd()) } }
$out += ''

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-smilga-check.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

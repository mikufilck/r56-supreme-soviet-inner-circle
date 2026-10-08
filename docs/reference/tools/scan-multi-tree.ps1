# scan-multi-tree.ps1
# 目的：解析 R56 每个 focus_tree 的 id / 所在文件 / country 评分块，
#       用于判定「同一 TAG 有多棵树时，实际加载哪一棵」。
# 用法：powershell -File scan-multi-tree.ps1 > 输出文件
#
# 原理：focus_tree 的 country = { ... } 是 MTTH 评分块，开局前求值一次，
#       得分最高者被加载。故必须把每个竞赛者的 factor/modifier 打出来比较。

$ErrorActionPreference = 'Stop'
$dir = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus'

# 找出从 $start（'{' 位置）起配对的右花括号位置
function Find-Match([string]$text, [int]$openIdx) {
    $depth = 0
    for ($j = $openIdx; $j -lt $text.Length; $j++) {
        $c = $text[$j]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') {
            $depth--
            if ($depth -eq 0) { return $j }
        }
    }
    return -1
}

# 从块里取第一个 id = xxx
function Get-Id([string]$block) {
    $m = [regex]::Match($block, '(?m)^\s*id\s*=\s*([A-Za-z0-9_\.]+)')
    if ($m.Success) { return $m.Groups[1].Value }
    return '?'
}

# 取 country = { ... } 的原文（保留换行，便于人读）
function Get-CountryBlock([string]$block) {
    $m = [regex]::Match($block, '(?m)^\s*country\s*=\s*\{')
    if (-not $m.Success) { return '(无 country 块)' }
    $open = $block.IndexOf('{', $m.Index)
    $close = Find-Match $block $open
    if ($close -lt 0) { return '(括号不配对)' }
    return $block.Substring($open, $close - $open + 1)
}

$rows = @()

foreach ($f in Get-ChildItem -LiteralPath $dir -Filter '*.txt' -File) {
    $text = [System.IO.File]::ReadAllText($f.FullName)
    $idx = 0
    while ($true) {
        $i = $text.IndexOf('focus_tree', $idx)
        if ($i -lt 0) { break }
        $open = $text.IndexOf('{', $i)
        if ($open -lt 0) { break }
        $close = Find-Match $text $open
        if ($close -lt 0) { break }
        $body = $text.Substring($open, $close - $open + 1)

        $id = Get-Id $body
        $cb = Get-CountryBlock $body

        # 从 country 块里抽出面向的 TAG。三种写法都要覆盖：
        #   country = { SOV = { ... } }          <- 裸 TAG 当 scope
        #   modifier = { tag = DNZ ... }         <- tag = XXX
        #   modifier = { original_tag = ETH }    <- original_tag = XXX
        # 注意：必须排除 NOT / AND / OR 等逻辑关键字，否则会把 "NOT" 误当成国家。
        $exclude = @('NOT','AND','OR','ANY','ALL','ROOT','TAG','FROM','THIS','PREV','OWNER','CONTROLLER','IF','ELSE','LIMIT')
        $found = New-Object System.Collections.ArrayList
        foreach ($m in [regex]::Matches($cb, '\b(?:tag|original_tag)\s*=\s*([A-Z]{3})\b')) {
            [void]$found.Add($m.Groups[1].Value)
        }
        foreach ($m in [regex]::Matches($cb, '(?m)^\s*([A-Z]{3})\s*=\s*\{')) {
            if ($exclude -notcontains $m.Groups[1].Value) { [void]$found.Add($m.Groups[1].Value) }
        }
        $tags = $found | Sort-Object -Unique

        $rows += [pscustomobject]@{
            File    = $f.Name
            TreeId  = $id
            Tags    = ($tags -join ',')
            Country = ($cb -replace '\s+', ' ').Trim()
        }

        $idx = $close
    }
}

# 输出 1：按 TAG 聚合，只列一 TAG 多棵树的情况（需裁决的）
Write-Output "=== 需裁决：同一 TAG 有多个 focus_tree（含各自 country 评分块） ==="
$byTag = @{}
foreach ($r in $rows) {
    foreach ($t in ($r.Tags -split ',')) {
        if ($t) {
            if (-not $byTag.ContainsKey($t)) { $byTag[$t] = @() }
            $byTag[$t] += $r
        }
    }
}
foreach ($t in ($byTag.Keys | Sort-Object)) {
    if ($byTag[$t].Count -lt 2) { continue }
    Write-Output ""
    Write-Output "### TAG $t  <- $($byTag[$t].Count) 棵树"
    foreach ($r in $byTag[$t]) {
        Write-Output ("    {0,-34} {1,-28} {2}" -f $r.TreeId, $r.File, $r.Country)
    }
}

# 输出 2：全量清单（供交叉核对）
Write-Output ""
Write-Output "=== 全量：$(($rows | Measure-Object).Count) 棵树 ==="
$rows | Sort-Object File, TreeId |
    ForEach-Object { "{0,-42} {1,-32} {2}" -f $_.File, $_.TreeId, $_.Tags }

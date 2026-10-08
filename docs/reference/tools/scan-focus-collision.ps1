# =============================================================================
# 解析苏联国策树的绝对坐标，检查"核心圈 7 个入口国策"要占的格子是否空闲
# -----------------------------------------------------------------------------
# 为什么需要这个：
#   国策的 x / y 可以是【相对】的（relative_position_id）。
#   最高苏维埃 自己就是相对定位（挂在 SOV_the_peoples_revolution 下面），
#   所以"往它下面放两个格子"到底落在哪，光看它自己的 x/y 是算不出来的。
#   前几轮我靠猜坐标，结果整排国策跑到了树的左边。这次先把绝对坐标算出来再放。
#
# 做法：
#   1. 括号配平切出每个 focus = { ... } 块，取 id / x / y / relative_position_id
#   2. 递归解析绝对坐标（带记忆化，防循环）
#   3. 输出目标格子是否被占用
# =============================================================================

# 参数化以便复用：也可以用同一个脚本去量原版德国的树，
# 用“德国窗口挂在德国树下且不重叠”这个事实反推 px/格 的换算率。
#
# ⚠️ param() 必须是脚本的第一条语句（注释之前可以，赋值之前不行），
#    放到 $ErrorActionPreference 后面会直接语法报错。
param(
    [string]$FocusFile = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\national_focus\soviet.txt',
    [string]$AnchorId  = 'SOV_the_supreme_soviet'
)

$ErrorActionPreference = 'Stop'

$sovFile = $FocusFile
$text    = [System.IO.File]::ReadAllText($sovFile)
$lines   = [System.IO.File]::ReadAllLines($sovFile)

Write-Output "文件: $sovFile"
Write-Output "行数: $($lines.Count)"

# ---------------------------------------------------------------- 1. 切块解析
#
# ⚠️ 关键：先把【注释】剥掉再数花括号。
#    否则注释里出现单个 `{` 或 `}`（例如 `# TODO: { 待补`）就会让深度跑偏，
#    后续所有块串成一个，解析结果会静默错得离谱。
#    （第一版就踩了这个：29,696 行只解析出 62 块，锚点都找不到。）
$blocks = @()
$depth = 0
$curId = $null
$curX = $null
$curY = $null
$curRel = $null
$inFocus = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    $clean = ($lines[$i] -replace '#.*$', '')

    if (-not $inFocus) {
        if ($clean -match '^\s*focus\s*=\s*\{\s*$') {
            $inFocus = $true
            $depth = 1
            $curId = $null; $curX = $null; $curY = $null; $curRel = $null
            continue
        }
        continue
    }

    # 统计本行的花括号（已剥注释）
    $depth += ([regex]::Matches($clean, '\{')).Count
    $depth -= ([regex]::Matches($clean, '\}')).Count

    if ($clean -match '^\s*id\s*=\s*([A-Za-z0-9_]+)\s*$')   { if (-not $curId) { $curId = $Matches[1] } }
    if ($clean -match '^\s*x\s*=\s*(-?\d+)\s*$')            { if ($null -eq $curX) { $curX = [int]$Matches[1] } }
    if ($clean -match '^\s*y\s*=\s*(-?\d+)\s*$')            { if ($null -eq $curY) { $curY = [int]$Matches[1] } }
    if ($clean -match '^\s*relative_position_id\s*=\s*([A-Za-z0-9_]+)\s*$') { $curRel = $Matches[1] }

    if ($depth -le 0) {
        if ($curId) {
            $blocks += [pscustomobject]@{
                Id = $curId; X = $curX; Y = $curY; Rel = $curRel; Line = $i + 1
            }
        }
        $inFocus = $false
        $depth = 0
    }
}

# 交叉验证：文件里 `focus = {` 的行数应当与解析出的块数一致。
# 不一致就说明解析器有问题，此时后面的结论一律不可信 —— 直接报出来。
$focusLineCount = 0
foreach ($ln in $lines) {
    if (($ln -replace '#.*$', '') -match '^\s*focus\s*=\s*\{\s*$') { $focusLineCount++ }
}

Write-Output "文件里 focus = { 行数: $focusLineCount"
Write-Output "解析出 focus 块: $($blocks.Count)"
if ($focusLineCount -ne $blocks.Count) {
    Write-Output "  ✗ 两者不一致 —— 解析器有问题，下面的坐标结论不可信！"
} else {
    Write-Output "  ✓ 一致，解析可信"
}

$byId = @{}
foreach ($b in $blocks) { if (-not $byId.ContainsKey($b.Id)) { $byId[$b.Id] = $b } }

# ---------------------------------------------------------------- 2. 解析绝对坐标
$absCache = @{}

function Get-AbsPos([string]$id, [int]$guard = 0) {
    if ($guard -gt 50) { return $null }                       # 防循环引用
    if ($absCache.ContainsKey($id)) { return $absCache[$id] }
    if (-not $byId.ContainsKey($id)) { return $null }

    $b = $byId[$id]
    $x = if ($null -ne $b.X) { $b.X } else { 0 }
    $y = if ($null -ne $b.Y) { $b.Y } else { 0 }

    if ($b.Rel) {
        $p = Get-AbsPos $b.Rel ($guard + 1)
        if ($null -eq $p) { return $null }                    # 挂到树外了，算不了
        $res = [pscustomobject]@{ X = $p.X + $x; Y = $p.Y + $y }
    }
    else {
        $res = [pscustomobject]@{ X = $x; Y = $y }
    }

    $absCache[$id] = $res
    return $res
}

$resolved = 0
$unresolved = @()
foreach ($b in $blocks) {
    $p = Get-AbsPos $b.Id
    if ($p) { $resolved++ } else { $unresolved += $b.Id }
}
Write-Output "绝对坐标解析成功: $resolved / $($blocks.Count)"
if ($unresolved.Count -gt 0) {
    Write-Output "  （以下 $($unresolved.Count) 个解析不了，通常是挂到别的树/别的国家的国策上）"
    Write-Output "   " + (($unresolved | Select-Object -First 12) -join ', ')
}

# ---------------------------------------------------------------- 3. 占用图
$occ = @{}
foreach ($b in $blocks) {
    # 排除我们自己注入的入口国策。
    # 不排的话，"目标格子是否被占用"就会自指成立 ——
    # 文件里已经躺着我们的国策，于是永远报冲突，掩盖真正的答案。
    if ($b.Id -like 'hof_ic_seat_*') { continue }

    $p = Get-AbsPos $b.Id
    if (-not $p) { continue }
    $key = "$($p.X),$($p.Y)"
    if (-not $occ.ContainsKey($key)) { $occ[$key] = @() }
    $occ[$key] += $b.Id
}

$xs = @($absCache.Values | ForEach-Object { $_.X })
$ys = @($absCache.Values | ForEach-Object { $_.Y })
Write-Output ''
Write-Output ("树绝对坐标范围: X {0}..{1}   Y {2}..{3}" -f ($xs | Measure-Object -Minimum).Minimum, ($xs | Measure-Object -Maximum).Maximum, ($ys | Measure-Object -Minimum).Minimum, ($ys | Measure-Object -Maximum).Maximum)

# ---------------------------------------------------------------- 4. 目标格子检查
$anchorId = $AnchorId
$anchor = Get-AbsPos $anchorId

Write-Output ''
Write-Output "===== 锚点 $anchorId 的绝对坐标 ====="
if ($anchor) {
    Write-Output ("  ({0}, {1})   [相对: {2} x={3} y={4}]" -f $anchor.X, $anchor.Y, $byId[$anchorId].Rel, $byId[$anchorId].X, $byId[$anchorId].Y)

    $relY = 2
    Write-Output ''
    Write-Output "===== 入口国策目标格子（相对锚点 x=-6..6 步长2, y=$relY）====="
    $clash = @()
    foreach ($dx in @(-6, -4, -2, 0, 2, 4, 6)) {
        $tx = $anchor.X + $dx
        $ty = $anchor.Y + $relY
        $key = "$tx,$ty"
        if ($occ.ContainsKey($key)) {
            $who = $occ[$key] -join ', '
            Write-Output ("  ({0,4},{1,4})  ✗ 已被占用: {2}" -f $tx, $ty, $who)
            $clash += $who
        }
        else {
            Write-Output ("  ({0,4},{1,4})  ✓ 空闲" -f $tx, $ty)
        }
    }

    Write-Output ''
    if ($clash.Count -gt 0) {
        Write-Output "结论：有冲突，需要换 y（例如改成 3 或 -2）或换 x 范围。"
    } else {
        Write-Output "结论：7 个目标格子全部空闲，可以放心用 relative_position_id + y=$relY。"
    }

    # 顺便把锚点下方几行整行的占用情况打出来，方便挑别的 y
    Write-Output ''
    Write-Output "===== 锚点下方 y = $($anchor.Y) .. $($anchor.Y + 5) 的占用情况（只列非空）====="
    for ($yy = $anchor.Y; $yy -le $anchor.Y + 5; $yy++) {
        $row = @()
        for ($xx = $anchor.X - 8; $xx -le $anchor.X + 8; $xx++) {
            if ($occ.ContainsKey("$xx,$yy")) { $row += ("x={0}:{1}" -f $xx, ($occ["$xx,$yy"] -join '/')) }
        }
        if ($row.Count -gt 0) { Write-Output ("  y={0,4}  {1}" -f $yy, ($row -join '   ')) }
        else { Write-Output ("  y={0,4}  （空）" -f $yy) }
    }
}
else {
    Write-Output "  找不到锚点或解析不了它的坐标。"
}

# =============================================================================
# 生成 interface/hof_ic_scripted_gui.gui
# -----------------------------------------------------------------------------
# 【现行版：760 x 740，七席两排；取消底部候选小框】
#
# 为什么放大画布：
#   原画布 631x583，但底板的实体画框只有 16..614 / 26..550（四周透明，
#   实测见 docs/reference/scan-window-art-bounds.ps1）。
#   1:1 排布需要的内容高度是 586，加留白约 626，横向 605 —— 原画框装不下。
#   上一版试过把席位缩到 0.85 硬塞，观感太挤，已废弃。
#   现在改为【放大画布】让全部素材保持 1:1，并把新尺寸交给 GPT 重画底板。
#
# 底板与席位框见 art/inner_circle/v3/，均已导出到 mod/gfx/interface/hof_ic/。
#
# 三条硬规矩（都是踩坑后加的，别改）：
#   1. 所有元素的 orientation 一律 upper_left。
#      y 永远从容器顶部算；水平居中由 (容器宽 - 素材宽)/2 显式算出。
#      混用 center / center_up 会让 y 变成"从容器中心算"，表现是底板与文字错位。
#   2. 内容必须落在画布之内（下面的自检会断言）。
#   3. 业务代码里的函数名不要用短名 —— `sc` 这类是 PowerShell 内置别名，
#      而解析优先级是【别名 > 函数】，会让脚本被误导去调 Set-Content 并卡住。
# =============================================================================

$ErrorActionPreference = 'Stop'

$modRoot   = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
$outPath   = Join-Path $modRoot 'interface\hof_ic_scripted_gui.gui'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# =============================================================================
# 布局常量 —— 想调版面只改这一段
# =============================================================================

# 画布 = 窗口尺寸 =【新底板的尺寸】，要与 docs/16 里的要求一致
$CANVAS_W = 760
$CANVAS_H = 740

# ---- 素材原始尺寸（docs/16，全部 1:1 使用）----
$LEADER_SIZE       = 165
$LEADER_RIBBON_W   = 160
$LEADER_RIBBON_H   = 36
$LEADER_TITLEBOX_W = 115
$LEADER_TITLEBOX_H = 22

# 🚩 席位【容器】宽 150，不是 131 —— 131 是框/立绘的美术尺寸。
#    名牌 146、特质框 144 都比 131 宽，容器再用 131 就会横向溢出 18px
#    （2026-09-15 修：游戏里红名牌比席位框还宽、横着挤在一起）。
#    德国原版的席位容器也是 150x120，名牌/特质框居中在 150 里，所以从不溢出。
$SEAT_W = 150
$SEAT_H = 215
$SEAT_ART_W = 131   # 席位框 / 立绘框的美术宽度（1:1）
$SEAT_ART_X = 10    # 框在容器里居中 (150-131)/2
$PORTRAIT_X = 28    # 立绘按 0.60 缩放；避开新框顶部和左右金属边
$PLATE_W = 146      # 名牌底衬
$PLATE_H = 26
$TRAITB_W = 144     # 特质框
$TRAITB_H = 43

# 席位内部各元素的 y（1:1）
$PLATE_Y     = 145
$NAME_TXT_Y  = 150
$TRAITB_Y    = 172
$TRAIT_TXT_Y = 179
$TEXT_W      = 140
$TEXT_H      = 18

# ---- 纵向排布 ----
$TITLE_Y  = 22
$TITLE_H  = 34
$LEADER_Y = 70                                   # 领袖容器顶部
$LEADER_RIBBON_Y   = $LEADER_Y + 120             # 绸带（相对画布）
$LEADER_TITLEBOX_Y = $LEADER_Y + 150             # 头衔框（相对画布）
$LEADER_BLOCK_BOT  = $LEADER_TITLEBOX_Y + $LEADER_TITLEBOX_H   # 领袖区实际下沿
$ROW1_Y   = 255
$ROW2_Y   = 490

# ---- 横向 ----
# 四个 150px 席位之间保留 30px，外边距 35px
$SEAT_GAP  = 30
$SEAT_STEP = $SEAT_W + $SEAT_GAP

$row1Count = 4
$row2Count = 3
$row1Span  = $row1Count * $SEAT_STEP - $SEAT_GAP
$row2Span  = $row2Count * $SEAT_STEP - $SEAT_GAP
$row1X0    = [int][Math]::Round(($CANVAS_W - $row1Span) / 2.0)
$row2X0    = [int][Math]::Round(($CANVAS_W - $row2Span) / 2.0)

$seatTargets = @()
foreach ($i in 0..($row1Count - 1)) {
    $seatTargets += [pscustomobject]@{ N = $i + 1; X = $row1X0 + $i * $SEAT_STEP; Y = $ROW1_Y }
}
foreach ($i in 0..($row2Count - 1)) {
    $seatTargets += [pscustomobject]@{ N = $row1Count + $i + 1; X = $row2X0 + $i * $SEAT_STEP; Y = $ROW2_Y }
}

function CenterOf([int]$containerW, [int]$itemW) {
    return [int][Math]::Round(($containerW - $itemW) / 2.0)
}
function CenterX([int]$itemW) {
    return [int][Math]::Round(($CANVAS_W - $itemW) / 2.0)
}

# =============================================================================
# 生成
# =============================================================================
$sb = New-Object System.Text.StringBuilder
function Emit([string]$s) { $null = $sb.AppendLine($s) }

Emit '# ============================================================================='
Emit '# 核心圈窗口本体'
Emit '# -----------------------------------------------------------------------------'
Emit '# 由 build/gen-hof-ic-gui.ps1 生成 —— 勿手改，改布局请改那个脚本里的常量表。'
Emit '#'
Emit "# 画布 $CANVAS_W x $CANVAS_H；席位头像按 0.60、领袖头像按 0.53 缩放。"
Emit '#'
Emit '# ⚠️ 三条硬规矩（都是踩坑后加的，别改）：'
Emit '#   1. 所有元素的 orientation 一律 upper_left，y 从容器顶部算；'
Emit '#      水平居中由 (容器宽 - 素材宽)/2 显式算出。混用 center / center_up'
Emit '#      会让 y 变成"从容器中心算"，表现是底板与文字错位。'
Emit '#   2. 内容必须落在画布之内（生成器会断言）。'
Emit '#   3. 底板美术铺满画布，四周无透明边；矩形肖像必须缩入框内。'
Emit '#'
Emit '# sprite 走 GFX_hof_ic_* 间接层（见 interface/hof_ic.gfx）。'
Emit '# ============================================================================='
Emit ''
Emit 'guiTypes = {'
Emit ''
Emit '	containerWindowType = {'
Emit '		name = "hof_ic_ui_window"'
Emit '		orientation = lower_left'
Emit '		position = { x = 0 y = 0 }'
Emit "		size = { width = $CANVAS_W height = $CANVAS_H }"
Emit '		clipping = no'
Emit ''
Emit '		# ---------------- 窗口底板 ----------------'
Emit '		background = {'
Emit '			name = "background"'
Emit '			quadTextureSprite = "GFX_hof_ic_window_bg"'
Emit '			alwaystransparent = yes'
Emit '		}'
Emit ''
Emit '		# ---------------- 标题 ----------------'
Emit '		instantTextBoxType = {'
Emit '			name = "hof_ic_title"'
Emit '			orientation = upper_left'
Emit "			position = { x = $(CenterX 600) y = $TITLE_Y }"
Emit '			font = "hoi_36header"'
Emit '			text = "hof_ic_title_text"'
Emit '			format = center'
Emit '			maxWidth = 600'
Emit "			maxHeight = $TITLE_H"
Emit '		}'
Emit ''

# ---------------------------------------------------------------- 领袖位
Emit '		# ========================================================================='
Emit '		# 领袖位（1:1）'
Emit '		# ========================================================================='
Emit '		containerWindowType = {'
Emit '			name = "hof_ic_leader_container"'
Emit '			orientation = upper_left'
Emit "			position = { x = $(CenterX $LEADER_SIZE) y = $LEADER_Y }"
Emit "			size = { width = $LEADER_SIZE height = $LEADER_SIZE }"
Emit '			clipping = no'
Emit ''
Emit '			# 立绘：spriteType 留空，由 inlay window 的 scripted_images 供给'
Emit '			iconType = {'
Emit '				name = "hof_ic_leader_portrait"'
Emit '				spriteType = ""'
Emit '				orientation = upper_left'
Emit '				position = { x = 41 y = 35 }'
Emit '				scale = 0.53'
Emit '				alwaystransparent = yes'
Emit '			}'
Emit ''
Emit '			# 圆框后画，盖住议场肖像的矩形边缘'
Emit '			iconType = {'
Emit '				name = "hof_ic_leader_frame"'
Emit '				spriteType = "GFX_hof_ic_leader_frame"'
Emit '				orientation = upper_left'
Emit '				position = { x = 0 y = 0 }'
Emit '				alwaystransparent = yes'
Emit '			}'
Emit ''
Emit '			# 名牌缎带（160 x 36）——贴在圆框下缘'
Emit '			iconType = {'
Emit '				name = "hof_ic_leader_ribbon"'
Emit '				spriteType = "GFX_hof_ic_leader_ribbon"'
Emit '				orientation = upper_left'
Emit "				position = { x = $(CenterOf $LEADER_SIZE $LEADER_RIBBON_W) y = $($LEADER_RIBBON_Y - $LEADER_Y) }"
Emit '				alwaystransparent = yes'
Emit '			}'
Emit ''
Emit '			# 领袖名字（贴在缎带上）'
Emit '			instantTextBoxType = {'
Emit '				name = "hof_ic_leader_name"'
Emit '				orientation = upper_left'
Emit "				position = { x = $(CenterOf $LEADER_SIZE 160) y = $($LEADER_RIBBON_Y - $LEADER_Y + 7) }"
Emit '				font = "hoi_18mbs"'
Emit '				text = "hof_ic_leader_name_text"'
Emit '				format = center'
Emit '				maxWidth = 160'
Emit '				maxHeight = 22'
Emit '				alwaystransparent = yes'
Emit '			}'
Emit ''
Emit '			# 头衔框（115 x 22）'
Emit '			iconType = {'
Emit '				name = "hof_ic_leader_title_box"'
Emit '				spriteType = "GFX_hof_ic_leader_title_box"'
Emit '				orientation = upper_left'
Emit "				position = { x = $(CenterOf $LEADER_SIZE $LEADER_TITLEBOX_W) y = $($LEADER_TITLEBOX_Y - $LEADER_Y) }"
Emit '				alwaystransparent = yes'
Emit '			}'
Emit ''
Emit '			# 头衔文字'
Emit '			instantTextBoxType = {'
Emit '				name = "hof_ic_leader_title"'
Emit '				orientation = upper_left'
Emit "				position = { x = $(CenterOf $LEADER_SIZE $LEADER_TITLEBOX_W) y = $($LEADER_TITLEBOX_Y - $LEADER_Y + 3) }"
Emit '				font = "hoi_18mbs"'
Emit '				text = "hof_ic_leader_title_text"'
Emit '				format = center'
Emit "				maxWidth = $LEADER_TITLEBOX_W"
Emit '				maxHeight = 20'
Emit '				alwaystransparent = yes'
Emit '			}'
Emit '		}'
Emit ''

# ---------------------------------------------------------------- 席位
Emit '		# ========================================================================='
Emit '		# 席位 1-7（第一排 4 个、第二排 3 个，1:1）'
Emit '		# ========================================================================='

foreach ($s in $seatTargets) {

    $n = $s.N
    $rowLabel = if ($n -le $row1Count) { '第一排' } else { '第二排' }

    Emit ''
    Emit "		# ---- 席位 $n（$rowLabel）----"
    Emit '		containerWindowType = {'
    Emit "			name = `"hof_ic_seat_${n}_container`""
    Emit '			orientation = upper_left'
    Emit "			position = { x = $($s.X) y = $($s.Y) }"
    Emit "			size = { width = $SEAT_W height = $SEAT_H }"
    Emit '			clipping = no'
    Emit ''
    Emit '			# 立绘：156x210 按 0.60 缩放，四边缩入金属框的内缘'
    Emit '			iconType = {'
    Emit "				name = `"hof_ic_seat_${n}_portrait`""
    Emit '				spriteType = ""'
    Emit '				orientation = upper_left'
    Emit "				position = { x = $PORTRAIT_X y = 12 }"
    Emit '				scale = 0.60'
    Emit '				alwaystransparent = yes'
    Emit '			}'
    Emit ''
    Emit '			# 席位框盖在立绘外缘；spriteType 由 scripted_images 按空/满切换'
    Emit '			iconType = {'
    Emit "				name = `"hof_ic_seat_${n}_frame`""
    Emit '				spriteType = ""'
    Emit '				orientation = upper_left'
    Emit "				position = { x = $SEAT_ART_X y = 0 }"
    Emit '			}'
    Emit ''
    Emit '			# 名牌底衬（画在立绘之上）'
    Emit '			iconType = {'
    Emit "				name = `"hof_ic_seat_${n}_name_box`""
    Emit '				spriteType = "GFX_hof_ic_seat_name_box"'
    Emit '				orientation = upper_left'
    Emit "				position = { x = $(CenterOf $SEAT_W $PLATE_W) y = $PLATE_Y }"
    Emit '				alwaystransparent = yes'
    Emit '			}'
    Emit ''
    Emit '			# 席位名（脚本本地化，方括号是必须的）'
    Emit '			instantTextBoxType = {'
    Emit "				name = `"hof_ic_seat_${n}_name`""
    Emit '				orientation = upper_left'
    Emit "				position = { x = $(CenterOf $SEAT_W $TEXT_W) y = $NAME_TXT_Y }"
    Emit '				font = "hoi_18mbs"'
    Emit "				context_aware_text = [hof_ic_slot_${n}_name]"
    Emit '				format = center'
    Emit "				maxWidth = $TEXT_W"
    Emit "				maxHeight = $TEXT_H"
    Emit '				alwaystransparent = yes'
    Emit '			}'
    Emit ''
    Emit '			# 特质框'
    Emit '			iconType = {'
    Emit "				name = `"hof_ic_seat_${n}_trait_box`""
    Emit '				spriteType = "GFX_hof_ic_seat_trait_box"'
    Emit '				orientation = upper_left'
    Emit "				position = { x = $(CenterOf $SEAT_W $TRAITB_W) y = $TRAITB_Y }"
    Emit '				alwaystransparent = yes'
    Emit '			}'
    Emit ''
    Emit '			# 特质名'
    Emit '			instantTextBoxType = {'
    Emit "				name = `"hof_ic_seat_${n}_trait`""
    Emit '				orientation = upper_left'
    Emit "				position = { x = $(CenterOf $SEAT_W $TEXT_W) y = $TRAIT_TXT_Y }"
    Emit '				font = "hoi_18mbs"'
    Emit "				context_aware_text = [hof_ic_slot_${n}_trait]"
    Emit '				format = center'
    Emit "				maxWidth = $TEXT_W"
    Emit "				maxHeight = $TEXT_H"
    Emit '				alwaystransparent = yes'
    Emit '			}'
    Emit '		}'
}

Emit '	}'
Emit '}'

[System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)

# =============================================================================
# 输出与自检
# =============================================================================
$txt = $sb.ToString()
Write-Output "写出 $outPath"
Write-Output ("行数 = {0}" -f (([regex]::Matches($txt, "`n")).Count + 1))
Write-Output "画布 = $CANVAS_W x $CANVAS_H；七个 150x215 席位，无底部候选栏"

Write-Output ''
Write-Output '======== 布局摘要 ========'
Write-Output ("  标题      y = {0} .. {1}    x = {2}" -f $TITLE_Y, ($TITLE_Y + $TITLE_H), (CenterX 600))
Write-Output ("  领袖位    y = {0} .. {1}    x = {2}" -f $LEADER_Y, ($LEADER_Y + $LEADER_SIZE), (CenterX $LEADER_SIZE))
Write-Output ("    绸带    y = {0} .. {1}" -f $LEADER_RIBBON_Y, ($LEADER_RIBBON_Y + $LEADER_RIBBON_H))
Write-Output ("    头衔框  y = {0} .. {1}" -f $LEADER_TITLEBOX_Y, $LEADER_BLOCK_BOT)
Write-Output ("  第一排    y = {0} .. {1}    x = {2}" -f $ROW1_Y, ($ROW1_Y + $SEAT_H), (($seatTargets | Where-Object { $_.Y -eq $ROW1_Y } | ForEach-Object { $_.X }) -join ', '))
Write-Output ("  第二排    y = {0} .. {1}    x = {2}" -f $ROW2_Y, ($ROW2_Y + $SEAT_H), (($seatTargets | Where-Object { $_.Y -eq $ROW2_Y } | ForEach-Object { $_.X }) -join ', '))
Write-Output ("  席位尺寸  {0} x {1}（原始尺寸，未缩放）" -f $SEAT_W, $SEAT_H)

Write-Output ''
Write-Output '======== 自检 ========'
$fail = 0

$o  = ([regex]::Matches($txt, '\{')).Count
$cl = ([regex]::Matches($txt, '\}')).Count
$ok = if ($o -eq $cl) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok] 花括号配平 {=$o }=$cl"

$ob = ([regex]::Matches($txt, '\[')).Count
$cb = ([regex]::Matches($txt, '\]')).Count
$ok = if ($ob -eq $cb) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok] 方括号配平 [=$ob ]=$cb"

$orientLines = @([regex]::Matches($txt, '(?m)^\s*orientation\s*=\s*(\S+)\s*$') | ForEach-Object { $_.Groups[1].Value })
$bad = @($orientLines | Where-Object { $_ -ne 'upper_left' -and $_ -ne 'lower_left' })
$ok = if ($bad.Count -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok] 锚点只用 upper_left / lower_left（其它 $($bad.Count) 处）"

$need = @('hof_ic_leader_portrait', 'hof_ic_leader_frame', 'hof_ic_leader_ribbon', 'hof_ic_leader_name', 'hof_ic_leader_title_box', 'hof_ic_leader_title')
foreach ($i in 1..7) {
    $need += "hof_ic_seat_${i}_container"
    $need += "hof_ic_seat_${i}_frame"
    $need += "hof_ic_seat_${i}_portrait"
    $need += "hof_ic_seat_${i}_name_box"
    $need += "hof_ic_seat_${i}_name"
    $need += "hof_ic_seat_${i}_trait_box"
    $need += "hof_ic_seat_${i}_trait"
}
$miss = @($need | Where-Object { $txt -notmatch ('name\s*=\s*"' + [regex]::Escape($_) + '"') })
$ok = if ($miss.Count -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok] 组件名齐全（缺 $($miss.Count) 个）"

# 不得再出现缩放
$scHits = @([regex]::Matches($txt, '(?m)^\s*scale\s*=\s*([0-9.]+)\s*$') | ForEach-Object { $_.Groups[1].Value })
$badScale = @($scHits | Where-Object { $_ -ne '0.60' -and $_ -ne '0.53' })
$ok = if ($badScale.Count -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok] 无额外缩放（只允许席位 0.60 / 领袖 0.53；其它 $($badScale.Count) 处：$($badScale -join ',')）"

# 内容必须落在画布内
$violations = @()
$vertical = @(
    @{ N = '标题';   T = $TITLE_Y;  B = $TITLE_Y + $TITLE_H }
    @{ N = '领袖位'; T = $LEADER_Y; B = $LEADER_BLOCK_BOT }
    @{ N = '第一排'; T = $ROW1_Y;   B = $ROW1_Y + $SEAT_H }
    @{ N = '第二排'; T = $ROW2_Y;   B = $ROW2_Y + $SEAT_H }
)
foreach ($v in $vertical) {
    if ($v.T -lt 0) { $violations += "$($v.N) 顶部为负" }
    if ($v.B -gt $CANVAS_H) { $violations += "$($v.N) 底部 $($v.B) 超出画布高 $CANVAS_H" }
}
for ($i = 0; $i -lt $vertical.Count - 1; $i++) {
    if ($vertical[$i].B -gt $vertical[$i + 1].T) {
        $violations += "$($vertical[$i].N) 底 $($vertical[$i].B) 压到 $($vertical[$i+1].N) 顶 $($vertical[$i+1].T)"
    }
}
$plateOverhang = [int][Math]::Round(($PLATE_W - $SEAT_W) / 2.0)
$seatL = (($seatTargets | ForEach-Object { $_.X } | Measure-Object -Minimum).Minimum) - $plateOverhang
$seatR = (($seatTargets | ForEach-Object { $_.X + $SEAT_W } | Measure-Object -Maximum).Maximum) + $plateOverhang
if ($seatL -lt 0) { $violations += "席位左缘（含名牌外伸）$seatL < 0" }
if ($seatR -gt $CANVAS_W) { $violations += "席位右缘（含名牌外伸）$seatR > $CANVAS_W" }
if ($TRAITB_Y + $TRAITB_H -gt $SEAT_H) { $violations += "席位内特质框底 $($TRAITB_Y + $TRAITB_H) 超出容器高 $SEAT_H" }

$ok = if ($violations.Count -eq 0) { 'OK ' } else { $fail++; 'FAIL' }
Write-Output "  [$ok] 内容全部落在画布 $CANVAS_W x $CANVAS_H 之内且互不重叠"
foreach ($v in $violations) { Write-Output "         ✗ $v" }

$bom = (Get-Content -LiteralPath $outPath -Encoding Byte -TotalCount 3) -join ','
$ok = if ($bom -eq '239,187,191') { $fail++; 'FAIL' } else { 'OK ' }
Write-Output "  [$ok] 无 BOM（.gui 必须无 BOM）"

Write-Output ''
if ($fail -gt 0) { throw "自检失败 $fail 项" }
Write-Output '生成完成，全部自检通过'

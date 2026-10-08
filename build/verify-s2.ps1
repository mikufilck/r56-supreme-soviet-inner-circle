# verify-s2.ps1
# ---------------------------------------------------------------------------
# S2 预检：在启动游戏之前，静态核对核心圈窗口各文件的引用是否自洽。
# 重点抓「静默失败」类错误 —— 名字写错时 HOI4 不报错，只是不生效。
# 用法：powershell -NoProfile -File verify-s2.ps1
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$ModRoot  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'
$GameRoot = 'F:\Hearts.of.Iron.IV.v1.19.3.0'

# texturefile 的外部查找路径（见 6b）：
# HOI4 的贴图路径按“本体 + 全部已加载 mod”统一解析，
# 所以引用 R56 / 本体 / DLC 自带的素材是【合法】的，不能当错报。
#
# ⚠️ 必须包含 dlc\*\ ——有些立绘只存在 DLC 目录里。
#    例：布哈林/李可夫的 156x210 立绘在 dlc034_no_step_back\gfx\leaders\SOV\。
#    漏掉 DLC 会得出“这两人没有大幅立绘”的【错误结论】（已踩过一次）。
$VanillaRoot = $GameRoot
$R56Root     = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$AssetRoots  = @($VanillaRoot, $R56Root)
$dlcDir = Join-Path $GameRoot 'dlc'
if (Test-Path $dlcDir) {
    $AssetRoots += @(Get-ChildItem $dlcDir -Directory -ErrorAction SilentlyContinue |
                     Select-Object -ExpandProperty FullName)
}

$guiFile  = Join-Path $ModRoot 'interface\hof_ic_scripted_gui.gui'
$iwFile   = Join-Path $ModRoot 'common\focus_inlay_windows\hof_ic_inlay_window.txt'
$locFile  = Join-Path $ModRoot 'localisation\simp_chinese\hof_ic_l_simp_chinese.yml'
$sovFile  = Join-Path $ModRoot 'common\national_focus\soviet.txt'

$fail = 0
$checks = 0
$failMsgs = @()
function Fail($msg) {
    Write-Output ("  ✗ " + $msg)
    $script:fail++
    $script:checks++
    # 顺手落盘一份真 UTF-8 失败清单。
    # ⚠️ 控制台输出编码（PS 5.1 下常为 GBK）会把 ✗ 与中文一并替换成 '?'，
    #    导致从终端/重定向日志里【无法区分 Pass 与 Fail】。
    #    这里的文件由 .NET 直接写，不受控制台编码影响。
    $script:failMsgs += $msg
}
function Pass($msg) { Write-Output ("  ✓ " + $msg); $script:checks++ }

# ---------- 读取 ----------
$gui = [System.IO.File]::ReadAllText($guiFile)
$iw  = [System.IO.File]::ReadAllText($iwFile)
$loc = [System.IO.File]::ReadAllText($locFile)
$sov = [System.IO.File]::ReadAllText($sovFile)

# ---------- 1. 括号配平 ----------
Write-Output "=== 1. 括号配平 ==="
foreach ($pair in @(@('gui(.gui)', $gui), @('inlay window(.txt)', $iw))) {
    $o = ([regex]::Matches($pair[1], '\{')).Count
    $c = ([regex]::Matches($pair[1], '\}')).Count
    if ($o -eq $c) { Pass ("{0}  左 {1} / 右 {2}" -f $pair[0], $o, $c) }
    else { Fail ("{0}  左 {1} / 右 {2} —— 不配平！" -f $pair[0], $o, $c) }
}

# ---------- 2. window_name 必须与 .gui 里的窗口名一致 ----------
Write-Output ""
Write-Output "=== 2. window_name 与 .gui 窗口名一致 ==="
$iwWinName = ([regex]::Match($iw, 'window_name\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
if ($gui -match ('name\s*=\s*"' + [regex]::Escape($iwWinName) + '"')) {
    Pass ("window_name = " + $iwWinName + "  在 .gui 中找到")
} else {
    Fail ("window_name = " + $iwWinName + "  在 .gui 中【找不到】")
}

# ---------- 3. scripted_images 的键必须都是 .gui 里的组件名 ----------
Write-Output ""
Write-Output "=== 3. scripted_images 键 -> .gui 组件名 ==="
$siBlock = ([regex]::Match($iw, 'scripted_images\s*=\s*\{')).Success
if (-not $siBlock) { Fail "inlay window 里没有 scripted_images 块" }

# 取 scripted_images 块内的顶层键（缩进两级的 name = ...）
$siKeys = @()
foreach ($m in [regex]::Matches($iw, '(?m)^\t\t([A-Za-z0-9_]+)\s*=\s*\{')) {
    $siKeys += $m.Groups[1].Value
}
if ($siKeys.Count -eq 0) { Fail "没解析到 scripted_images 的键" }
foreach ($k in $siKeys) {
    if ($gui -match ('name\s*=\s*"' + [regex]::Escape($k) + '"')) {
        Pass ("scripted_images 键 " + $k + " -> .gui 有同名组件")
    } else {
        Fail ("scripted_images 键 " + $k + " -> .gui 中【无】同名组件（会静默不生效）")
    }
}

# ---------- 4. 反向：.gui 里 spriteType="" 的组件必须有 scripted 来源 ----------
Write-Output ""
Write-Output "=== 4. .gui 中 spriteType=\"\" 的组件 -> 是否有 scripted_images 供给 ==="
$emptySpriteNames = @()
foreach ($m in [regex]::Matches($gui, '(?s)name\s*=\s*"([A-Za-z0-9_]+)"\s*\r?\n\s*spriteType\s*=\s*""')) {
    $emptySpriteNames += $m.Groups[1].Value
}
if ($emptySpriteNames.Count -eq 0) { Write-Output "  （无）" }
foreach ($n in $emptySpriteNames) {
    if ($siKeys -contains $n) { Pass ($n + "  有 scripted_images 供给") }
    else { Fail ($n + "  是空 spriteType 但【没有】scripted_images 供给 → 永远不显示") }
}

# ---------- 5. .gui 引用的本地化键是否存在 ----------
Write-Output ""
Write-Output "=== 5. .gui 引用的本地化键 ==="
$locKeys = @()
foreach ($m in [regex]::Matches($gui, '(?:text|context_aware_text)\s*=\s*"([A-Za-z0-9_]+)"')) {
    $locKeys += $m.Groups[1].Value
}
$locKeys = $locKeys | Sort-Object -Unique
if ($locKeys.Count -eq 0) { Write-Output "  （无）" }
foreach ($k in $locKeys) {
    if ($loc -match ('(?m)^\s*' + [regex]::Escape($k) + '\s*:')) { Pass ($k + "  在 .yml 中已定义") }
    else { Fail ($k + "  在 .yml 中【未定义】→ 界面会显示原始键名") }
}

# ---------- 6. 引用的 sprite 是否存在于游戏 gfx ----------
Write-Output ""
Write-Output "=== 6. .gui 引用的 sprite 是否存在 ==="
$sprites = @()
foreach ($m in [regex]::Matches($gui, '(?:quadTextureSprite|spriteType)\s*=\s*"(GFX_[A-Za-z0-9_]+)"')) {
    $sprites += $m.Groups[1].Value
}
$sprites = $sprites | Sort-Object -Unique
$gfxText = ''
foreach ($f in Get-ChildItem (Join-Path $GameRoot 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    $gfxText += [System.IO.File]::ReadAllText($f.FullName)
}
# 也要算上 mod 自己的 gfx
foreach ($f in Get-ChildItem (Join-Path $ModRoot 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    $gfxText += [System.IO.File]::ReadAllText($f.FullName)
}
foreach ($s in $sprites) {
    if ($gfxText -match ('name\s*=\s*"' + [regex]::Escape($s) + '"')) { Pass ($s + "  已定义") }
    else { Fail ($s + "  【未定义】→ 窗口该处会空白或报错") }
}

# ---------- 6b. 我们自己的 .gfx 里 texturefile 指向的文件是否真实存在 ----------
Write-Output ""
Write-Output "=== 6b. mod 自身 .gfx 的 texturefile 是否存在 ==="
$texCount = 0
foreach ($f in Get-ChildItem (Join-Path $ModRoot 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
    $lines = [System.IO.File]::ReadAllLines($f.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'texturefile\s*=\s*"([^"]+)"') {
            $tex = $Matches[1] -replace '/', '\'
            $full = Join-Path $ModRoot $tex
            # 往回找最近的 sprite 名，便于报错时定位
            $spriteName = '?'
            for ($j = $i; $j -ge [Math]::Max(0, $i - 8); $j--) {
                if ($lines[$j] -match 'name\s*=\s*"([A-Za-z0-9_]+)"') { $spriteName = $Matches[1]; break }
            }
            $texCount++
            if (Test-Path $full) {
                Pass ($spriteName + " -> " + $tex)
            }
            else {
                # 贴图不一定放在我们 mod 里。
                # HOI4 的 texturefile 是【相对路径】，按“本体 + 全部已加载 mod”
                # 统一解析，所以引用 R56 / 原版自带的素材是合法的（本项目就大量
                # 这么做：领袖立绘、想法小图都在那边）。
                # 只有三处都找不到时，才是真的错。
                $external = $null
                foreach ($root in $AssetRoots) {
                    if (-not $root) { continue }
                    if (-not (Test-Path $root)) { continue }
                    $cand = Join-Path $root $tex
                    if (Test-Path $cand) { $external = $root; break }
                }
                if ($external) {
                    $who = if ($external -eq $VanillaRoot) { '原版' }
                           elseif ($external -eq $R56Root) { 'R56' }
                           else { 'DLC:' + (Split-Path $external -Leaf) }
                    Pass ($spriteName + " -> " + $tex + "  【引用" + $who + "素材】")
                }
                else {
                    Fail ($spriteName + " -> " + $tex + "  【mod/本体/R56/DLC 都找不到】")
                }
            }
        }
    }
}
if ($texCount -eq 0) { Write-Output "  （mod 的 .gfx 里没有 texturefile）" }

# ---------- 7. 树内挂载与可见条件 ----------
Write-Output ""
Write-Output "=== 7. 苏联树内的挂载点与可见条件 ==="
if ($sov -match '(?m)^\s*id\s*=\s*hof_ic_inlay_window') {
    Pass "soviet.txt 内已声明 inlay_window -> hof_ic_inlay_window"
} else {
    Fail "soviet.txt 内【没有】hof_ic_inlay_window 声明（需跑 sync-from-r56.ps1）"
}
$visFocus = ([regex]::Match($iw, 'has_completed_focus\s*=\s*([A-Za-z0-9_]+)')).Groups[1].Value
if ($sov -match ('(?m)^\s*id\s*=\s*' + [regex]::Escape($visFocus))) {
    Pass ("可见条件所依赖的国策 " + $visFocus + " 存在于 soviet.txt")
} else {
    Fail ("可见条件依赖的国策 " + $visFocus + " 在 soviet.txt 中【不存在】")
}

# 注入块里出现字面量转义序列（\t \r\n \r\n）—— 这是 PowerShell 单引号字符串不解释转义的经典坑，
# 注进去就是语法垃圾，但 HOI4 不一定报错，属于最阴的一类失败。
$escHits = [regex]::Matches($sov, '\\[tnr](?=[A-Za-z ])')
if ($escHits.Count -gt 0) {
    Fail ("soviet.txt 的注入块里有 " + $escHits.Count + " 处【字面量转义序列】（如 \\t）—— 应为真制表符")
} else {
    Pass "注入块无字面量转义序列"
}

# ---------- 8. .yml 编码（覆盖全部本地化文件） ----------
Write-Output ""
Write-Output "=== 8. 本地化文件编码 ==="
$ymlFiles = @(Get-ChildItem (Join-Path $ModRoot 'localisation\simp_chinese') -Filter '*.yml' -File -ErrorAction SilentlyContinue)
if ($ymlFiles.Count -eq 0) { Fail "localisation\simp_chinese 下没有任何 .yml" }
foreach ($yf in $ymlFiles) {
    $b = [System.IO.File]::ReadAllBytes($yf.FullName)
    $hasBom = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
    $first = ([System.IO.File]::ReadAllLines($yf.FullName))[0]
    $nameOk = ($yf.Name -match '_l_simp_chinese\.yml$')
    $headOk = ($first -match '^\uFEFF?l_simp_chinese:\s*$')
    if ($hasBom -and $nameOk -and $headOk) {
        Pass ($yf.Name + "  BOM / 文件名后缀 / 首行 均正确")
    } else {
        Fail ($yf.Name + "  编码异常：BOM=" + $hasBom + " 文件名后缀=" + $nameOk + " 首行='" + $first + "'")
    }
}

# ---------- 9. S3 交叉引用 ----------
# 这一节专抓「名字写错 -> HOI4 不报错、只是不生效」这一类失败。
# 是本轮实际踩过坑之后补的：效果名、触发器名、动态文本键、sprite 名，
# 任何一处拼错都不会进 error.log，只会在游戏里表现为“窗口总是空的”。
Write-Output ""
Write-Output "=== 9. S3 交叉引用 ==="

$fxFile = Join-Path $ModRoot 'common\scripted_effects\hof_ic_scripted_effects.txt'
$tgFile = Join-Path $ModRoot 'common\scripted_triggers\hof_ic_scripted_triggers.txt'
$slFile = Join-Path $ModRoot 'common\scripted_localisation\hof_ic_scripted_loc.txt'

$s3Missing = @()
foreach ($p in @($fxFile, $tgFile, $slFile)) {
    if (-not (Test-Path $p)) { $s3Missing += (Split-Path $p -Leaf) }
}

if ($s3Missing.Count -gt 0) {
    Fail ("S3 文件缺失：" + ($s3Missing -join ', '))
}
else {

    $fx = [System.IO.File]::ReadAllText($fxFile)
    $fx += [System.IO.File]::ReadAllText((Join-Path $ModRoot 'common\scripted_effects\hof_ic_role_effects.txt'))
    $fx += [System.IO.File]::ReadAllText((Join-Path $ModRoot 'common\scripted_effects\hof_ic_mio_effects.txt'))
    $tg = [System.IO.File]::ReadAllText($tgFile)
    $sl = [System.IO.File]::ReadAllText($slFile)

    # 9a. soviet.txt 里调用的每个 hof_ic_* = yes，必须真有效果/触发器定义
    $called = @([regex]::Matches($sov, '(hof_ic_[A-Za-z0-9_]+)\s*=\s*yes') |
                ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missA = @()
    foreach ($c in $called) {
        $pat = '(?m)^\s*' + [regex]::Escape($c) + '\s*=\s*\{'
        if (-not (($fx -match $pat) -or ($tg -match $pat))) { $missA += $c }
    }
    if ($called.Count -eq 0) {
        Fail "SOV 树里没有任何 hof_ic_* = yes 调用（入口国策没注进去？）"
    } elseif ($missA.Count -gt 0) {
        Fail ("SOV 树调用了【未定义】的效果/触发器：" + ($missA -join ', '))
    } else {
        Pass ("SOV 树里 " + $called.Count + " 个 hof_ic_* 调用全部有定义")
    }

    # 9b. .gui 的 context_aware_text 键，必须在 scripted_localisation 里有 defined_text
    #
    # ⚠️ 这里必须接受方括号写法。HOI4 的两种写法含义不同：
    #     context_aware_text = "loc_key"          ← 引号   = 普通本地化键
    #     context_aware_text = [DefinedTextName]  ← 方括号 = 脚本本地化 defined_text
    # 我们的 hof_ic_slot_N_* 是 defined_text，所以应当是方括号。
    $caKeys = @([regex]::Matches($gui, 'context_aware_text\s*=\s*[\["]?(hof_ic_[A-Za-z0-9_]+)[\]"]?') |
                ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missB = @()
    foreach ($k in $caKeys) {
        if (-not ($sl -match ('(?m)^\s*name\s*=\s*' + [regex]::Escape($k) + '\s*$'))) { $missB += $k }
    }
    if ($caKeys.Count -eq 0) {
        Fail ".gui 里没有 context_aware_text（席位名字/头衔不会跟着席位变）"
    } elseif ($missB.Count -gt 0) {
        Fail (".gui 引用了【未定义】的动态文本键：" + ($missB -join ', '))
    } else {
        Pass (".gui 里 " + $caKeys.Count + " 个 context_aware_text 键全部有定义")
    }

    # 9b-2. 哨兵：指向 defined_text 的 context_aware_text 必须用【方括号】。
    #       写成裸的（既不引号也不方括号）会被当成字面量，
    #       界面上会直接把键名印出来 —— 游戏不报错，只有肉眼能发现（已踩过）。
    #
    #       ⚠️ 否定字符类里必须排除空白：否则 `\s*` 会回溯成零个空格，
    #          让 `=` 后面那个空格被匹配上，导致每行都误报（已踩过）。
    $bareCa = @([regex]::Matches($gui, 'context_aware_text\s*=\s*(?![\["\s])') |
                ForEach-Object { $_.Value })
    if ($bareCa.Count -gt 0) {
        Fail ("有 " + $bareCa.Count + " 处 context_aware_text 没加方括号/引号，键名会被当字面量直接显示：" + (($bareCa | Select-Object -First 3) -join ' | '))
    } else {
        Pass "所有 context_aware_text 都带了方括号或引号"
    }

    # 9c. inlay window 里引用的 GFX 名，必须在 mod 的 .gfx 里注册过
    $allGfx = ''
    foreach ($f in Get-ChildItem (Join-Path $ModRoot 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
        $allGfx += [System.IO.File]::ReadAllText($f.FullName)
    }
    $gfxRefs = @([regex]::Matches($iw, '(GFX_hof_ic_[A-Za-z0-9_]+)') |
                 ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missC = @()
    foreach ($g in $gfxRefs) {
        if (-not ($allGfx -match ('name\s*=\s*"' + [regex]::Escape($g) + '"'))) { $missC += $g }
    }
    if ($missC.Count -gt 0) {
        Fail ("inlay window 引用了【未注册】的 sprite：" + ($missC -join ', '))
    } else {
        Pass ("inlay window 里 " + $gfxRefs.Count + " 个 sprite 已全部注册")
    }

    # 9d. 普通 localization_key 必须在 yml 定义；idea_desc|<id> 是原版的动态格式化键。
    $allYml = ''
    foreach ($yf in $ymlFiles) { $allYml += [System.IO.File]::ReadAllText($yf.FullName) }
    $locKeys = @([regex]::Matches($sl, 'localization_key\s*=\s*([A-Za-z0-9_|]+)') |
                 ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $icIdeaText = [System.IO.File]::ReadAllText((Join-Path $ModRoot 'common\ideas\hof_ic_ideas.txt'))
    $icIdeaText += [System.IO.File]::ReadAllText((Join-Path $ModRoot 'common\ideas\hof_ic_role_variants.txt'))
    $missD = @()
    foreach ($k in $locKeys) {
        if ($k -match '^idea_desc\|([A-Za-z0-9_]+)$') {
            $ideaId = $Matches[1]
            if (-not ($icIdeaText -match ('(?m)^\s*' + [regex]::Escape($ideaId) + '\s*=\s*\{')) -or
                -not ($allYml -match ('(?m)^\s*' + [regex]::Escape($ideaId) + ':'))) { $missD += $k }
        } elseif (-not ($allYml -match ('(?m)^\s*' + [regex]::Escape($k) + ':'))) {
            $missD += $k
        }
    }
    if ($missD.Count -gt 0) {
        Fail ("动态文本指向【未定义】的本地化键：" + ($missD -join ', '))
    } else {
        Pass ("动态文本里 " + $locKeys.Count + " 个本地化键全部有定义")
    }

    # 9e. 每个入口国策都要有名字与说明的本地化键。
    #     HOI4 用「<focus_id>」查国策名、「<focus_id>_desc」查说明；
    #     缺了的话国策牌子上会直接显示 id 原文（像 hof_ic_seat_lev_trotsky 那样），
    #     但 error.log 里【不会有任何报错】—— 典型的静默失败。
    $focusIds = @([regex]::Matches($sov, 'id = (hof_ic_seat_[A-Za-z0-9_]+)') |
                  ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missE = @()
    foreach ($fid in $focusIds) {
        if (-not ($allYml -match ('(?m)^\s*' + [regex]::Escape($fid) + ':')))      { $missE += $fid }
        if (-not ($allYml -match ('(?m)^\s*' + [regex]::Escape($fid) + '_desc:'))) { $missE += ($fid + '_desc') }
    }
    if ($focusIds.Count -eq 0) {
        Fail "soviet.txt 里找不到入口国策 id"
    } elseif ($missE.Count -gt 0) {
        Fail ("入口国策缺本地化键（牌子上会直接显示 id）：" + ($missE -join ', '))
    } else {
        Pass ("$($focusIds.Count) 个入口国策的名称与说明本地化键齐全")
    }

    # 9f. 注入内容必须与 build/inject-sov-seats.txt 【逐字一致】。
    #     这一条专抓「读文件时编码不对，中文被解成乱码后写进 soviet.txt」——
    #     sync 脚本的 Get-Content 曾漏掉 -Encoding UTF8，把 UTF-8 注释读成 GBK 乱码，
    #     注入后就是一堆「鏍稿績鍦堝叆鍙ｃ」。垃圾是注释，不影响解析，
    #     所以游戏不报错、校验历史版本也查不出来，只能靠这种逐字比对。
    $repoRoot  = Split-Path (Split-Path $ModRoot -Parent) -Parent
    $injectSrc = Join-Path $repoRoot 'build\inject-sov-seats.txt'
    if (Test-Path $injectSrc) {
        $srcLines = @([System.IO.File]::ReadAllLines($injectSrc, [System.Text.Encoding]::UTF8) |
                      Where-Object { $_.Trim() -ne '' })
        $badLines = @()
        foreach ($ln in $srcLines) {
            if ($sov -notmatch [regex]::Escape($ln)) { $badLines += $ln.Trim() }
        }
        if ($badLines.Count -gt 0) {
            Fail ("注入内容与源文件不一致（多半是读文件时编码不对，中文变乱码）：" + $badLines.Count + " 行对不上，例如 '" + $badLines[0] + "'")
        } else {
            Pass ("注入内容与 inject-sov-seats.txt 逐行一致（核对 " + $srcLines.Count + " 行）")
        }
    } else {
        Fail "找不到 build\inject-sov-seats.txt，无法核对注入内容"
    }
}

# 9g. 个人线效果由静态职务 idea 承担，可见精神读取当前版本。
$roleIdeas = Join-Path $ModRoot 'common\ideas\hof_ic_role_variants.txt'
$roleEffects = Join-Path $ModRoot 'common\scripted_effects\hof_ic_role_effects.txt'
$roleLoc = Join-Path $ModRoot 'localisation\simp_chinese\hof_ic_role_l_simp_chinese.yml'
if ((-not (Test-Path $roleIdeas)) -or (-not (Test-Path $roleEffects)) -or (-not (Test-Path $roleLoc))) {
    Fail '最高苏维埃静态职务版本文件缺失'
} else {
    $ideaText = [IO.File]::ReadAllText($roleIdeas)
    $effectText = [IO.File]::ReadAllText($roleEffects)
    $locText = [IO.File]::ReadAllText($roleLoc)
    $missingRole = @()
    $roleIds = @([regex]::Matches($ideaText, '(?m)^\s*(hof_ic_role_[A-Za-z0-9_]+)\s*=\s*\{') | ForEach-Object { $_.Groups[1].Value })
    foreach ($id in $roleIds) {
        if ($locText -notmatch ('(?m)^\s*' + [regex]::Escape($id) + ':')) { $missingRole += $id }
    }
    if ($roleIds.Count -ne 259) { $missingRole += "idea count $($roleIds.Count)" }
    $trotskyStart = $ideaText.IndexOf('hof_ic_role_lev_trotsky_0 = {')
    $nextRoleStart = $ideaText.IndexOf('hof_ic_role_nikolay_bukharin_0 = {')
    if ($trotskyStart -lt 0 -or $nextRoleStart -le $trotskyStart) {
        $missingRole += 'Trotsky role range'
    } else {
        $trotskyRoleText = $ideaText.Substring($trotskyStart, $nextRoleStart - $trotskyStart)
        if ($trotskyRoleText -match 'army_leader_cost_factor|military_leader_cost_factor|army_core_attack_factor|modifier_army_sub_unit_militia_attack_factor') { $missingRole += 'Trotsky retired modifiers in static roles' }
        if ($trotskyRoleText -notmatch 'no_supply_grace\s*=\s*72') { $missingRole += 'Trotsky 72-hour supply grace' }
        if ($trotskyRoleText -notmatch 'production_speed_industrial_complex_factor\s*=\s*0\.05') { $missingRole += 'Trotsky uneven-development industrial construction' }
    }
    $legacyRoleText = [IO.File]::ReadAllText((Join-Path $ModRoot 'common\ideas\hof_ic_ideas.txt'))
    $legacyTrotskyEnd = $legacyRoleText.IndexOf('hof_ic_idea_nikolay_bukharin = {')
    if ($legacyTrotskyEnd -lt 0 -or $legacyRoleText.Substring(0, $legacyTrotskyEnd) -match 'army_leader_cost_factor') { $missingRole += 'Trotsky leader cost in legacy tiers' }
    $roleSpec = Get-Content (Join-Path $PSScriptRoot 'hof-ic-role-spec.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $personalFoci = @($roleSpec.Lines | ForEach-Object { $_.Line } | ForEach-Object { $_ })
    if ($personalFoci.Count -ne 152) { $missingRole += "personal focus count $($personalFoci.Count)" }
    foreach ($focus in $personalFoci) {
        $flag = 'hof_ic_done_' + $focus.Id
        if ($sov -notmatch [regex]::Escape("set_country_flag = $flag")) { $missingRole += "focus flag $($focus.Id)" }
        if ($effectText -notmatch [regex]::Escape("has_country_flag = $flag")) { $missingRole += "role selector $($focus.Id)" }
        if ($effectText -notmatch [regex]::Escape("has_completed_focus = $($focus.Id) } set_country_flag = $flag")) { $missingRole += "save migration $($focus.Id)" }
    }
    if ($sov -match 'add_dynamic_modifier\s*=\s*\{\s*modifier\s*=\s*hof_ic_(?!supreme_soviet)[A-Za-z_]+_dm') { $missingRole += 'old dynamic modifier attached' }
    if ($effectText -notmatch 'hof_ic_role_migrate_all\s*=\s*\{') { $missingRole += 'migration effect' }
    if ($missingRole.Count -gt 0) { Fail ('最高苏维埃静态职务版本缺失：' + ($missingRole -join ', ')) }
    else { Pass ("$($roleIds.Count) 个职务版本有本地化；个人动态修正不再挂载") }
}

# ---------- 10. 需求 B：中苏联合国策 —— ⛔ 2026-09-24 已取消（负向断言） ----------
# 用户 2026-09-24 口径：「先取消中苏联合国策树和专属线联合国策树，占位国策也删掉」
#   ⇒ 整条需求 B 作废（S4 作废；当年 docs/19 §7 里记的「内容是机制验证版、名称与效果是占位」
#     指的就是 hof_sino_* 这 3 条）。
# 取消这种操作最怕两类残留，HOI4 都不会报「你删漏了」：
#   ① 定义文件删了，但国策树里还留着 `shared_focus = hof_sino_*`
#      → 引用不存在的 shared focus，官方 wiki 明写【会进主菜单就崩溃】；
#   ② 定义删了、本地化 / 触发器 / 同步脚本还在 → 无害但是未清理。
# 所以这一节由「正向断言」改为「取消后残留检测」。
Write-Output ""
Write-Output "=== 10. 需求 B 已取消：残留检测（负向断言）==="

$sinoLeftover = @()

# 10a 需求 B 的三个文件必须都不存在
foreach ($rel in @('common\national_focus\hof_sino_joint.txt',
                   'common\scripted_triggers\hof_sino_scripted_triggers.txt',
                   'localisation\simp_chinese\hof_sino_l_simp_chinese.yml')) {
    if (Test-Path (Join-Path $ModRoot $rel)) { $sinoLeftover += ("文件仍在：" + $rel) }
}
if ($sinoLeftover.Count -eq 0) { Pass '需求 B 的 3 个文件已全部删除' }
else { Fail ($sinoLeftover -join ' · ') }

# 10b 任何国策树里都不许再有 shared_focus = hof_sino_*
#     （这是最危险的一类残留：引用不存在的 shared focus 会让游戏进主菜单就崩）
$sinoTreeHits = @()
foreach ($f in Get-ChildItem (Join-Path $ModRoot 'common\national_focus') -Filter '*.txt' -File -ErrorAction SilentlyContinue) {
    if ([System.IO.File]::ReadAllText($f.FullName) -match '(?m)^\s*shared_focus\s*=\s*hof_sino_') { $sinoTreeHits += $f.Name }
}
if ($sinoTreeHits.Count -eq 0) { Pass '没有任何国策树残留 shared_focus = hof_sino_*（不会出现 missing shared focus）' }
else { Fail ("这些树里还残留 hof_sino 引用：" + ($sinoTreeHits -join ', ')) }

# 10c mod 全库不许再有 hof_sino 字样
$sinoAnyHits = @()
foreach ($sub in @('common', 'localisation', 'events', 'interface', 'history')) {
    $dp = Join-Path $ModRoot $sub
    if (-not (Test-Path $dp)) { continue }
    foreach ($f in Get-ChildItem $dp -Recurse -File -Include '*.txt', '*.yml', '*.gfx', '*.gui' -ErrorAction SilentlyContinue) {
        if ([System.IO.File]::ReadAllText($f.FullName) -match 'hof_sino') { $sinoAnyHits += ($sub + '/' + $f.Name) }
    }
}
if ($sinoAnyHits.Count -eq 0) { Pass 'mod 全库无任何 hof_sino 残留（含本地化 / 触发器 / 界面）' }
else { Fail ("mod 全库仍有 hof_sino 残留：" + ($sinoAnyHits -join ', ')) }

# 10d 同步脚本不许再解析 / 注入需求 B
$sinoSyncPath = Join-Path $PSScriptRoot 'sync-from-r56.ps1'
if (-not (Test-Path $sinoSyncPath)) {
    Fail '找不到 build\sync-from-r56.ps1（无法做残留检测）'
} else {
    $sinoSyncTxt = [System.IO.File]::ReadAllText($sinoSyncPath)
    $sinoSyncCode = [regex]::Replace($sinoSyncTxt, '(?m)^\s*#.*$', '')
    if ($sinoSyncCode -match 'hofSinoSharedFocusLines') {
        Fail 'sync-from-r56.ps1 的【代码】里仍残留 $hofSinoSharedFocusLines'
    } else { Pass 'sync-from-r56.ps1 已摘除需求 B 的注入逻辑（注释里的留档不算）' }
    # ⚠️ 2026-09-25 订正：不能再对整个脚本查 'prc_sino' ——
    #    $FocusPatchMap 里【合法】有一层就叫 'prc_sino'（中共的国策效果补丁）。
    #    要查的是【$InjectMap 那个块里】有没有单独写 prc_sino 键。
    # ⚠️ 切块要用【未剥注释】的原文（边界那行本身就是注释），
    #    切完再把块内的注释剥掉再判。
    $injectStart = $sinoSyncTxt.IndexOf('$InjectMap = @{')
    $injectEnd = $sinoSyncTxt.IndexOf('# --- 工具函数')
    if ($injectStart -lt 0 -or $injectEnd -lt $injectStart) {
        Fail '读不出 sync-from-r56.ps1 的 $InjectMap 块（无法做残留检测）'
    } else {
        $injectBlock = $sinoSyncTxt.Substring($injectStart, $injectEnd - $injectStart)
        $injectBlockCode = [regex]::Replace($injectBlock, '(?m)^\s*#.*$', '')
        if ($injectBlockCode -match "'prc_sino'\s*=") {
            Fail 'sync-from-r56.ps1 的 $InjectMap 里仍单独写了 prc_sino 键'
        } else { Pass 'sync-from-r56.ps1 的 $InjectMap 已无 prc_sino 专属键（S5 由循环统一并入）' }
    }
}

# ---------- 11. S3 德式核心圈机制（动态修正容器 / 编号槽位 / 角色 idea / 事件） ----------
# 蓝本：原版德国 GER_fuhrerprinzip 的 add_dynamic_modifier 骨架。
# 这一节专抓德式机制的"静默失效"：
#   容器没定义      → 嵌层窗口永远不出现
#   角色 idea 没定义 → add_ideas 无声失败，席位永远空着
#   事件 id 拼错     → 满席时点入口国策什么都不会发生
#   工具条键没定义   → 面板上直接印出键名
# HOI4 对这四类一律【不报错】，error.log 里干干净净，只能靠这里交叉核对。
Write-Output ""
Write-Output "=== 11. S3 德式核心圈机制 ==="

if (-not $fx) { $fx = '' }

$dmDir   = Join-Path $ModRoot 'common\dynamic_modifiers'
$ideaDir = Join-Path $ModRoot 'common\ideas'
$evDir   = Join-Path $ModRoot 'events'

$dmTxt   = ''
foreach ($f in Get-ChildItem $dmDir   -Filter '*.txt' -File -ErrorAction SilentlyContinue) { $dmTxt   += [System.IO.File]::ReadAllText($f.FullName) }
$ideaTxt = ''
foreach ($f in Get-ChildItem $ideaDir -Filter '*.txt' -File -ErrorAction SilentlyContinue) { $ideaTxt += [System.IO.File]::ReadAllText($f.FullName) }
$evTxt   = ''
foreach ($f in Get-ChildItem $evDir   -Filter '*.txt' -File -ErrorAction SilentlyContinue) { $evTxt   += [System.IO.File]::ReadAllText($f.FullName) }

# 11.0 三个生成文件必须都在（缺一个就跑 gen-hof-ic-s3.ps1）
$s3Files = @(
    'common\dynamic_modifiers\hof_ic_dynamic_modifiers.txt',
    'common\ideas\hof_ic_ideas.txt',
    'events\hof_ic_events.txt'
)
$missF = @()
foreach ($rel in $s3Files) { if (-not (Test-Path (Join-Path $ModRoot $rel))) { $missF += $rel } }
if ($missF.Count -gt 0) {
    Fail ("德式机制文件缺失：" + ($missF -join ', ') + " —— 先跑 build\gen-hof-ic-s3.ps1")
} else {
    Pass "德式机制三个文件齐全（dynamic_modifiers / ideas / events）"
}

# 11.0b 角色 idea 必须有 ideas = { <category> = { } } 包裹
#       漏了会【静默不注册】—— 游戏不报错，但 idea 完全不存在，精神格也不显示
#       德国原版把职务 idea 放在 hidden_ideas 里（common/ideas/GER.txt L11339）
$ideaFile = Join-Path $ideaDir 'hof_ic_ideas.txt'
if (Test-Path $ideaFile) {
    $it = [System.IO.File]::ReadAllText($ideaFile)
    $hasOuter = ([regex]::Matches($it, '(?m)^ideas\s*=\s*\{')).Count
    $hasCat   = ([regex]::Matches($it, '(?m)^\thidden_ideas\s*=\s*\{')).Count
    $bare     = ([regex]::Matches($it, '(?m)^hof_ic_\w+\s*=\s*\{')).Count
    if ($hasOuter -eq 1 -and $hasCat -eq 1 -and $bare -eq 0) {
        Pass "角色 idea 外层结构正确（ideas = { hidden_ideas = { } }，职务不占精神格）"
    } else {
        Fail ("角色 idea 外层结构不对：ideas={0} hidden_ideas={1} 裸块={2} —— 必须恰好 1/1/0，否则 idea 静默不注册" -f $hasOuter, $hasCat, $bare)
    }
} else {
    Fail "common\ideas\hof_ic_ideas.txt 不存在 —— 先跑 build\gen-hof-ic-s3.ps1"
}

# 11a 容器本体
if ($dmTxt -match '(?m)^\s*hof_ic_supreme_soviet_dm\s*=\s*\{') {
    Pass "动态民族精神容器 hof_ic_supreme_soviet_dm 已定义"
} else {
    Fail "动态民族精神容器 hof_ic_supreme_soviet_dm 【未定义】→ 嵌层窗口永远不出现"
}

# 11a-1 可见容器必须有本地化和专属贴图；个人数值 DM 不能占额外精神格。
$icSpriteFile = Join-Path $ModRoot 'interface\hof_ic_ideas.gfx'
$icIconFile   = Join-Path $ModRoot 'gfx\interface\hof_ic\ideas\GFX_idea_hof_ic_supreme_soviet.dds'
if ($dmTxt -match '(?m)^\s*icon\s*=\s*GFX_idea_hof_ic_supreme_soviet\s*$' -and
    $loc -match '(?m)^\s*hof_ic_supreme_soviet_dm:0\s+"最高苏维埃"' -and
    (Test-Path $icSpriteFile) -and (Test-Path $icIconFile) -and
    ([System.IO.File]::ReadAllText($icSpriteFile) -match 'GFX_idea_hof_ic_supreme_soviet')) {
    Pass '最高苏维埃精神的名称、专属图标及 sprite 引用齐全'
} else {
    Fail '最高苏维埃精神缺少名称或专属图标引用'
}
$icAuxWithIcon = @(Get-ChildItem (Join-Path $ModRoot 'common\dynamic_modifiers') -Filter 'hof_ic_*_dm.txt' |
    Where-Object { [System.IO.File]::ReadAllText($_.FullName) -match '(?m)^\s*icon\s*=' })
if ($icAuxWithIcon.Count -eq 0) {
    Pass '个人数值动态修正全部隐藏图标，只保留一个可见容器'
} else {
    Fail ("个人数值动态修正仍有可见图标：" + (($icAuxWithIcon | ForEach-Object Name) -join ', '))
}

# 11b soviet.txt 里每个 add_dynamic_modifier 的 modifier= 都必须有定义
#     ⚠️ 只看 hof_ 前缀。soviet.txt 是全量复制过来的 R56 树，
#        里面还有几十个 R56 自己的 SOV_*_dynamic_modifier，
#        它们的定义在 R56 的 common\dynamic_modifiers\ 里，不在我们这个目录，
#        不做前缀过滤会全是误报（已踩过）。
$usedDm = @([regex]::Matches($sov, 'add_dynamic_modifier\s*=\s*\{\s*modifier\s*=\s*(hof_[A-Za-z0-9_]+)') |
            ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$missDm = @()
foreach ($d in $usedDm) {
    if (-not ($dmTxt -match ('(?m)^\s*' + [regex]::Escape($d) + '\s*=\s*\{'))) { $missDm += $d }
}
if ($usedDm.Count -eq 0) {
    Fail "soviet.txt 里没有 add_dynamic_modifier —— 容器根本没挂到 SOV_the_supreme_soviet 上"
} elseif ($missDm.Count -gt 0) {
    Fail ("soviet.txt 挂了【未定义】的动态修正：" + ($missDm -join ', '))
} else {
    Pass ("soviet.txt 挂载的 $($usedDm.Count) 个动态修正全部有定义")
}

# 11c hub 挂载点：2026-09-16 起 DM 不再补丁原版 SOV_the_supreme_soviet，
#     改由自建的中间国策 hof_ic_commissar（「人民委员」）挂载。
#     🚩🚩 旧断言查的是「补丁标记恰好 1 对」—— 迁移后标记应为 0 对。
$hubBeg = @([regex]::Matches($sov, '# hof:focus-begin SOV_the_supreme_soviet')).Count
$hubEnd = @([regex]::Matches($sov, '# hof:focus-end SOV_the_supreme_soviet')).Count
$cmNode = @([regex]::Matches($sov, '(?m)^\s*id = hof_ic_commissar\s*$')).Count
if ($hubBeg -eq 0 -and $hubEnd -eq 0 -and $cmNode -eq 1) {
    Pass "原版 SOV_the_supreme_soviet 已无 hub 补丁标记（0/0）；DM 转由自建 hof_ic_commissar 挂载"
} else {
    Fail ("hub 迁移未完成：旧补丁标记 begin=$hubBeg end=$hubEnd（应各 0）；id = hof_ic_commissar 找到 $cmNode 次（应为 1）")
}
$supremePos = $sov.IndexOf('id = SOV_the_supreme_soviet')
$commissarPos = $sov.IndexOf('id = hof_ic_commissar')
$firstSeatPos = $sov.IndexOf('id = hof_ic_seat_lev_trotsky')
if ($supremePos -ge 0 -and $supremePos -lt $commissarPos -and $commissarPos -lt $firstSeatPos) {
    Pass '最高苏维埃 → 人民委员 → 入席国策按相对坐标依赖顺序声明'
} else {
    Fail '苏联核心圈国策声明顺序错误：游戏会报 relative_focus_id 不存在'
}

# 11d 脚本效果/事件里 add_ideas 引用的 hof_ic_* idea 必须定义
$usedIdea = @([regex]::Matches(($fx + $effectText + $evTxt), 'add_ideas\s*=\s*(hof_ic_[A-Za-z0-9_]+)') |
              ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$missIdea = @()
foreach ($i in $usedIdea) {
    if (-not ($ideaTxt -match ('(?m)^\s*' + [regex]::Escape($i) + '\s*=\s*\{'))) { $missIdea += $i }
}
if ($usedIdea.Count -eq 0) {
    Fail "脚本效果里没有任何 hof_ic_* idea 的 add_ideas —— 任命后席位不会有内容"
} elseif ($missIdea.Count -gt 0) {
    Fail ("引用了【未定义】的角色 idea：" + ($missIdea -join ', '))
} else {
    Pass ("引用的 $($usedIdea.Count) 个角色 idea 全部有定义")
}

# 11e 席位首级 idea 数必须 == 花名册人数（每个在册人物 1 个首级 idea）
#     🚩 首级 id 结尾不带数字，所以「不含数字」的正则正好只挑出首级
#     🚩🚩 这里原本写死 7 —— 候选池 2026-09-16 扩到 22 后就崩了。改为从数据算：
#          花名册人数 = scripted_effects 里 hof_ic_idea_<key>_sync_rank 的条数（一人一条）
$nRoster  = @([regex]::Matches($fx, '(?m)^hof_ic_idea_\w+_sync_rank[ \t]*=[ \t]*\{')).Count
$baseIdea = @([regex]::Matches($ideaTxt, '(?m)^[ \t]*hof_ic_idea_[a-z_]+[ \t]*=[ \t]*\{')).Count
$allIdea  = @([regex]::Matches($ideaTxt, '(?m)^[ \t]*hof_ic_idea_[A-Za-z0-9_]+[ \t]*=[ \t]*\{')).Count
if ($nRoster -gt 0 -and $baseIdea -eq $nRoster) {
    Pass "席位首级 idea 共 $baseIdea 个（与花名册 $nRoster 人一一对应）；含职务分级共 $allIdea 个"
} else {
    Fail ("席位首级 idea 为 $baseIdea 个，应为花名册人数 $nRoster（改花名册必须同步改生成器）")
}

# 11f 职务分级：每个分级 id 都必须被 sync_rank 或国策引用到（否则定义了也没人给）
$effTxt = ''
foreach ($f in Get-ChildItem (Join-Path $ModRoot 'common\scripted_effects') -Filter '*.txt' -File -ErrorAction SilentlyContinue) {
    $effTxt += [System.IO.File]::ReadAllText($f.FullName)
}
$tierIds = [regex]::Matches($ideaTxt, '(?m)^[ \t]*(hof_ic_idea_[a-z_]+_\d+[ab]?)[ \t]*=[ \t]*\{') |
    ForEach-Object { $_.Groups[1].Value }
$orphan = @($tierIds | Where-Object { $effTxt -notmatch [regex]::Escape($_) })
if ($tierIds.Count -eq 0) {
    Pass "（暂无职务分级）"
} elseif ($orphan.Count -eq 0) {
    Pass "职务分级 $($tierIds.Count) 个全部被 sync_rank 引用"
} else {
    Fail ("有 $($orphan.Count) 个职务分级没有任何地方给：" + ($orphan -join ', '))
}

# 11f 满席替换事件必须存在、且 7 个选项各清一个槽
$repOpts = @([regex]::Matches($evTxt, 'hof_ic_replace_slot_([0-9]+)\s*=\s*yes') |
             ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object -Unique)
if ($repOpts.Count -eq 7 -and $repOpts[0] -eq 1 -and $repOpts[6] -eq 7) {
    Pass "满席替换事件有 7 个选项，覆盖槽位 1..7"
} else {
    Fail ("满席替换事件槽位覆盖不全（" + ($repOpts -join ',') + "），应为 1..7")
}

# 11g 事件命名空间
if ($evTxt -match '(?m)^\s*add_namespace\s*=\s*heartofiron\s*$') {
    Pass "事件命名空间 = heartofiron"
} else {
    Fail "events\hof_ic_events.txt 里没有 add_namespace = heartofiron"
}
if ($evTxt -match '(?m)^\s*namespace\s*=') {
    Fail '事件文件使用了 namespace =；本版本必须写 add_namespace ='
}

# 旧档个人 DM 保留无效果定义；新档只能从静态职务 idea 取得数值。
$retiredDmFile = Join-Path $ModRoot 'common\dynamic_modifiers\hof_ic_retired_personal_dm.txt'
$retiredDm = [IO.File]::ReadAllText($retiredDmFile)
$retiredCount = @([regex]::Matches($retiredDm, '(?m)^hof_ic_[a-z_]+_dm\s*=\s*\{')).Count
if ($retiredCount -eq 22 -and $retiredDm -notmatch '(?m)^\s*[a-z_]+\s*=\s*[A-Za-z0-9_]+\s*$') {
    Pass '22 个旧个人动态修正只保留失效兼容定义，无实际数值'
} else { Fail "旧个人动态修正兼容定义异常：$retiredCount 个" }
$roleIdeaText = [IO.File]::ReadAllText((Join-Path $ModRoot 'common\ideas\hof_ic_role_variants.txt'))
if ($roleIdeaText -match '(?m)^\s*planning_speed\s*=\s*0\.10\s*$' -and
    ((Get-Content (Join-Path $PSScriptRoot 'gen-hof-ic-s3.ps1') -Encoding UTF8 -Raw) -match "'planning_speed\|_planning_speed\|0\.10'")) {
    Pass '伏罗希洛夫规划速度使用引擎接受的 planning_speed 键'
} else { Fail '伏罗希洛夫规划速度未正确进入职务 idea' }

# 同一 idea 的 modifier 不能重复同名键；引擎只取最后一个并写 error.log。
$duplicateIdeaKeys = @()
foreach ($block in [regex]::Matches($ideaTxt, '(?s)\bmodifier\s*=\s*\{([^{}]*)\}')) {
    $keys = @([regex]::Matches($block.Groups[1].Value, '(?m)^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=') |
        ForEach-Object { $_.Groups[1].Value })
    $duplicateIdeaKeys += @($keys | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
}
if ($duplicateIdeaKeys.Count -gt 0) { Fail ('idea 的 modifier 重复键：' + ($duplicateIdeaKeys -join ', ')) }
else { Pass 'idea 的 modifier 块没有重复修正键' }

# 个人线的 add_to_variable 需要现存本地化键，漏键会直接在游戏里显示原始 id。
$modifiersLocPath = Join-Path $GameRoot 'localisation\simp_chinese\modifiers_l_simp_chinese.yml'
if (-not (Test-Path -LiteralPath $modifiersLocPath)) {
    Fail "找不到原版词条本地化：$modifiersLocPath"
} else {
    $officialModifiersLoc = [IO.File]::ReadAllText($modifiersLocPath)
    $focusTooltipKeys = @([regex]::Matches($sov, 'add_to_variable\s*=\s*\{\s*hof_ic_[A-Za-z0-9_]+\s*=\s*[-0-9.]+\s+tooltip\s*=\s*([A-Za-z0-9_]+)') |
        ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missingFocusTooltips = @($focusTooltipKeys | Where-Object {
        $keyPattern = '(?m)^\s*' + [regex]::Escape($_) + ':'
        $officialModifiersLoc -notmatch $keyPattern -and $allYml -notmatch $keyPattern
    })
    if ($focusTooltipKeys.Count -eq 0 -or $missingFocusTooltips.Count -gt 0) {
        Fail "个人线数值提示键缺失：$($missingFocusTooltips -join ', ')（扫描到 $($focusTooltipKeys.Count) 个）"
    } else { Pass "个人线 $($focusTooltipKeys.Count) 个数值提示键均有原版或本模组本地化" }
}

$duplicateDmKeys = @()
foreach ($dmFile in $personalDm) {
    $dmKeys = @([regex]::Matches([IO.File]::ReadAllText($dmFile.FullName), '(?m)^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*hof_ic_[A-Za-z0-9_]+\s*$') |
        ForEach-Object { $_.Groups[1].Value })
    $duplicateDmKeys += @($dmKeys | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $dmFile.Name + ':' + $_.Name })
}
if ($duplicateDmKeys.Count -gt 0) { Fail ('个人动态修正里有重复词条：' + ($duplicateDmKeys -join ', ')) }
else { Pass '22 个个人动态修正均无重复词条' }

$rankHeadings = ([regex]::Matches($sov, 'localization_key\s*=\s*hof_ic_rank_up_tt')).Count
$hiddenRankEffects = ([regex]::Matches($sov, 'hidden_effect\s*=\s*\{\s*hof_ic_idea_[A-Za-z0-9_]+_sync_rank\s*=\s*yes\s*\}')).Count
$visibleRankEffects = ([regex]::Matches($sov, '(?m)^\s*hof_ic_idea_[A-Za-z0-9_]+_sync_rank\s*=\s*yes\s*$')).Count
if ($rankHeadings -eq 0 -or $rankHeadings -ne $hiddenRankEffects -or $visibleRankEffects -ne 0) {
    Fail "个人线官衔提示分组有误：抬头 $rankHeadings / 隐藏实效 $hiddenRankEffects / 可见重复实效 $visibleRankEffects"
} else { Pass "$rankHeadings 个官衔升级均由显式差值提示 + 隐藏真实重算组成" }
$rosterLocPath = Join-Path $ModRoot 'localisation\simp_chinese\hof_ic_roster_l_simp_chinese.yml'
$rosterLoc = [IO.File]::ReadAllText($rosterLocPath)
$referencedEffectHeaders = ([regex]::Matches($rosterLoc, '(?m)^\s*hof_ic_[A-Za-z0-9_]+_extra_effects_tt:0\s+"§Y.+的职务§!追加效果："\s*$')).Count
if ($referencedEffectHeaders -ne 22) { Fail "个人线职务效果抬头应 22 个；实际 $referencedEffectHeaders 个" }
else { Pass '22 个个人线效果抬头均指向职务加成' }

# 11h 脚本效果里 country_event 引用的 id 必须在 events 里有定义
$evRefs = @([regex]::Matches($fx, 'country_event\s*=\s*([A-Za-z0-9_]+)\.([0-9]+)') |
            ForEach-Object { $_.Groups[1].Value + '.' + $_.Groups[2].Value } | Sort-Object -Unique)
$missEv = @()
foreach ($e in $evRefs) {
    if (-not ($evTxt -match ('(?m)^\s*id\s*=\s*' + [regex]::Escape($e) + '\s*$'))) { $missEv += $e }
}
if ($evRefs.Count -eq 0) {
    Fail "脚本效果里没有 country_event 调用 —— 满席时点入口国策不会有任何反应"
} elseif ($missEv.Count -gt 0) {
    Fail ("引用了【未定义】的事件：" + ($missEv -join ', '))
} else {
    Pass ("引用的 $($evRefs.Count) 个事件全部有定义")
}

# 11i 动态修正的 custom_modifier_tooltip 键必须在 yml 里有定义（否则悬停只显示键名）
$dmTt = @([regex]::Matches($dmTxt, 'custom_modifier_tooltip\s*=\s*([A-Za-z0-9_]+)') |
          ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
$missDmTt = @()
foreach ($k in $dmTt) {
    if (-not ($allYml -match ('(?m)^\s*' + [regex]::Escape($k) + ':'))) { $missDmTt += $k }
}
if ($dmTt.Count -eq 0) {
    Fail "动态修正没有 custom_modifier_tooltip —— 悬停时看不到现任 7 人名单"
} elseif ($missDmTt.Count -gt 0) {
    Fail ("动态修正工具条指向【未定义】的键：" + ($missDmTt -join ', '))
} else {
    Pass ("动态修正工具条键 $($dmTt.Count) 个均有定义")
}

# 11j 槽位替换 / 移除效果必须各 7 条
$repN = @([regex]::Matches($fx, '(?m)^\s*hof_ic_replace_slot_[0-9]+\s*=\s*\{')).Count
$remN = @([regex]::Matches($fx, '(?m)^\s*hof_ic_remove_slot_[0-9]+_idea\s*=\s*\{')).Count
if ($repN -eq 7 -and $remN -eq 7) {
    Pass "槽位替换 / 移除效果各 7 条"
} else {
    Fail ("槽位效果数量异常（replace=$repN remove=$remN，应为各 7）")
}

# ---------- 汇总 ----------
Write-Output ""
# ---------- 12. 国策图标 sprite 注册（art/focus 美术接入） ----------
Write-Output ''
Write-Output "=== 12. 国策图标 sprite 注册 ==="

$focusGfx = Join-Path $ModRoot 'interface\hof_ic_focus_icons.gfx'
if (-not (Test-Path $focusGfx)) {
    Fail "interface\hof_ic_focus_icons.gfx 不存在 —— 先跑 build\gen-hof-ic-focus-icons.ps1"
} else {
    $gx = [System.IO.File]::ReadAllText($focusGfx)

    # 12a .gfx 里引用的自家贴图必须真实存在
    $bad = @()
    foreach ($m in [regex]::Matches($gx, 'texturefile = "([^"]+)"')) {
        $rel = $m.Groups[1].Value.Replace('/', '\')
        if ($rel -like 'gfx\interface\hof_ic\*') {
            if (-not (Test-Path (Join-Path $ModRoot $rel))) { $bad += $rel }
        }
    }
    if ($bad.Count -eq 0) { Pass "图标 .gfx 引用的自家贴图全部存在" }
    else { Fail ("图标 .gfx 有 {0} 个贴图找不到：{1}" -f $bad.Count, ($bad -join ', ')) }

    # 12b 收集 mod 内全部 .gfx 注册的 sprite 名
    $sprNames = New-Object System.Collections.Generic.HashSet[string]
    Get-ChildItem (Join-Path $ModRoot 'interface') -File -Filter '*.gfx' -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($_.FullName), 'name = "([^"]+)"')) {
            $null = $sprNames.Add($m.Groups[1].Value)
        }
    }

    # 12c 国策里用到的 GFX_hof_ic_* 必须已注册，且必须另有 `_shine`
    #     🚩 国策图标漏了 `_shine` 会显示成默认占位图，而且不报错
    $used = New-Object System.Collections.Generic.HashSet[string]
    foreach ($d in @('common', 'events')) {
        $p = Join-Path $ModRoot $d
        if (-not (Test-Path $p)) { continue }
        Get-ChildItem $p -Recurse -File -Filter '*.txt' -ErrorAction SilentlyContinue | ForEach-Object {
            foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
                if ($line -match 'icon\s*=\s*(GFX_hof_ic_[A-Za-z0-9_]+)') { $null = $used.Add($Matches[1]) }
            }
        }
    }
    $unreg = @(); $noshine = @()
    foreach ($u in $used) {
        if (-not $sprNames.Contains($u)) { $unreg += $u }
        elseif (-not $sprNames.Contains($u + '_shine')) { $noshine += $u }
    }
    if ($used.Count -eq 0) {
        Fail "没有任何国策使用 GFX_hof_ic_* 图标 —— 生成器可能还在用占位图"
    } elseif ($unreg.Count -eq 0 -and $noshine.Count -eq 0) {
        Pass ("国策引用的 {0} 个专属图标全部已注册，且都带 _shine" -f $used.Count)
    } else {
        if ($unreg.Count -gt 0) { Fail ("{0} 个国策图标没注册 sprite：{1}" -f $unreg.Count, ($unreg -join ', ')) }
        if ($noshine.Count -gt 0) { Fail ("{0} 个国策图标缺 _shine（会显示占位图）：{1}" -f $noshine.Count, ($noshine -join ', ')) }
    }

    # 12d 注册张数 == 【国策引用】的图标数；贴图数可以更少
    # 🚩🚩 2026-09-16 改法：原断言是「贴图张数 == 注册张数」。
    #     加了【缺图兜底】之后不再成立 —— 美术未交付的国策图标会**复用**该人入口图标的贴图
    #     （不这么做的话 icon 指向不存在的 sprite，error.log 会报 missing sprite，违反规则 5）。
    #     现在断言的是：
    #       ① 每个被国策引用的图标都注册了 sprite（12c 已查，含 _shine）
    #       ② 注册总数 == 被引用的图标数
    #       ③ 每个注册项指向的贴图都真实存在（12c）
    $ddsCnt = (Get-ChildItem (Join-Path $ModRoot 'gfx\interface\hof_ic\focus') -File -Filter 'GFX_*.dds' -ErrorAction SilentlyContinue).Count
    $regCnt = ([regex]::Matches($gx, '(?m)^\tSpriteType = \{')).Count / 2
    $fallback = $regCnt - $ddsCnt
    if ($ddsCnt -gt 0 -and $regCnt -eq $used.Count) {
        if ($fallback -gt 0) {
            Pass ("图标注册 {0} 个 == 国策引用数；其中贴图 {1} 张，另 {2} 个是【缺图兜底】（复用已有贴图，美术交付后自动消失）" -f $regCnt, $ddsCnt, $fallback)
        } else {
            Pass ("图标贴图 {0} 张 == 注册 {0} 个（各含本体 + _shine）" -f $ddsCnt)
        }
    } else {
        Fail ("图标注册数不对：国策引用 {0} 个 / 注册 {1} 个（贴图 {2} 张）" -f $used.Count, $regCnt, $ddsCnt)
    }
}

# ---------- 13. 需求 C：经互会通用线（S5 · shared_focus + joint_focus） ----------
# 这一节专抓通用线的"静默失效"：头节点没注进树、id 拼错、本地化缺键、
# 引用的 sprite / idea / DM / 触发器不存在 —— HOI4 这些一律不报错，只是国策不出现
# 或者 error.log 里多一条 missing sprite。
Write-Output ""
Write-Output "=== 13. 经互会通用线（S5 ==="

$maFile = Join-Path $ModRoot 'common\national_focus\hof_ma_joint.txt'

if (-not (Test-Path $maFile)) {
    Fail "缺少 common\national_focus\hof_ma_joint.txt"
}
else {
    $mt = [System.IO.File]::ReadAllText($maFile)

    if ($mt -match '(?m)^\s*focus_tree\s*=\s*\{') {
        Fail "hof_ma_joint.txt 里出现了 focus_tree —— shared_focus / joint_focus 应写在文件根级"
    } else {
        Pass "hof_ma_joint.txt 是根级定义（无 focus_tree 包裹）"
    }

    $mids = @([regex]::Matches($mt, '(?m)^\s*id\s*=\s*(hof_ma_[A-Za-z0-9_]+)\s*$') | ForEach-Object { $_.Groups[1].Value })
    $maHeadIds = @([regex]::Matches($mt, '(?m)^shared_focus\s*=\s*\{\s*\r?\n\s*id\s*=\s*(hof_ma_[A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value })
    if ($mids.Count -ne 59) { Fail ("经互会通用线国策块应 59 个，实际 $($mids.Count) 个") }
    else { Pass "经互会通用线国策块 = 59（1 头 + 58 子）" }
    if ($maHeadIds.Count -ne 1) { Fail ("头节点应有 1 个 shared_focus，实际 $($maHeadIds.Count)") }
    else { Pass "头节点 = $($maHeadIds[0])（唯一的 shared_focus）" }

    # 13a 头节点必须被【每一个相位 1 挂载点的树文件】引用（含 PRC）
    #     ⚠️ 2026-09-25：带 `"s5": false` 的挂载点【豁免】——
    #        它们只是「为了改内容而覆盖的树」，本来就不该有经互会通用线。
    #        ⭐ 这里与 sync-from-r56.ps1 的跳过规则【同源】。
    #     📌 洪都拉斯（hon_std）2026-09-25 曾带过这个字段，同日又按用户口径
    #        （「洪都拉斯需要挂载经互会，应该生效」）改回注入 ⇒ 现在没有点带它。
    $apJson = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'attach-points.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $ap1 = @($apJson.points | Where-Object { $_.phase -le 1 -and $_.s5 -ne $false })
    $ap1Skip = @($apJson.points | Where-Object { $_.phase -le 1 -and $_.s5 -eq $false })
    $missTree = @()
    foreach ($pt in $ap1) {
        $tf = Join-Path $ModRoot ($pt.srcRelativePath -replace '/', '\')
        $okRef = $false
        if (Test-Path $tf) {
            $txt = [System.IO.File]::ReadAllText($tf)
            $okRef = ($txt -match ('(?m)^\s*shared_focus\s*=\s*' + [regex]::Escape($maHeadIds[0]) + '\s*$'))
        }
        if (-not $okRef) { $missTree += "$($pt.tag)/$($pt.id)" }
    }
    if ($missTree.Count -gt 0) { Fail ("未注入头节点的挂载点：" + ($missTree -join ', ')) }
    else { Pass "$($ap1.Count) 个挂载点全部引用了 $($maHeadIds[0])" }
    # 13a-2 带 s5:false 的挂载点必须【没有】引用头节点（否则等于钻进了经互会）
    $leakTree = @()
    foreach ($pt in $ap1Skip) {
        $tf = Join-Path $ModRoot ($pt.srcRelativePath -replace '/', '\')
        if (Test-Path $tf) {
            $txt = [System.IO.File]::ReadAllText($tf)
            if ($txt -match ('(?m)^\s*shared_focus\s*=\s*' + [regex]::Escape($maHeadIds[0]) + '\s*$')) { $leakTree += "$($pt.tag)/$($pt.id)" }
        }
    }
    if ($leakTree.Count -gt 0) { Fail ("s5:false 的挂载点却引用了头节点：" + ($leakTree -join ', ')) }
    elseif ($ap1Skip.Count -eq 0) { Pass "当前没有 s5:false 挂载点（机制保留备用）—— $($ap1.Count) 个挂载点全部注入经互会通用线" }
    else { Pass "$($ap1Skip.Count) 个 s5:false 挂载点未引用头节点（$((@($ap1Skip | ForEach-Object { $_.id }) ) -join ','))" }

    # 13b v7：⛔ 一条 offset 都不写、⛔ 一处 relative_position_id 都不写
    #    ⚠️ 2026-09-20 第三次订正：旧版靠「每棵树一个 offset」把带子送到树右侧，
    #    而 offset.x 依赖【该树的 X 最大】—— 那张表实测是错的
    #    （french_focus 表里 20 / 实测 67、saudi_focus 6/11、polish_focus 46/54），
    #    于是 SAU / FRA / POL 三棵树的带子被送进树身里 ⇒ 重叠。
    #    ✅ 现在：不用 offset、不用相对位置 —— 带子固定在所有树的【下方】(y = 27..33)，
    #    21 棵树实测 Y 最大只有 11 ⇒ 空出 13 行，一个都压不到。见 docs/99 §47.14。
    $offCnt = ([regex]::Matches($mt, '(?m)^\s*offset\s*=\s*\{')).Count
    if ($offCnt -ne 59) { Fail "图瓦专属 offset 应 59 条，实际 $offCnt 条" }
    else { Pass '59 条图瓦专属 offset，其他国家仍使用原有绝对格位' }
    if ($mt.Contains('relative_position_id =')) { Fail '文件里还留着 relative_position_id =（v6 起一律不用）' }
    else { Pass '全文件不使用 relative_position_id（摆位 = 绝对格位）' }

    # 13c 本地化键（缺了牌子上直接显示 id 原文）
    $maLoc = Join-Path $ModRoot 'localisation\simp_chinese\hof_ma_l_simp_chinese.yml'
    if (-not (Test-Path $maLoc)) { Fail "缺少 hof_ma_l_simp_chinese.yml" }
    else {
        $ml = [System.IO.File]::ReadAllText($maLoc)
        $b3 = (Get-Content -LiteralPath $maLoc -Encoding Byte -TotalCount 3) -join ','
        if ($b3 -ne '239,187,191') { Fail "hof_ma_l_simp_chinese.yml 缺 BOM（本地化必须是 UTF-8 with BOM）" }
        elseif (-not $ml.StartsWith('l_simp_chinese:')) { Fail "hof_ma_l_simp_chinese.yml 首行必须是 l_simp_chinese:" }
        else { Pass "hof_ma_l_simp_chinese.yml：有 BOM + 首行语言头正确" }
        $missM = @()
        foreach ($fid in $mids) {
            if (-not ($ml -match ('(?m)^\s*' + [regex]::Escape($fid) + ':')))      { $missM += $fid }
            if (-not ($ml -match ('(?m)^\s*' + [regex]::Escape($fid) + '_desc:'))) { $missM += ($fid + '_desc') }
        }
        if ($missM.Count -gt 0) { Fail ("通用线缺本地化键：" + ($missM -join ', ')) }
        else { Pass "$($mids.Count) 个国策块的名称与说明本地化键齐全" }
    }

    # 13d 引用的 idea / 动态民族精神 必须都有定义
    $idAll = ''
    foreach ($f in Get-ChildItem (Join-Path $ModRoot 'common\ideas') -Filter '*.txt' -File -ErrorAction SilentlyContinue) {
        $idAll += [System.IO.File]::ReadAllText($f.FullName)
    }
    $usedIdeas = @([regex]::Matches($mt, 'add_ideas\s*=\s*(hof_ma_idea_[A-Za-z0-9_]+)') |
                   ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missIdeas = @()
    foreach ($i in $usedIdeas) {
        if (-not ($idAll -match ('(?m)^\s*' + [regex]::Escape($i) + '\s*=\s*\{'))) { $missIdeas += $i }
    }
    if ($missIdeas.Count -gt 0) { Fail ("通用线引用的 idea 没定义：" + ($missIdeas -join ', ')) }
    else { Pass "国策引用的 $($usedIdeas.Count) 个机构 idea 全部有定义" }

    $dmAll = ''
    foreach ($f in Get-ChildItem (Join-Path $ModRoot 'common\dynamic_modifiers') -Filter '*.txt' -File -ErrorAction SilentlyContinue) {
        $dmAll += [System.IO.File]::ReadAllText($f.FullName)
    }
    $usedDm = @([regex]::Matches($mt, 'add_dynamic_modifier\s*=\s*\{\s*modifier\s*=\s*(hof_ma_dm_[A-Za-z0-9_]+)') |
                ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $missDm = @()
    foreach ($d in $usedDm) {
        if (-not ($dmAll -match ('(?m)^\s*' + [regex]::Escape($d) + '\s*=\s*\{'))) { $missDm += $d }
    }
    if ($missDm.Count -gt 0) { Fail ("通用线引用的动态民族精神没定义：" + ($missDm -join ', ')) }
    else { Pass "头节点挂载的 $($usedDm.Count) 个动态民族精神全部有定义" }

    # 13e 每个 add_to_variable 的变量名，必须在【对应容器】里被读出来
    #     （写错容器 = 国策点了没反应，且不报错）
    $vPairs = @([regex]::Matches($mt, 'add_to_variable\s*=\s*\{\s*\r?\n\s*(hof_ma_(eco|pol|mil)_[A-Za-z0-9_]+)\s*=') )
    $missVar = @()
    foreach ($vp in $vPairs) {
        $vn = $vp.Groups[1].Value
        if (-not ($dmAll -match ('(?m)^\s*[A-Za-z0-9_]+\s*=\s*' + [regex]::Escape($vn) + '\s*$'))) { $missVar += $vn }
    }
    if ($vPairs.Count -eq 0) { Fail "通用线没有任何 add_to_variable —— 累积数值没接上" }
    elseif ($missVar.Count -gt 0) {
        $u = @($missVar | Sort-Object -Unique)
        Fail ("$($u.Count) 个变量没有出现在任何容器里：{0}" -f ($u -join ', '))
    } else {
        Pass "$($vPairs.Count) 条 add_to_variable 的变量全部被容器读入"
    }

    # 13e-2 经互会资格与新成员追赶：59 个奖励都要记录进度、校验资格、触发补发。
    $maEffPath = Join-Path $ModRoot 'common\scripted_effects\hof_ma_membership_effects.txt'
    $maActPath = Join-Path $ModRoot 'common\on_actions\hof_ma_membership_on_actions.txt'
    $maTrgPath = Join-Path $ModRoot 'common\scripted_triggers\hof_ma_scripted_triggers.txt'
    $maEff = ''
    if (-not ((Test-Path $maEffPath) -and (Test-Path $maActPath) -and (Test-Path $maTrgPath))) {
        Fail '经互会资格/补发的 effect、on_action 或 trigger 文件缺失'
    } else {
        $maEff = [System.IO.File]::ReadAllText($maEffPath)
        $maAct = [System.IO.File]::ReadAllText($maActPath)
        $maTrg = [System.IO.File]::ReadAllText($maTrgPath)
        $progress = ([regex]::Matches($mt, 'set_country_flag\s*=\s*hof_ma_done_hof_ma_')).Count
        $reconciles = ([regex]::Matches($mt, 'hof_ma_reconcile_all\s*=\s*yes')).Count
        $guarded = ([regex]::Matches($mt, 'limit\s*=\s*\{\s*hof_ma_eligible\s*=\s*yes\s*\}')).Count
        if ($progress -eq 59 -and $reconciles -eq 59 -and $guarded -ge 59 -and
            $maTrg.Contains('hof_ma_eligible = {') -and
            $maEff.Contains('hof_ma_reconcile_member = {') -and
            $maEff.Contains('hof_ma_clear_member = {') -and
            $maAct.Contains('on_weekly = {')) {
            Pass '59 个经互会国策逐项记录进度、校验资格、补发精神，周钩子覆盖新附庸'
        } else { Fail "经互会资格/补发链不完整（进度 $progress、补发 $reconciles、资格 $guarded）" }
    }

    # 13e-3 四项首都资源是资格例外；完成时给全部已挂载树逐国发一次。
    $resourceTreeIds = @($apJson.points | Where-Object { $_.s5 -ne $false } | ForEach-Object { $_.treeId } | Sort-Object -Unique)
    foreach ($resourceNode in @(
        @{ Id = 'hof_ma_eco_ibec'; Count = 7 },
        @{ Id = 'hof_ma_eco_intermetall'; Count = 7 },
        @{ Id = 'hof_ma_eco_druzhba'; Count = 1 },
        @{ Id = 'hof_ma_eco_power_grid'; Count = 1 }
    )) {
        $resourceBlock = [regex]::Match($mt, '(?s)joint_focus\s*=\s*\{\s*id\s*=\s*' + [regex]::Escape($resourceNode.Id) + '\s+.*?(?=\r?\njoint_focus\s*=\s*\{|\z)')
        $distributor = [regex]::Match($maEff, '(?ms)^hof_ma_distribute_resource_' + [regex]::Escape($resourceNode.Id) + '\s*=\s*\{.*?(?=^hof_ma_distribute_resource_|\z)')
        $resourceFlag = 'hof_ma_resource_done_' + $resourceNode.Id
        if ($resourceBlock.Success -and
            ([regex]::Matches($resourceBlock.Value, 'add_resource\s*=\s*\{')).Count -eq $resourceNode.Count -and
            [regex]::IsMatch($resourceBlock.Value, '\t\t\}\r?\n\t\tif\s*=\s*\{\r?\n\t\t\tlimit\s*=\s*\{\s*NOT\s*=\s*\{\s*has_country_flag\s*=\s*' + [regex]::Escape($resourceFlag)) -and
            $resourceBlock.Value.Contains("hof_ma_distribute_resource_$($resourceNode.Id) = yes") -and
            $distributor.Success -and
            ([regex]::Matches($distributor.Value, 'has_focus_tree\s*=')).Count -eq $resourceTreeIds.Count -and
            @($resourceTreeIds | Where-Object { $distributor.Value -notmatch ('has_focus_tree\s*=\s*' + [regex]::Escape($_) + '(?![A-Za-z0-9_])') }).Count -eq 0 -and
            ([regex]::Matches($distributor.Value, 'add_resource\s*=\s*\{')).Count -eq $resourceNode.Count -and
            $distributor.Value.Contains('NOT = { has_country_flag = ' + $resourceFlag + ' }') -and
            $distributor.Value.Contains('set_country_flag = ' + $resourceFlag)) {
            Pass "$($resourceNode.Id)：首都资源逐个挂载国家只发一次，资格不参与判断"
        } else { Fail "$($resourceNode.Id)：首都资源跨国分发或去重链不完整" }
    }
    $iibBlock = [regex]::Match($mt, '(?s)joint_focus\s*=\s*\{\s*id\s*=\s*hof_ma_eco_iib\s+.*?(?=\r?\njoint_focus\s*=\s*\{|\z)')
    if ($iibBlock.Success -and $iibBlock.Value.Contains("`t`t`tcapital_scope = { add_building_construction")) {
        Pass '经互会投资银行的首都工厂仍受资格判断约束'
    } else { Fail '经互会投资银行的首都工厂意外移出资格判断' }

    # 13f 引用的 sprite 必须能解析到定义 —— 原版【或】本 mod 自己注册的
    #     2026-09-20 起：三条线那三张仍用【原版已有】的图（用户口径「经互会和华约的不用，
    #     游戏内不是已经有了」），但【游戏里没有的个别节点】用本 mod 自己注册的图
    #     （如 hof_ma_pol_ius -> GFX_hof_ma_ius）。注册见 build/gen-hof-ma-icons.ps1，
    #     逐条检查在 §14。
    $vanillaRoot = $GameRoot
    if (Test-Path $vanillaRoot) {
        $gfxAll = ''
        foreach ($f in Get-ChildItem (Join-Path $vanillaRoot 'interface') -Filter '*.gfx' -File -ErrorAction SilentlyContinue) {
            $gfxAll += [System.IO.File]::ReadAllText($f.FullName)
        }
        $maGfx = Join-Path $ModRoot 'interface\hof_ma_icons.gfx'
        $gfxOwn = if (Test-Path $maGfx) { [System.IO.File]::ReadAllText($maGfx) } else { '' }
        $usedSpr = @([regex]::Matches($mt, '(?m)^\s*icon\s*=\s*(GFX_[A-Za-z0-9_]+)\s*$') |
                     ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
        $missSpr = @()
        $ownCount = 0
        foreach ($s in $usedSpr) {
            if ($gfxAll -match ('name\s*=\s*"' + [regex]::Escape($s) + '"')) { continue }
            if ($gfxOwn -match ('name\s*=\s*"' + [regex]::Escape($s) + '"')) { $ownCount++; continue }
            $missSpr += $s
        }
        if ($missSpr.Count -gt 0) { Fail ("通用线用的 sprite 找不到定义：" + ($missSpr -join ', ')) }
        else { Pass "通用线用的 $($usedSpr.Count) 个 sprite 全部有定义（原版 $($usedSpr.Count - $ownCount) 张 + 本 mod $ownCount 张，零缺图）" }
    } else {
        Write-Output "  [SKIP] 跳过原版 sprite 检查（找不到 $vanillaRoot）"
    }

    # 13g 三条线互不串线（用户口径 ⑦）
    #     结构 = 头 → 三条线的大门 → 每条大门下面【按分类分的若干条支线】
    #     ⇒ 每个节点的 prerequisite 只能是：① 头 ② 本线大门 ③ 同一条线上的另一个节点
    #     ⛔ 跨线 prerequisite = 三条线串起来了（这正是要防的）
    $pairs = @([regex]::Matches($mt, '(?ms)^\s*id\s*=\s*(hof_ma_[A-Za-z0-9_]+).*?^\s*prerequisite\s*=\s*\{\s*focus\s*=\s*(hof_ma_[A-Za-z0-9_]+)\s*\}') |
               ForEach-Object { , @($_.Groups[1].Value, $_.Groups[2].Value) })
    $lineOf = @{}
    foreach ($fid in $mids) {
        $lnk = 'head'
        foreach ($pre in @('eco', 'pol', 'mil')) { if ($fid -like "hof_ma_${pre}_*") { $lnk = $pre } }
        $lineOf[$fid] = $lnk
    }
    $crossLine = @()
    foreach ($pr in $pairs) {
        $a = $pr[0]; $b = $pr[1]
        if ($b -eq $maHeadIds[0]) { continue }          # 挂在头上 —— 合法（三条线的大门）
        if ($lineOf[$a] -ne $lineOf[$b]) { $crossLine += "$a -> $b" }
    }
    if ($crossLine.Count -gt 0) { Fail ("存在跨线的 prerequisite（三条线串起来了）：" + ($crossLine -join ', ')) }
    else { Pass "$($pairs.Count) 条 prerequisite 全部落在同一条线内（三条线互不串线）" }

    # 13g ⭐ 描述文本不许自引本项目的设计文档（2026-09-20 立）
#     硬性规则 9：描述必须出自史实 / 一手件，每条都要注明【真实出处】。
#     `—— 记于 docs/un-focus/01 §4.2 #3` 这种写法等于没有出处（读者无从核对），必须为 0。
$locMaG = Join-Path $PSScriptRoot '..\mod\heart_of_iron\localisation\simp_chinese\hof_ma_l_simp_chinese.yml'
$selfCite = @(Select-String -Path $locMaG -Pattern '_desc:.*docs/un-focus')
if ($selfCite.Count -gt 0) { Fail ("有 $($selfCite.Count) 条描述在自引设计文档（应为 0）：" + (($selfCite | ForEach-Object { $_.Line.Trim().Split(':')[0] }) -join ', ')) }
else { Pass "全部 59 条描述都有真实出处，零自引设计文档" }
#     顺手统计出处分布，防止「全是同一条」也算过
$srcKinds = @()
foreach ($k in @('中文维基','俄文维基','本项目据英文转译','本项目据俄文转译','【en】')) {
    $n = @(Select-String -Path $locMaG -Pattern ('_desc:.*' + [regex]::Escape($k))).Count
    if ($n -gt 0) { $srcKinds += "$k $n" }
}
Pass ("描述出处分布：" + ($srcKinds -join ' · '))

# 13h ⭐ 摆位自检（2026-09-20 起，改过四轮）
    #   ① 「拉的鬼都不认识了」= 固定列值 + 锚上一节点 → 每级累加漂移
    #   ② 「这些不是线性关系吧」= 三条长链，不是树
    #   ③ 「天哪超级无敌重叠啊」= 「头挂 offset、子节点靠 relative_position_id 跟」
    #      —— **本项目实测不成立**：根级 joint_focus 是各自独立的根级块，
    #      头被 offset 拉走之后子节点留在原处 ⇒ 正好压在某国自己国策上。
    #      ⚠️ 反证：原版 nordic_shared / R56 baltic_shared·china_shared·r56_india_shared
    #         【都是这么写的】且能跑 —— 所以不是「语法错」，是【本项目的组合】踩中边界。
    #      ✅ 定案 = 照【本项目自己的 S4 中苏联合带子】（hof_sino_joint.txt）：
    #      每个节点写【绝对格位】+【自带 21 条 offset】。S4 已实装且渲染正确。
    # ① 保险基准（不套 offset）：x ∈ [-21, +21]、y ∈ [27, 33]（苏联终局最深 y=25）
    $posBad = @()
    $cell  = @{}
    $blocks = [regex]::Matches($mt, '(?ms)^(?:shared_focus|joint_focus)\s*=\s*\{.*?^\}')
    $bx0 = 999; $bx1 = -999; $by0 = 999; $by1 = -999
    $nOffBad = @()
    foreach ($mb in $blocks) {
        $body = $mb.Value
        $bid  = [regex]::Match($body, '(?m)^\s*id\s*=\s*(hof_ma_\S+)').Groups[1].Value
        if (-not $bid) { continue }
        $mvx = [regex]::Match($body, '(?m)^\s*x\s*=\s*(-?\d+)\s*$')
        $mvy = [regex]::Match($body, '(?m)^\s*y\s*=\s*(-?\d+)\s*$')
        if ((-not $mvx.Success) -or (-not $mvy.Success)) { $posBad += $bid; continue }
        $vx = [int]$mvx.Groups[1].Value; $vy = [int]$mvy.Groups[1].Value
        if ($vx -lt $bx0) { $bx0 = $vx }; if ($vx -gt $bx1) { $bx1 = $vx }
        if ($vy -lt $by0) { $by0 = $vy }; if ($vy -gt $by1) { $by1 = $vy }
        $k = "$vx,$vy"
        if ($cell.ContainsKey($k)) { $cell[$k] = $cell[$k] + 1 } else { $cell[$k] = 1 }
        # 图瓦树独深：每块须有且只有一条图瓦专属 offset，其他国家保持固定坐标。
        $no = ([regex]::Matches($body, '(?m)^\s*offset\s*=\s*\{')).Count
        if ($no -ne 1 -or $body -notmatch 'offset\s*=\s*\{\s*x\s*=\s*0\s+y\s*=\s*60\s+trigger\s*=\s*\{\s*tag\s*=\s*TAN\s*\}\s*\}') { $nOffBad += "$bid($no)" }
    }
    $dupCell = @($cell.Keys | Where-Object { $cell[$_] -gt 1 })
    if ($posBad.Count -gt 0) { Fail ("$($posBad.Count) 个块读不出 x/y：" + ($posBad -join ', ')) }
    elseif ($dupCell.Count -gt 0) { Fail ("$($dupCell.Count) 处两个块落在同一格（叠格）：" + ($dupCell -join ', ')) }
    elseif ($nOffBad.Count -gt 0) { Fail ("$($nOffBad.Count) 个块缺少图瓦专属 y+60 offset：" + ($nOffBad -join ', ')) }
    elseif (($bx0 -lt -21) -or ($bx1 -gt 21) -or ($by0 -lt 27) -or ($by1 -gt 33)) {
        Fail ("摆位包围盒超出设计值 x ∈ [-21, 21] · y ∈ [27, 33]（实测 x $bx0..$bx1 · y $by0..$by1）")
    } else {
        # ⭐ 逐格证明：带子整条落在所有宿主树的【下方】
        #   2026-09-21 起改成【现场实测】，不再写死常数 ——
        #   旧写法是 `$realYMax = 11`（抄自一次性报告），加挂载点（暹罗）或 R56 更新树时
        #   它会【静默过期】—— 这正是 MaxX 表踩过的那个坑（docs/99 §47.14）。
        #   方法：brace-match 取 focus_tree 体内、与 focus_tree 同级的 focus 块，
        #        按 relative_position_id 解出绝对 y，取全宿主树的最大值。
        #   🚩🚩 2026-09-21 实测订正：旧一次性报告 `mutual-tree-bbox-report-v2-celllevel.txt`
        #      **没做 relative_position_id 链式解析** ⇒ 严重【低估】——
        #      它把 soviet_focus 读成 Ymax 7、把全局读成 11；
        #      现场实测是 **23（SOV）**，而那 23 正是【我们自己那 22 条个人线的结局节点】
        #      （`relative_position_id = hof_ic_seat_<人>`、y = 16 + 7）。
        #      ⇒ 旧报告已加【作废警告】；本断言改为现场实测后，R56 或我们自己往 soviet.txt
        #        加节点都会被当场抓住。
        $realYMax = -9999; $realYMaxTree = ''; $tuvaYMax = -9999
        foreach ($pt2 in $ap1) {
            $fp2 = Join-Path $ModRoot ($pt2.srcRelativePath -replace '/', '\')
            if (-not (Test-Path -LiteralPath $fp2)) { continue }
            $ft2 = [regex]::Replace([System.IO.File]::ReadAllText($fp2), '(?m)#[^\r\n]*', '')
            $seg2 = $null
            foreach ($m2 in [regex]::Matches($ft2, 'focus_tree\s*=\s*\{')) {
                $i2 = $ft2.IndexOf('{', $m2.Index); $d2 = 0; $j2 = $i2
                while ($j2 -lt $ft2.Length) {
                    $c2 = $ft2[$j2]
                    if ($c2 -eq '{') { $d2++ } elseif ($c2 -eq '}') { $d2--; if ($d2 -eq 0) { break } }
                    $j2++
                }
                $s2 = $ft2.Substring($i2 + 1, $j2 - $i2 - 1)
                if ($s2 -match ('(?m)^\s*id\s*=\s*' + [regex]::Escape($pt2.treeId) + '\s*$')) { $seg2 = $s2; break }
            }
            if (-not $seg2) { continue }
            $nd2 = @{}
            foreach ($m3 in [regex]::Matches($seg2, '(?m)^\s*focus\s*=\s*\{')) {
                $i3 = $seg2.IndexOf('{', $m3.Index); $d3 = 0; $j3 = $i3
                while ($j3 -lt $seg2.Length) {
                    $c3 = $seg2[$j3]
                    if ($c3 -eq '{') { $d3++ } elseif ($c3 -eq '}') { $d3--; if ($d3 -eq 0) { break } }
                    $j3++
                }
                $blk3 = $seg2.Substring($i3 + 1, $j3 - $i3 - 1)
                $mid3 = [regex]::Match($blk3, '(?m)^\s*id\s*=\s*(\S+)')
                if (-not $mid3.Success) { continue }
                $gx3 = [regex]::Match($blk3, '(?m)^\s*x\s*=\s*(-?\d+)\s*$')
                $gy3 = [regex]::Match($blk3, '(?m)^\s*y\s*=\s*(-?\d+)\s*$')
                $rp3 = [regex]::Match($blk3, '(?m)^\s*relative_position_id\s*=\s*(\S+)')
                $yy = 0; if ($gy3.Success) { $yy = [int]$gy3.Groups[1].Value }
                $rr = ''; if ($rp3.Success) { $rr = $rp3.Groups[1].Value }
                $nd2[$mid3.Groups[1].Value] = @($yy, $rr)
            }
            foreach ($k3 in @($nd2.Keys)) {
                $y3 = 0; $cur = $k3; $guard = 0
                while ($cur -and $nd2.ContainsKey($cur) -and $guard -lt 64) {
                    $y3 += [int]$nd2[$cur][0]
                    $cur = [string]$nd2[$cur][1]
                    $guard++
                }
                if ($pt2.tag -eq 'TAN') {
                    if ($y3 -gt $tuvaYMax) { $tuvaYMax = $y3 }
                } elseif ($y3 -gt $realYMax) { $realYMax = $y3; $realYMaxTree = $pt2.tag }
            }
        }
        if ($realYMax -lt 0) {
            Fail '逐格实测宿主树 Y 最大失败（一个 focus 块都没读到）'
        } elseif ($by0 -le $realYMax) {
            Fail ("带子 y 起点 $by0 没低过逐格实测的 $($ap1.Count) 棵树 Y 最大 $realYMax（$realYMaxTree）")
        } elseif (($by0 + 60) -le $tuvaYMax) {
            Fail ("图瓦带子 y 起点 $($by0 + 60) 没低过图瓦树 Y 最大 $tuvaYMax")
        } else {
            Pass ("摆位正确：59 块占 59 格无叠格 · 普通树 y $by0..$by1 > 最大 $realYMax · 图瓦 y $($by0+60)..$($by1+60) > 最大 $tuvaYMax")
        }
    }
}


# ---------- 14. S5 图标：国策版 + 民族精神版 ----------
Write-Output ''
Write-Output "=== 14. S5 图标（国策版 + 民族精神版）==="

$maGfxRel = 'interface\hof_ma_icons.gfx'
$maGfxAbs = Join-Path $ModRoot $maGfxRel
if (-not (Test-Path $maGfxAbs)) {
    Fail "$maGfxRel 不存在 —— 先跑 build\gen-hof-ma-icons.ps1"
} else {
    $raw = [System.IO.File]::ReadAllBytes($maGfxAbs)
    if ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF) {
        Fail "$maGfxRel 带 BOM（.gfx 不能带 BOM）"
    } else { Pass "$maGfxRel 存在且无 BOM" }

    $gx = [System.IO.File]::ReadAllText($maGfxAbs)

    # 14a 国策图标必须【成对】：每个 GFX_hof_ma_<x> 都要有 GFX_hof_ma_<x>_shine
    #     （民族精神版 GFX_idea_hof_ma_* 不需要 shine —— 见原版 interface/ideas.gfx）
    $focusNames = @([regex]::Matches($gx, 'name = "(GFX_hof_ma_[^"]+)"') | ForEach-Object { $_.Groups[1].Value })
    $base  = @($focusNames | Where-Object { $_ -notlike '*_shine' })
    $shine = @($focusNames | Where-Object { $_ -like '*_shine' })
    $missShine = @($base | Where-Object { $focusNames -notcontains ($_ + '_shine') })
    if ($missShine.Count -eq 0 -and $base.Count -gt 0) {
        Pass "国策图标成对：$($base.Count) 张 + $($shine.Count) 张 _shine"
    } else {
        Fail ("缺 _shine 的国策图标：" + ($missShine -join ', '))
    }

    # 14b 引用的自家贴图必须存在，且尺寸合规（国策 100x88 · 民族精神 60x60）
    $badTex = @(); $badSize = @()
    foreach ($m in [regex]::Matches($gx, 'texturefile = "([^"]+)"')) {
        $rel = $m.Groups[1].Value.Replace('/', '\')
        if ($rel -notlike 'gfx\interface\hof_ma\*') { continue }
        $abs = Join-Path $ModRoot $rel
        if (-not (Test-Path $abs)) { $badTex += $rel; continue }
        $b = [System.IO.File]::ReadAllBytes($abs)
        $w = [BitConverter]::ToUInt32($b, 16); $h = [BitConverter]::ToUInt32($b, 12)
        $want = if ($rel -like '*\focus\*') { @(100, 88) } else { @(60, 60) }
        if ($w -ne $want[0] -or $h -ne $want[1]) { $badSize += "$rel($($w)x$($h))" }
    }
    if ($badTex.Count -eq 0) { Pass "hof_ma 图标贴图全部存在" } else { Fail ("找不到贴图：" + ($badTex -join ', ')) }
    if ($badSize.Count -eq 0) { Pass "贴图尺寸合规（国策 100x88 · 民族精神 60x60）" } else { Fail ("尺寸不合规：" + ($badSize -join ', ')) }

    # 14c hof_ma_joint.txt 里引用的 icon / text_icon 必须能解析到 sprite 定义
    #     定义可能来自：原版 interface\*.gfx · R56 interface\*.gfx · 本 mod interface\*.gfx
    $spr = New-Object System.Collections.Generic.HashSet[string]
    $roots = @()
    if (Test-Path (Join-Path $GameRoot 'interface')) { $roots += (Join-Path $GameRoot 'interface') }
    if (Test-Path 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\interface') {
        $roots += 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\interface'
    }
    $roots += (Join-Path $ModRoot 'interface')
    foreach ($r in $roots) {
        Get-ChildItem $r -File -Filter '*.gfx' -ErrorAction SilentlyContinue | ForEach-Object {
            foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($_.FullName), 'name = "([^"]+)"')) {
                $null = $spr.Add($m.Groups[1].Value)
            }
        }
    }
    Pass "全库 sprite 名 $($spr.Count) 个（原版 + R56 + 本 mod）"

    $jointAbs = Join-Path $ModRoot 'common\national_focus\hof_ma_joint.txt'
    $jt = [System.IO.File]::ReadAllText($jointAbs)
    $used = @([regex]::Matches($jt, '(?m)^\s*icon = (\S+)') | ForEach-Object { $_.Groups[1].Value } |
              Sort-Object -Unique)
    $maOwn = @($base + $shine + @([regex]::Matches($gx, 'name = "(GFX_idea_hof_ma_[^"]+)"') | ForEach-Object { $_.Groups[1].Value }))
    if ($gx -match '(?m)^`t') { Fail 'hof_ma_icons.gfx 含字面量 `t（PowerShell 单引号转义失效，引擎会报 Unexpected token）' }
    else { Pass 'hof_ma_icons.gfx 无字面量 `t' }
    $unres = @($used | Where-Object { ($spr -notcontains $_) -and ($maOwn -notcontains $_) })
    if ($unres.Count -eq 0) { Pass "国策引用的 $($used.Count) 个 icon 全部有 sprite 定义" }
    else { Fail ("这些 icon 没有 sprite：" + ($unres -join ', ')) }

    # 14d idea 的 picture → GFX_idea_<名字> 必须存在
    $ideaAbs = Join-Path $ModRoot 'common\ideas\hof_ma_ideas.txt'
    $it = [System.IO.File]::ReadAllText($ideaAbs)
    $pics = @([regex]::Matches($it, '(?m)^\s*picture = (\S+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $unresPic = @($pics | Where-Object { ($spr -notcontains ('GFX_idea_' + $_)) -and ($maOwn -notcontains ('GFX_idea_' + $_)) })
    if ($unresPic.Count -eq 0) { Pass "民族精神 idea 的 $($pics.Count) 个 picture 全部有 sprite 定义" }
    else { Fail ("这些 picture 没有 sprite：" + ($unresPic -join ', ')) }

    # 14e DM 的 icon 必须存在
    $dmAbs = Join-Path $ModRoot 'common\dynamic_modifiers\hof_ma_dynamic_modifiers.txt'
    $dt = [System.IO.File]::ReadAllText($dmAbs)
    $dmic = @([regex]::Matches($dt, '(?m)^\s*icon = (\S+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $unresDm = @($dmic | Where-Object { ($spr -notcontains $_) -and ($maOwn -notcontains $_) })
    if ($unresDm.Count -eq 0) { Pass "动态民族精神的 $($dmic.Count) 个 icon 全部有 sprite 定义" }
    else { Fail ("这些 DM icon 没有 sprite：" + ($unresDm -join ', ')) }

    # 14f 真图覆盖度如实报数（不判失败）
    #     ⚠️ 2026-09-25 用户口径：「经互会和华约的不是已经有了吗，游戏内自带，
    #        莫洛托夫条约也不用重新画就用那个吧」⇒ 国策里那几张**原版 sprite**
    #        （经互会 / 华约 / 马列思想）已从「占位」**升为「定案用图」**，不是待办。
    #        真正还等美术的 = **政治线逐节点的国策图 + 政治线 idea 的方形图**（见 docs/un-focus/03 v3）。
    $realIdea = @($pics | Where-Object { $_ -like 'hof_ma_*' })
    $realDm   = @($dmic | Where-Object { $_ -like 'GFX_idea_hof_ma_*' })
    $realFoc  = @($used | Where-Object { $_ -like 'GFX_hof_ma_*' })
    Pass ("真图进度（按 sprite 计）：国策 $($realFoc.Count)/$($used.Count) · idea $($realIdea.Count)/$($pics.Count) · 动态民族精神 $($realDm.Count)/$($dmic.Count) —— ⭐ 国策那 $($used.Count - $realFoc.Count) 张是【游戏自带 · 已定案】（用户 2026-09-25 口径），不是待办")
}


# ---------- 15. 苏联「开战倒计时」决议（2026-09-23 实装） ----------
#   设计出处：docs/96-soviet-war-countdown-decision.md（查证）
#             docs/97-soviet-war-countdown-design.md（设计）
#   ⚠️ 这一节专门抓【静默失效】：决议这类数据错一个字，游戏里只会"什么都不发生"，
#      error.log 也不一定报 —— 所以关键字段、编制营数、挂载 id、本地化键全部逐条断言。
Write-Output ''
Write-Output "=== 15. 苏联「开战倒计时」决议 ==="

$mobCatRel  = 'common\decisions\categories\hof_sov_mob_categories.txt'
$mobDecRel  = 'common\decisions\hof_sov_mob_decisions.txt'
$mobOnARel  = 'common\on_actions\hof_sov_mob_on_actions.txt'
$mobLocRel  = 'localisation\simp_chinese\hof_sov_mob_l_simp_chinese.yml'
$mobCatAbs  = Join-Path $ModRoot $mobCatRel
$mobDecAbs  = Join-Path $ModRoot $mobDecRel
$mobOnAAbs  = Join-Path $ModRoot $mobOnARel
$mobLocAbs  = Join-Path $ModRoot $mobLocRel

$mobMissing = @(@($mobCatRel, $mobDecRel, $mobOnARel, $mobLocRel) | Where-Object {
    -not (Test-Path (Join-Path $ModRoot $_)) })
if ($mobMissing.Count -gt 0) {
    Fail ("缺文件：" + ($mobMissing -join ', '))
} else {

    # 15a 编码红线（AGENTS.md 硬性规则 3）
    #   .txt → UTF-8 无 BOM ；.yml → UTF-8 带 BOM + 文件名含 _l_simp_chinese + 首行 l_simp_chinese:
    $mobBomBad = @()
    foreach ($rel in @($mobCatRel, $mobDecRel, $mobOnARel)) {
        $b = [System.IO.File]::ReadAllBytes((Join-Path $ModRoot $rel))
        if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { $mobBomBad += $rel }
    }
    if ($mobBomBad.Count -eq 0) { Pass '3 个脚本文件均无 BOM（.txt 正确）' }
    else { Fail ("这些脚本文件带了 BOM（引擎会解析失败）：" + ($mobBomBad -join ', ')) }

    $mobLocBytes = [System.IO.File]::ReadAllBytes($mobLocAbs)
    if (-not ($mobLocBytes.Length -ge 3 -and $mobLocBytes[0] -eq 0xEF -and $mobLocBytes[1] -eq 0xBB -and $mobLocBytes[2] -eq 0xBF)) {
        Fail "$mobLocRel 缺 BOM（中文会乱码）"
    } else { Pass "$mobLocRel 带 BOM" }

    if ($mobLocRel -notmatch '_l_simp_chinese\.yml$') { Fail "$mobLocRel 文件名缺 _l_simp_chinese 后缀" }
    else { Pass '本地化文件名含 _l_simp_chinese' }

    $mobLocText = [System.IO.File]::ReadAllText($mobLocAbs)
    $mobFirstLine = ([regex]::Match($mobLocText, '(?m)^\s*([^\r\n]+)')).Groups[1].Value.Trim()
    if ($mobFirstLine -ne 'l_simp_chinese:') { Fail "本地化首行不是 l_simp_chinese:（实为 $mobFirstLine）" }
    else { Pass '本地化首行 = l_simp_chinese:' }

    # 15b 分类块存在 + 决议挂在【同名顶层块】下
    #     ⚠️ 决议与分类不靠字段关联 —— 实测原版 decisions/*.txt 里 `decision_category = ` 0 次，
    #        关联完全靠顶层块名相同（例：原版 AFG.txt 的 AFG_radical_students_category）
    $mobCatText = [System.IO.File]::ReadAllText($mobCatAbs)
    $mobDecText = [System.IO.File]::ReadAllText($mobDecAbs)
    $mobOnAText = [System.IO.File]::ReadAllText($mobOnAAbs)
    if ($mobCatText -notmatch '(?m)^hof_sov_mob_category\s*=\s*\{') {
        Fail 'categories 文件里没有 hof_sov_mob_category 顶层块'
    } elseif ($mobDecText -notmatch '(?m)^hof_sov_mob_category\s*=\s*\{') {
        Fail 'decisions 文件里没有 hof_sov_mob_category 顶层块 —— 决议不会出现在决议面板'
    } elseif ($mobDecText -notmatch '(?m)^\s*hof_sov_mob_war_countdown\s*=\s*\{') {
        Fail 'decisions 文件里没有 hof_sov_mob_war_countdown 决议块'
    } else { Pass '分类块 + 决议块同名挂载正确' }

    # 15c ⭐ 关键字段逐条断言（错一个就静默失效）
    $mobFieldBad = @()
    if ($mobDecText -notmatch '(?m)^\s*target_array\s*=\s*enemies\s*$') { $mobFieldBad += 'target_array=enemies' }
    if ($mobDecText -notmatch '(?m)^\s*target_root_trigger\s*=\s*\{') { $mobFieldBad += 'target_root_trigger' }
    if ($mobDecText -notmatch '(?m)^\s*target_trigger\s*=\s*\{') { $mobFieldBad += 'target_trigger' }
    # 乙案 = 任务 + available 恒假 ⇒ 玩家点不了、只有 timeout_effect 会跑
    if ($mobDecText -notmatch '(?m)^\s*days_mission_timeout\s*=\s*29\s*$') { $mobFieldBad += 'days_mission_timeout=29' }
    if ($mobDecText -notmatch '(?m)^\s*available\s*=\s*\{\s*always\s*=\s*no\s*\}') { $mobFieldBad += 'available={always=no}' }
    # ⛔ `cancel_trigger` 【不再】列入关键字段 —— 2026-09-25 实测它会与 activation 同时为真，
    #    把卡牌撤成「1 天一闪」，已整个删除（失败条件改用 target_trigger + timeout 守卫），
    #    并由下面的 15h-1 反向断言守着。
    if ($mobDecText -notmatch '(?m)^\s*timeout_effect\s*=\s*\{') { $mobFieldBad += 'timeout_effect' }
    if ($mobFieldBad.Count -eq 0) { Pass '决议关键字段齐全（targeted / 任务 / available 恒假 / timeout_effect）' }
    else { Fail ("决议缺关键字段：" + ($mobFieldBad -join ', ')) }

    # ⚠️ 负向断言必须【先剥注释】—— 否则文件头解释"为什么不能用 X"的那段注释
    #    会把 X 本身当成实际代码，自己把自己判失败（2026-09-23 真踩过一次）。
    $mobDecCode = [regex]::Replace($mobDecText, '(?m)#[^\r\n]*', '')
    $mobOnACode = [regex]::Replace($mobOnAText, '(?m)#[^\r\n]*', '')

    # ⚠️ `is_in_war_with` 在本版本【不存在】（triggers_documentation.md 0 命中）
    #    ⇒ 一切战争判定必须是 has_war_with
    if ($mobDecCode -match 'is_in_war_with') {
        Fail 'decisions 里出现了 is_in_war_with —— 本版本没有这个触发器，必须改成 has_war_with'
    } else { Pass '战争判定用的是 has_war_with（未误用 is_in_war_with）' }

    # ⚠️ 写 days_remove 会把任务降级回普通决议（玩家可点、可中止）
    if ($mobDecCode -match '(?m)^\s*days_remove\s*=') {
        Fail 'decisions 里同时写了 days_remove —— 会破坏"乙案 = 非可选任务"'
    } else { Pass '没有 days_remove（任务形态未被降级）' }

    # 15d 师编制：20 营 = 中型坦克 12 + 摩托化 8 —— ⭐ 2026-09-25 用户口径【移除炮兵】
    #     ＋ 2 个【支援连】= engineer（工兵连）+ mot_recon（摩托化侦察连）
    #     5×5 是引擎硬上限：defines → MAX_DIVISION_BRIGADE_WIDTH/HEIGHT = 5
    $mobTplName = ''
    $mReg = [regex]::Match($mobDecText, '(?s)division_template\s*=\s*\{')
    if (-not $mReg.Success) {
        Fail 'decisions 里没有 division_template = {'
    } else {
        $ii = $mobDecText.IndexOf('{', $mReg.Index); $dd = 0; $jj = $ii
        while ($jj -lt $mobDecText.Length) {
            $cc = $mobDecText[$jj]
            if ($cc -eq '{') { $dd++ } elseif ($cc -eq '}') { $dd--; if ($dd -eq 0) { break } }
            $jj++
        }
        $tpl = $mobDecText.Substring($ii + 1, $jj - $ii - 1)
        $mobTplName = [regex]::Match($tpl, 'name\s*=\s*"([^"]+)"').Groups[1].Value

        $mr = [regex]::Match($tpl, '(?s)regiments\s*=\s*\{')
        if (-not $mr.Success) {
            Fail 'division_template 里没有 regiments = {'
        } else {
            $i2 = $tpl.IndexOf('{', $mr.Index); $d2 = 0; $j2 = $i2
            while ($j2 -lt $tpl.Length) {
                $c2 = $tpl[$j2]
                if ($c2 -eq '{') { $d2++ } elseif ($c2 -eq '}') { $d2--; if ($d2 -eq 0) { break } }
                $j2++
            }
            $reg = $tpl.Substring($i2 + 1, $j2 - $i2 - 1)
            $cells = @{}; $per = @{}; $oob = @()
            foreach ($mm in [regex]::Matches($reg, '(?m)^\s*(\w+)\s*=\s*\{\s*x\s*=\s*(\d+)\s*y\s*=\s*(\d+)\s*\}')) {
                $u = $mm.Groups[1].Value
                $px = [int]$mm.Groups[2].Value; $py = [int]$mm.Groups[3].Value
                if ($per.ContainsKey($u)) { $per[$u] = $per[$u] + 1 } else { $per[$u] = 1 }
                $ck = "$px,$py"
                if ($cells.ContainsKey($ck)) { $cells[$ck] = $cells[$ck] + 1 } else { $cells[$ck] = 1 }
                if ($px -gt 4 -or $py -gt 4) { $oob += "$u($px,$py)" }
            }
            $dup = @($cells.Keys | Where-Object { $cells[$_] -gt 1 })
            $total = 0; foreach ($v in $per.Values) { $total += $v }
            # ⭐ 2026-09-25 用户口径：炮兵（artillery_brigade）是错的 ⇒ 从编成里【移除】。
            #    所以它【不在】 $exp 里 —— 一旦哪次同步又把炮兵写回去，就会被下面的
            #    「预期外兵种」断言抓到（这是一条隐形的负向断言）。
            $exp = @{ 'medium_armor' = 12; 'motorized' = 8 }
            $badCount = @()
            foreach ($k in $exp.Keys) {
                $got = 0; if ($per.ContainsKey($k)) { $got = $per[$k] }
                if ($got -ne $exp[$k]) { $badCount += "$k $got/$($exp[$k])" }
            }
            if ($total -ne 20) { Fail "师编制营数 = $total（应为 20 —— 移除炮兵后的编成）" }
            elseif ($badCount.Count -gt 0) { Fail ("师编制构成不符：" + ($badCount -join ' · ')) }
            elseif ($dup.Count -gt 0) { Fail ("师编制有叠格：" + ($dup -join ', ')) }
            elseif ($oob.Count -gt 0) { Fail ("师编制超出 5×5 上限：" + ($oob -join ', ')) }
            else { Pass "师编制 20 营（中型坦克 12 · 摩托化 8）· 无叠格·全在 5×5 内" }
            # 非预期兵种 —— ⭐ 其中【已移除的 artillery_brigade 再出现就会被抓到】
            $extra = @($per.Keys | Where-Object { -not $exp.ContainsKey($_) })
            if ($extra.Count -gt 0) { Fail ("师编制出现预期外的兵种（含已移除的炮兵团）：" + ($extra -join ', ')) }
            else { Pass '师编制里没有预期外的兵种（原 artillery_brigade 确认已移除）' }
        }

        # 15d-2 支援连：恰好两个 = engineer（工兵连）+ mot_recon（摩托化侦察连）
        #    ⭐ 2026-09-25 用户口径新增。
        #    ⚠️ 支援连走【另一个网格】：本 mod defines
        #       MAX_DIVISION_SUPPORT_WIDTH = 1 ⇒ x 只能 0；HEIGHT = 7 ⇒ y = 0 / 1 合法。
        #    ⚠️ 原版先例：history/units/AUS_1936.txt 写的就是 engineer { x = 0 y = 0 } + recon { x = 0 y = 1 }
        $ms = [regex]::Match($tpl, '(?s)support\s*=\s*\{')
        if (-not $ms.Success) { Fail 'division_template 里没有 support = {' }
        else {
            $si = $tpl.IndexOf('{', $ms.Index); $sd = 0; $sj = $si
            while ($sj -lt $tpl.Length) {
                $sc = $tpl[$sj]
                if ($sc -eq '{') { $sd++ } elseif ($sc -eq '}') { $sd--; if ($sd -eq 0) { break } }
                $sj++
            }
            $sup = $tpl.Substring($si + 1, $sj - $si - 1)
            $supPer = @{}
            $supCells = @{}
            foreach ($mm in [regex]::Matches($sup, '(?m)^\s*(\w+)\s*=\s*\{\s*x\s*=\s*(\d+)\s*y\s*=\s*(\d+)\s*\}')) {
                $u = $mm.Groups[1].Value
                $qx = [int]$mm.Groups[2].Value; $qy = [int]$mm.Groups[3].Value
                if ($supPer.ContainsKey($u)) { $supPer[$u] = $supPer[$u] + 1 } else { $supPer[$u] = 1 }
                $supCells["$qx,$qy"] = 1
                if ($qx -gt 0 -or $qy -gt 6) { Fail "支援连 $u 超出 1×7 支援栏（$qx,$qy）" }
            }
            $wantSup = @{ 'engineer' = 1; 'mot_recon' = 1 }
            $supBad = @()
            foreach ($k in $wantSup.Keys) {
                $got = 0; if ($supPer.ContainsKey($k)) { $got = $supPer[$k] }
                if ($got -ne $wantSup[$k]) { $supBad += "$k $got/$($wantSup[$k])" }
            }
            $supExtra = @($supPer.Keys | Where-Object { -not $wantSup.ContainsKey($_) })
            if ($supBad.Count -gt 0) { Fail ("支援连不符：" + ($supBad -join ' · ')) }
            elseif ($supExtra.Count -gt 0) { Fail ("多出了预期外的支援连：" + ($supExtra -join ', ')) }
            elseif ($supCells.Count -ne 2) { Fail "支援连应占 2 格，实际 $($supCells.Count) 格" }
            else { Pass '支援连 = engineer（工兵连）+ mot_recon（摩托化侦察连）· 各 1 个·不叠格' }
        }
    }

    # 每条 create_unit 的模板名必须在两套模板里定义。
    $cuNames = @([regex]::Matches($mobDecText, 'division_template = \\"([^\\]+)\\"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    $cuBad = @($cuNames | Where-Object { $_ -notin @('1941摩托化坦克师', '1941机械化坦克师') })
    if ($cuNames.Count -eq 0) { Fail 'create_unit 里读不到 division_template 名字' }
    elseif ($cuBad.Count -gt 0) { Fail ("create_unit 引用的模板名与 division_template.name 不一致：" + ($cuBad -join ', ')) }
    elseif ($cuNames.Count -ne 2) { Fail 'create_unit 未同时引用旧式和机械化两套模板' }
    else { Pass 'create_unit 引用旧式和机械化两套模板，名字一致' }

    $expectedCounts = @(100, 200, 300)
    $actualCounts = @([regex]::Matches($mobDecCode, 'count\s*=\s*(\d+)') | ForEach-Object { [int]$_.Groups[1].Value } | Sort-Object -Unique)
    if (($actualCounts -join ',') -ne ($expectedCounts -join ',')) { Fail ("动员数量阶段不符：" + ($actualCounts -join ',')) }
    else { Pass '动员数量：1941 前 100、1941—1943 年 200、1944 年起 300' }

    # ⭐ 2026-09-25 用户口径：模板名 = 「1941摩托化坦克师」· 师的经验度 = 3.0（Seasoned）
    if ($mobTplName -ne '1941摩托化坦克师') {
        Fail ("模板名 = 「$mobTplName」（用户 2026-09-25 口径 = 「1941摩托化坦克师」）")
    } else { Pass '模板名 = 「1941摩托化坦克师」（用户口径）' }

    # 1941 年起的机械化模板需要填满 5×5 战斗营网格，并有五种指定支援连。
    $mechanizedStart = [regex]::Match($mobDecText, 'division_template\s*=\s*\{\s*name\s*=\s*"1941机械化坦克师"')
    if (-not $mechanizedStart.Success) { Fail '缺少 1941机械化坦克师 模板' }
    else {
        $mi = $mobDecText.IndexOf('{', $mechanizedStart.Index); $md = 0; $mj = $mi
        while ($mj -lt $mobDecText.Length) {
            if ($mobDecText[$mj] -eq '{') { $md++ }
            elseif ($mobDecText[$mj] -eq '}') { $md--; if ($md -eq 0) { break } }
            $mj++
        }
        $mechTpl = $mobDecText.Substring($mi, $mj - $mi + 1)
        $mechReg = [regex]::Matches($mechTpl, '(?m)^\s*(medium_armor|mechanized)\s*=\s*\{\s*x\s*=\s*(\d+)\s*y\s*=\s*(\d+)\s*\}')
        $mechTank = @($mechReg | Where-Object { $_.Groups[1].Value -eq 'medium_armor' })
        $mechInf = @($mechReg | Where-Object { $_.Groups[1].Value -eq 'mechanized' })
        $mechCells = @($mechReg | ForEach-Object { $_.Groups[2].Value + ',' + $_.Groups[3].Value } | Sort-Object -Unique)
        $mechSup = @('engineer', 'signal_company', 'mot_recon', 'logistics_company', 'field_hospital')
        $mechSupBad = @($mechSup | Where-Object { @([regex]::Matches($mechTpl, '(?m)^\s*' + $_ + '\s*=\s*\{\s*x\s*=\s*0\s*y\s*=\s*[0-4]\s*\}')).Count -ne 1 })
        if ($mechTank.Count -ne 15 -or $mechInf.Count -ne 10 -or $mechCells.Count -ne 25 -or $mechSupBad.Count -gt 0) {
            Fail "机械化模板不符：坦克 $($mechTank.Count)/15、机步 $($mechInf.Count)/10、格位 $($mechCells.Count)/25、支援缺 $($mechSupBad -join ',')"
        } else { Pass '机械化模板：15 中坦 + 10 机步 + 指定五支援连；25 格无重叠' }
    }

    # 师的经验度：用户 2026-09-25 先裁「3.0（Seasoned）」、后改为**第 4 级（Veterans）** ⇒ 1
    #   ⚠️ 该字段是 0–1 的系数，不是等级序号
    #      （defines: UNIT_EXP_LEVELS = { 0.1, 0.3, 0.75, 0.9 } ⇒ 5 级；第 4 级 = [0.9, 1.0]）
    #   ⭐ 原版 + R56 的 OOB 里有 90 处同样写 `1` —— 有先例
    #   ⭐ 用【数值比较】而不是字符串比较，`1` 与 `1.0` 都算过
    $expM = @([regex]::Matches($mobDecText, 'start_experience_factor\s*=\s*([0-9.]+)'))
    if ($expM.Count -eq 0) {
        Fail 'create_unit 里没有 start_experience_factor'
    } else {
        $expBad = @($expM | ForEach-Object { $_.Groups[1].Value } | Where-Object { [double]$_ -ne 1.0 })
        if ($expBad.Count -gt 0) {
            Fail ("start_experience_factor = " + ($expBad -join ',') + '（用户口径 = 1，即第 4 级 Veterans / 满经验）')
        } else { Pass "师的经验度 = 1（第 4 级 Veterans / 久经沙场 · 满经验 · 共 $($expM.Count) 处）" }
    }

    # create_unit 必须落在 state 作用域（官方 wiki：放进国家作用域会"什么都不做"）
    if ($mobDecText -notmatch 'capital_scope\s*=\s*\{') { Fail '没有 capital_scope —— create_unit 落在国家作用域会静默无效' }
    else { Pass 'create_unit 落在 state 作用域（capital_scope）' }
    if ($mobDecText -notmatch 'random_owned_controlled_state\s*=\s*\{') { Fail '缺首都失守时的兜底（random_owned_controlled_state）' }
    else { Pass '首都被占时有兜底分支' }

    # 15e on_action：开战当天立刻激活（官方 wiki 点名推荐的路子）
    #     ⚠️⚠️ 必须套 `on_actions = { }` 外壳 —— 2026-09-23 实测：
    #        原版 common/on_actions/ 下 **17 个文件全部套壳、0 个不套**；R56 的 21 个也全部套壳。
    #        ⇒ 顶层直接写 `on_war_relation_added = { }` 会【静默不触发】。
    $onABad = @()
    if ($mobOnACode -notmatch '(?m)^on_actions\s*=\s*\{') { $onABad += 'on_actions 外壳' }
    if ($mobOnACode -notmatch '(?m)^\s*on_war_relation_added\s*=\s*\{') { $onABad += 'on_war_relation_added' }
    if ($mobOnACode -notmatch 'activate_targeted_decision\s*=\s*\{') { $onABad += 'activate_targeted_decision' }
    if ($mobOnACode -notmatch 'decision\s*=\s*hof_sov_mob_war_countdown') { $onABad += 'decision=hof_sov_mob_war_countdown' }
    if ($onABad.Count -eq 0) { Pass 'on_action：on_actions 外壳 + on_war_relation_added + activate_targeted_decision 指向本决议' }
    else { Fail ("on_action 缺项：" + ($onABad -join ', ')) }
    # ⛔ on_war 不能用来做"多国同时开战"（原版注释：不重新触发）
    if ($mobOnACode -match '(?m)^\s*on_war\s*=\s*\{') { Fail '误用了 on_war（多国同时开战时不会重新触发）' }
    else { Pass '没有误用 on_war' }

    # 15f 本地化键齐全（缺了牌子上直接显示 id 原文）
    $mobKeys = @('hof_sov_mob_category', 'hof_sov_mob_category_desc',
                 'hof_sov_mob_war_countdown', 'hof_sov_mob_war_countdown_desc',
                 'hof_sov_mob_result_tt', 'hof_sov_mob_result_1941_tt', 'hof_sov_mob_result_1944_tt',
                 'hof_sov_mob_title_early', 'hof_sov_mob_title_1941', 'hof_sov_mob_title_1944',
                 'hof_sov_mob_desc_early', 'hof_sov_mob_desc_1941', 'hof_sov_mob_desc_1944')
    $mobLocBad = @($mobKeys | Where-Object { $mobLocText -notmatch ('(?m)^\s*' + [regex]::Escape($_) + ':0\s+"') })
    if ($mobLocBad.Count -eq 0) { Pass "本地化 $($mobKeys.Count) 个键齐全" }
    else { Fail ("本地化缺键：" + ($mobLocBad -join ', ')) }
    $mobScriptedLoc = Join-Path $ModRoot 'common\scripted_localisation\hof_sov_mob_scripted_loc.txt'
    if (-not (Test-Path $mobScriptedLoc)) { Fail '缺少按年份变化的动员决议标题／说明 scripted loc' }
    else {
        $mobStageLoc = [System.IO.File]::ReadAllText($mobScriptedLoc)
        if ($mobStageLoc -match 'name\s*=\s*hof_sov_mob_stage_title' -and
            $mobStageLoc -match 'name\s*=\s*hof_sov_mob_stage_desc' -and
            $mobLocText -match '\[hof_sov_mob_stage_title\]' -and
            $mobLocText -match '\[hof_sov_mob_stage_desc\]') {
            Pass '动员决议标题与说明按年份切换'
        } else { Fail '动员决议 scripted loc 未接入标题或说明' }
    }

    # 15g 引用的 sprite 必须能解析（原版 / R56 / 本 mod）
    $mobSpr = New-Object System.Collections.Generic.HashSet[string]
    $mobRoots = @()
    if (Test-Path (Join-Path $GameRoot 'interface')) { $mobRoots += (Join-Path $GameRoot 'interface') }
    if (Test-Path 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\interface') {
        $mobRoots += 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\interface'
    }
    $mobRoots += (Join-Path $ModRoot 'interface')
    foreach ($r in $mobRoots) {
        Get-ChildItem $r -File -Filter '*.gfx' -ErrorAction SilentlyContinue | ForEach-Object {
            foreach ($m in [regex]::Matches([System.IO.File]::ReadAllText($_.FullName), 'name = "([^"]+)"')) {
                $null = $mobSpr.Add($m.Groups[1].Value)
            }
        }
    }
    $mobIcons = @([regex]::Matches($mobCatText, '(?m)^\s*icon = (\S+)') | ForEach-Object { $_.Groups[1].Value }) +
               @([regex]::Matches($mobDecText, '(?m)^\s*icon = (\S+)') | ForEach-Object { $_.Groups[1].Value })
    $mobIconBad = @($mobIcons | Sort-Object -Unique | Where-Object { $mobSpr -notcontains $_ })
    if ($mobIconBad.Count -eq 0) { Pass "引用的 $($mobIcons.Count) 个 icon 全部有 sprite 定义（零缺图风险）" }
    else { Fail ("这些 icon 没有 sprite：" + ($mobIconBad -join ', ')) }

    # 15h ⭐⭐⭐ 2026-09-25 修 bug（**v7 现行版**）：作用域用对了 —— `activation`/`visible`/`cancel_trigger` 是【拥有者作用域】
    #   🚩 用户【七轮】实测，前六轮**全部在错的作用域里打转**：
    #      ① v1 只判「存在 / 交战」⇒ 卡牌反复起落。
    #      ② v2 加 `has_capitulated` + `cancel_trigger` ⇒ 1 天一闪（判据为假 ⇒ 否定恒真）。
    #      ③ v3「还拥有≥1 个州」+ 删 cancel ⇒ 幽灵卡 + 循环 + 发不出兵。
    #      ④ v4「cancel = activation 的否定」+ `any_controlled_state` ⇒ 又 1 天一闪。
    #      ⑤ v5 `cancel = { always = no }` + 一次性闸门 ⇒ 不闪了，但**跑完一轮又回来**（用户实测）。
    #      ⑥ v6 卡面加 `[FROM.GetName]` + 判据换计数式 ⇒ 用户截图上「中止条件：✗ 始终为非」= 确认模型已生效。
    #      ⭐ 用户第七轮给出**决定性线索**：卡面 `[FROM.GetName]` 渲染出的是**拥有者自己的名字**
    #         ⇒ **`FROM` 在那些块里不指向目标**。
    #   ⭐⭐ 查原版同型决议（`INS_start_limited_war_malaya` / `SIA_start_limited_war_malaysia_burma` /
    #      `PER_core_egypt_state`）确认：**`activation` / `visible` / `cancel_trigger` 里写的是【裸条件】**
    #      （讲的是**拥有者自己**的事），**从不写 `FROM = { … }`**；而 `target_trigger` / `remove_effect`
    #      这类**目标作用域**里才写 `FROM = { … }`（`PER_core_egypt_state` 的 `remove_effect = { FROM = { add_core_of = ROOT } }`）。
    #   ✅ v7 = ① `cancel_trigger` 裸条件 OR（原版同形 ⇒ 拥有者没立足之地就撤卡）
    #            ② `visible = { always = yes }`（拥有者作用域）
    #            ③ `selectable_mission = no`（原版 68 处 ⇒ 玩家点不动的正解）
    #   ✅ v8 = `on_daily`（不存在）⇒ 改挂 `on_peace` / `on_annex` / `on_civil_war_end` / `on_weekly`
    #   ✅ v9 = **两层校验**（用户提的）：层 1 拥有者层 = `activation = { is_ai = no  has_war = yes }`；
    #            层 2 目标层 = `target_trigger` / timeout 守卫 / 清扫；`fire_only_once = no` ⇒ 开战期间每月一轮。
    #   ⚠️ 判据用【代码】文本判（先剥注释）。
    $mobDecNC = $mobDecCode
    $mobOnANC = $mobOnACode

    # 15h-1 ⭐⭐ v7：`cancel_trigger` 必须是**裸条件 OR**（照原版 INS/SIA），且**绝不含 FROM**
    if (-not ($mobDecNC -match '(?m)^\s*cancel_trigger\s*=')) {
        Fail '缺少 cancel_trigger'
    } elseif ($mobDecNC -match '(?s)cancel_trigger\s*=\s*\{[^}]*FROM') {
        Fail 'cancel_trigger 里又出现了 FROM —— 实测这正是「1 天一闪 / 幽灵卡」的元凶（原版同型决议里从不这么写）'
    } elseif (-not ($mobDecNC -match '(?s)cancel_trigger\s*=\s*\{\s*OR\s*=\s*\{[\s\S]*?exists\s*=\s*no[\s\S]*?any_owned_state[\s\S]*?num_of_controlled_states')) {
        Fail 'cancel_trigger 形状不对 —— v7 要求裸条件 OR：`OR = { exists = no  NOT = { any_owned_state = { always = yes } }  NOT = { num_of_controlled_states > 0 }  NOT = { has_war = yes } }`'
    } elseif (-not ($mobDecNC -match '(?s)cancel_trigger\s*=\s*\{[\s\S]*?NOT\s*=\s*\{\s*has_war\s*=\s*yes')) {
        Fail 'cancel_trigger 缺第 4 条（v9）：`NOT = { has_war = yes }` —— 与所有人都停战了就当场撤卡'
    } else {
        Pass 'cancel_trigger = 裸条件 OR（不存在 / 丢光州 / 丢光控制 / 与所有人都停战 ⇒ 当场撤卡），且不含 FROM'
    }

    # 15h-1b ⭐⭐⭐ v7/v8/v9：`selectable_mission = no` + **层 1 拥有者条件**（`activation = { is_ai = no  has_war = yes }`）
    #            + `visible = { always = yes }` + **`fire_only_once = no`**（v9 = 用户要的「开战期间每月一轮」）
    #   ⭐ v9（2026-09-25 第八轮）用户口径：「首先苏联是玩家控制，且正在战争中，再开始检测敌方国家是否有州」
    #      ⇒ 这就是【两层校验】：层 1（拥有者层 · 裸条件）写 `is_ai = no` + `has_war = yes`；
    #        层 2（目标层 · `FROM`）写那个敌国的条件。
    #      ⭐ 原版同形先例 = `ETH_time_based_war_escalation_mission`（`common/decisions/ETH.txt`）：
    #         `activation = { has_war = yes  has_global_flag = … }` · `selectable_mission = no` ·
    #         `available = { hidden_trigger = { always = no } }` · **`fire_only_once = no`**（周期型战时倒计时）
    #   ⛔ 前三个块都**不许含 FROM**（拥有者作用域）；⛔ `fire_only_once` 不许写 `yes`（那会变成一次性）
    $smOk   = ($mobDecNC -match '(?m)^\s*selectable_mission\s*=\s*no')
    $actOff = ($mobDecNC -match '(?s)activation\s*=\s*\{[^}]*always\s*=\s*no[^}]*\}')
    $visYes = ($mobDecNC -match '(?s)visible\s*=\s*\{\s*always\s*=\s*yes\s*\}')
    $onceYes = ($mobDecNC -match '(?m)^\s*fire_only_once\s*=\s*yes')
    $badScope = ($mobDecNC -match '(?s)(activation|visible)\s*=\s*\{[^}]*FROM')
    if (-not $smOk) {
        Fail '缺 `selectable_mission = no` —— 原版「点不动」的正解（68 处先例）'
    } elseif (-not $actOff) {
        Fail '`activation` 必须是 `{ always = no }` —— 周期由显式的逐目标事件控制'
    } elseif (-not $visYes) {
        Fail '`visible` 必须是 `{ always = yes }` —— 它是拥有者作用域，塞 FROM 只会恒真/恒假'
    } elseif (-not $onceYes) {
        Fail '`fire_only_once` 必须是 `yes` —— 禁止引擎绕过目标校验自动重挂'
    } elseif ($badScope) {
        Fail '`activation` / `visible` 里出现了 FROM —— 这两个块是【拥有者作用域】，FROM 在此不指向目标'
    } else {
        Pass 'selectable_mission = no · activation = always no · visible = always yes · fire_only_once = yes（只允许显式逐目标激活）'
    }

    # 15h-2 ⛔ `has_capitulated` 必须【不再出现】
    if ($mobDecNC -match 'has_capitulated') {
        Fail '决议里又出现了 has_capitulated'
    } else { Pass '决议里没有 has_capitulated' }

    # 15h-2b 判据在【决策侧】：无 FROM 包着的三处（target_trigger / timeout 守卫 / cancel_trigger）各 3 处
    $ownCnt = ([regex]::Matches($mobDecNC, 'any_owned_state\s*=\s*\{\s*always\s*=\s*yes\s*\}')).Count
    $ctlCnt = ([regex]::Matches($mobDecNC, 'num_of_controlled_states\s*>\s*0')).Count
    $legacy = ([regex]::Matches($mobDecNC, 'any_controlled_state')).Count
    if ($ownCnt -ne 3 -or $ctlCnt -ne 3) {
        Fail "决策侧应各 3 处（target_trigger / timeout 守卫 / cancel_trigger），实际 owned $ownCnt · controlled $ctlCnt"
    } elseif ($legacy -ne 0) {
        Fail "v6 起已改用计数式，`any_controlled_state` 不该再出现（实际 $legacy 处）"
    } else {
        Pass '决策侧判据各 3 处：还拥有（any_owned_state）+ 还控制着（num_of_controlled_states > 0）'
    }

    # 15h-2d target_trigger 必须是【目标作用域】的 FROM 写法（原版 PER 同形）
    if ($mobDecNC -match '(?s)target_trigger\s*=\s*\{\s*FROM\s*=\s*\{[\s\S]*?has_war_with\s*=\s*ROOT') {
        Pass 'target_trigger 用 FROM = { … }（目标作用域 —— 这一处才是对的用法）'
    } else { Fail 'target_trigger 不是 FROM = { … } 形状' }

    # 15h-2e timeout_effect 的守卫 + ⭐⭐ v9：**决策侧不再盖章**（盖章只由清扫做，且只在目标不算数时）
    $gateCnt = ([regex]::Matches($mobDecNC, 'has_country_flag\s*=\s*hof_sov_mob_mustered')).Count
    $setCnt  = ([regex]::Matches($mobDecNC, 'set_country_flag\s*=\s*hof_sov_mob_mustered')).Count
    if (-not ($mobDecNC -match '(?s)hidden_effect\s*=\s*\{[\s\S]*?has_war_with\s*=\s*ROOT[\s\S]*?num_of_controlled_states\s*>\s*0')) {
        Fail 'timeout_effect 的 if 守卫里缺判据 —— 到点可能误发部队'
    } elseif ($gateCnt -ne 2) {
        Fail "闸门条件应在决策侧 2 处（target_trigger + timeout 守卫），实际 $gateCnt 处"
    } elseif ($setCnt -ne 0) {
        Fail "决策侧不应再出现 `set_country_flag = hof_sov_mob_mustered`（实际 $setCnt 处）—— v9 起盖章只由清扫做，否则会变回【一次性】"
    } else {
        Pass 'timeout_effect：守卫带判据 + **决策侧不盖章**（周期不被杀死）'
    }

    # 15h-3 ⭐⭐ v8 on_action：两处强制激活（开战先清章 + 校验）+ **四个真实钩子**上的清扫
    #   🚩 第七轮挂在 `on_daily` 上是错的 —— 本版本（1.19.2）**没有**这个钩子（实测扫原版 + R56
    #      的 `common/on_actions/*.txt` 顶层键）⇒ 清扫根本没跑。v8 改挂：
    #      `on_peace`（停战/白和 ⇒ 马上撤）· `on_annex`（被吞并）· `on_civil_war_end`（内战结束，D08 那种）
    #      · `on_weekly`（兜底）；逻辑抽到 scripted effect `hof_sov_mob_janitor`（写一次，四处调用）。
    $actCnt = ([regex]::Matches($mobOnANC, 'activate_targeted_decision\s*=\s*\{')).Count
    $ownOnA = ([regex]::Matches($mobOnANC, 'any_owned_state\s*=\s*\{\s*always\s*=\s*yes\s*\}')).Count
    $ctlOnA = ([regex]::Matches($mobOnANC, 'num_of_controlled_states\s*>\s*0')).Count
    $gateOnA = ([regex]::Matches($mobOnANC, 'has_country_flag\s*=\s*hof_sov_mob_mustered')).Count
    $clrOnA  = ([regex]::Matches($mobOnANC, 'clr_country_flag\s*=\s*hof_sov_mob_mustered')).Count
    $capOnA = ([regex]::Matches($mobOnANC, 'has_capitulated')).Count
    $dailyOnA = ([regex]::Matches($mobOnANC, '(?m)^\s*on_daily\s*=')).Count
    $hookPeace = ([regex]::Matches($mobOnANC, '(?m)^\s*on_peace\s*=')).Count
    $hookAnnex = ([regex]::Matches($mobOnANC, '(?m)^\s*on_annex\s*=')).Count
    $hookCW    = ([regex]::Matches($mobOnANC, '(?m)^\s*on_civil_war_end\s*=')).Count
    $hookWeek  = ([regex]::Matches($mobOnANC, '(?m)^\s*on_weekly\s*=')).Count
    $callJan   = ([regex]::Matches($mobOnANC, 'hof_sov_mob_janitor\s*=\s*yes')).Count
    $callRearm = ([regex]::Matches($mobOnANC, 'hof_sov_mob_rearm\s*=\s*yes')).Count
    if ($actCnt -ne 2) {
        Fail "on_action 里 activate_targeted_decision 应 2 处，实际 $actCnt 处"
    } elseif ($ownOnA -ne 2 -or $ctlOnA -ne 2) {
        # v8：on_action 侧判据只在开战两处 limit 里（清扫的判据在 scripted effect 里，另测）
        Fail "on_action 侧判据应各 2 处（开战两处 limit），实际 owned $ownOnA · 控制州计数 $ctlOnA"
    } elseif ($gateOnA -ne 2 -or $clrOnA -ne 2) {
        Fail "on_action 应「开战先清章 + 闸门校验」各 2 处，实际 清章 $clrOnA · 闸门 $gateOnA"
    } elseif ($dailyOnA -ne 0) {
        Fail "`on_daily` 出现了 —— 本版本（1.19.2）**不存在**这个钩子（清扫会静默不跑）"
    } elseif ($hookPeace -ne 1 -or $hookAnnex -ne 1 -or $hookCW -ne 1 -or $hookWeek -ne 1) {
        Fail "清扫钩子不完整：on_peace $hookPeace · on_annex $hookAnnex · on_civil_war_end $hookCW · on_weekly $hookWeek（各应为 1）"
    } elseif ($callJan -ne 4) {
        Fail "调用 `hof_sov_mob_janitor = yes` 应 4 处（四个钩子各一次），实际 $callJan 处"
    } elseif ($callRearm -ne 1 -or $mobOnANC -notmatch '(?s)on_weekly\s*=\s*\{[\s\S]*?limit\s*=\s*\{\s*tag\s*=\s*SOV\s*\}[\s\S]*?hof_sov_mob_rearm\s*=\s*yes') {
        Fail '周兜底必须只在苏联作用域调用 hof_sov_mob_rearm 一次'
    } elseif ($capOnA -ne 0) {
        Fail 'on_action 里还有 has_capitulated'
    } else {
        Pass 'on_action = 开战两处（清章 + 校验 + 强制激活）＋ 四个真实钩子（on_peace/on_annex/on_civil_war_end/on_weekly）调用清扫'
    }

    # 15h-3c ⭐⭐⭐ v9：**嵌套结构守卫** —— 光数「钩子出现 1 次」是不够的！
    #   🚩 2026-09-25 真踩（第八轮）：四个钩子都写对了、`on_actions = {` 外壳也在，但外壳在
    #      `on_war_relation_added` 之后就【提前闭合】了 ⇒ 四个钩子落在外壳【外面】⇒ 引擎不认，
    #      那台清扫一次都不会跑（症状与 v7 的 `on_daily` 一模一样），
    #      而旧的断言（只数出现次数）**全绿** —— 只有逐行花括号深度走才抓得到。
    #      ⚠️ 起因：我做过一次「只替换块首」的局部编辑（把 `FROM = { clr_country_flag = … }` 换成了
    #         `if = { limit = { … } FROM = { … } }`），**留下了孤儿行**（原 `limit` 的残余 + 多一个右括号）。
    #   ✅ 三条：① 末值必须 0 ② 任何一行都不许为负 ③ 五个钩子必须正好在 depth 2（外壳 1 + 钩子 1）
    $dep = 0; $depNeg = $false
    $onLines = $mobOnANC -split "`n"
    $depthAt = @{}
    for ($i = 0; $i -lt $onLines.Count; $i++) {
        $dep += ([regex]::Matches($onLines[$i], '\{')).Count
        $dep -= ([regex]::Matches($onLines[$i], '\}')).Count
        $depthAt[$i] = $dep
        if ($dep -lt 0) { $depNeg = $true }
    }
    $hookBad = @()
    foreach ($hk in @('on_war_relation_added', 'on_peace', 'on_annex', 'on_civil_war_end', 'on_weekly')) {
        $hit = $false
        for ($i = 0; $i -lt $onLines.Count; $i++) {
            if ($onLines[$i] -match ('^\s*' + $hk + '\s*=\s*\{')) {
                if ($depthAt[$i] -ne 2) { $hookBad += ("$hk 在 depth $($depthAt[$i])（应为 2）") }
                $hit = $true
            }
        }
        if (-not $hit) { $hookBad += "$hk 未找到" }
    }
    if ($depNeg) {
        Fail 'on_actions 文件的花括号深度出现【负数】—— 有块被多闭合了（结构坏 ⇒ 引擎整块丢弃）'
    } elseif ($dep -ne 0) {
        Fail ("on_actions 文件花括号末值 = $dep（应为 0）—— 少一个左括号或多一个右括号")
    } elseif ($hookBad.Count -gt 0) {
        Fail ('钩子不在 on_actions 外壳【里面】：' + ($hookBad -join ' · '))
    } else {
        Pass 'on_actions 嵌套结构正确：末值 0 · 无负深度 · 五个钩子都在外壳内（depth 2）'
    }

    # 15h-3b ⭐⭐ v8：清扫的**定义**必须在 scripted effect 里，且自带「盖章 + 撤卡」两件事
    $seRel = 'common\scripted_effects\hof_sov_mob_effects.txt'
    $seAbs = Join-Path $ModRoot $seRel
    if (-not (Test-Path -LiteralPath $seAbs)) {
        Fail "$seRel 不存在 —— 清扫效果没地方定义（四个钩子会调不到）"
    } else {
        $seBytes = [System.IO.File]::ReadAllBytes($seAbs)
        if ($seBytes.Length -ge 3 -and $seBytes[0] -eq 0xEF -and $seBytes[1] -eq 0xBB -and $seBytes[2] -eq 0xBF) {
            Fail "$seRel 带了 BOM（脚本 .txt 必须【无】BOM）"
        }
        $seText = [System.IO.File]::ReadAllText($seAbs)
        $seCode = [regex]::Replace($seText, '(?m)#[^\r\n]*', '')
        # 目标排除必须放在 every_country 的 limit 中。若误放进失效条件 OR，
        # NOT = { tag = SOV } 对每个敌国都为真，会每周撤掉全部有效倒计时。
        $seTargetFilterOk = ($seCode -match '(?s)every_country\s*=\s*\{\s*limit\s*=\s*\{\s*NOT\s*=\s*\{\s*tag\s*=\s*SOV\s*\}\s*\}') -and
                            ($seCode -notmatch '(?s)OR\s*=\s*\{\s*NOT\s*=\s*\{\s*tag\s*=\s*SOV')
        $seOk = ($seCode -match '(?ms)hof_sov_mob_janitor\s*=\s*\{') -and
                ($seCode -match 'every_country\s*=\s*\{') -and
                ($seCode -match 'set_country_flag\s*=\s*hof_sov_mob_mustered') -and
                ($seCode -match 'remove_targeted_decision\s*=\s*\{') -and
                ($seCode -match 'num_of_controlled_states\s*>\s*0') -and
                # ⭐ v9：清扫必须【双向】—— 目标重新变回有效时要清章（自愈，周期才能恢复）
                ($seCode -match 'clr_country_flag\s*=\s*hof_sov_mob_mustered') -and
                ($seCode -match '(?m)^\s*else\s*=\s*\{') -and
                ($seCode -match '(?s)hof_sov_mob_rearm\s*=\s*\{[\s\S]*?has_war_with\s*=\s*SOV[\s\S]*?num_of_controlled_states\s*>\s*0[\s\S]*?activate_targeted_decision\s*=\s*\{') -and
                $seTargetFilterOk
        if (-not $seOk) {
            Fail "$seRel 里的 hof_sov_mob_janitor 不完整（需要目标筛选 + 盖章 + 撤卡 + 判据 + else 清章）"
        } else {
            Pass "$seRel：hof_sov_mob_janitor 双向齐全（遍历 + 盖章 + 撤卡 + 判据 / else 清章）· 无 BOM"
        }
    }

    # v11：周期仅由到期后一日的隐藏事件重启；旧存档由周兜底启动。
    $mobEvtAbs = Join-Path $ModRoot 'events\hof_sov_mob_events.txt'
    if (-not (Test-Path -LiteralPath $mobEvtAbs)) {
        Fail '缺少每轮重启事件 events\hof_sov_mob_events.txt'
    } else {
        $mobEvtBytes = [IO.File]::ReadAllBytes($mobEvtAbs)
        $mobEvtCode = [regex]::Replace([IO.File]::ReadAllText($mobEvtAbs), '(?m)#[^\r\n]*', '')
        if (($mobEvtBytes.Length -ge 3 -and $mobEvtBytes[0] -eq 0xEF -and $mobEvtBytes[1] -eq 0xBB -and $mobEvtBytes[2] -eq 0xBF) -or
            $mobEvtCode -notmatch '(?m)^\s*add_namespace\s*=\s*hof_sov_mob\s*$' -or
            $mobEvtCode -notmatch 'id\s*=\s*hof_sov_mob\.1' -or
            $mobEvtCode -notmatch 'has_war_with\s*=\s*SOV' -or
            $mobEvtCode -notmatch 'num_of_controlled_states\s*>\s*0' -or
            $mobEvtCode -notmatch 'activate_targeted_decision\s*=\s*\{') {
            Fail '每轮重启事件缺少目标守卫、激活效果或编码错误'
        } else { Pass '每轮重启事件：目标守卫 + 显式激活 + 无 BOM' }
    }
    if ($mobDecNC -notmatch 'set_country_flag\s*=\s*\{\s*flag\s*=\s*hof_sov_mob_waiting\s+days\s*=\s*2\s*\}' -or
        $mobDecNC -notmatch 'country_event\s*=\s*\{\s*id\s*=\s*hof_sov_mob\.1\s+days\s*=\s*1\s*\}') {
        Fail '倒计时到期后必须设置等待标记并在 1 日后触发逐目标重启事件'
    } else { Pass '倒计时到期：1 日间隔 + 逐目标事件重启' }

    # 15h-4 ⭐⭐ v6/v7：卡面必须显示目标国名（排查用的"仪表"）
    if (-not ($mobLocText -match '\[FROM\.GetName\]')) {
        Fail '本地化里没有 [FROM.GetName] —— 玩家悬停看不到目标国，出问题时无法定位'
    } else {
        $fromNameCnt = ([regex]::Matches($mobLocText, '\[FROM\.GetName\]')).Count
        Pass ("卡面显示目标国名：[FROM.GetName] 共 {0} 处（同原版 targeted 决议的 _desc 写法）" -f $fromNameCnt)
    }
}
# ---------- 16. 全局槽位表 + 政治面板 UI 宽度（dose/94 与 2026-09-24 的 50→60） ----------
# 为什么值得单独断言：槽位数与槽宽是【两个文件、两处数字】，改一处忘另一处，
# 游戏里【不报错】——只是那一格画到面板外面去（看不见 = 静默失效）。
# 唯一权威出处：槽位 = common/idea_tags/00_idea.txt；槽宽 = interface/countrypoliticsview.gui
Write-Output ''
Write-Output "=== 16. 全局槽位表 + 政治面板 UI 宽度 ==="

$tagRel = 'common\idea_tags\00_idea.txt'
$guiRel = 'interface\countrypoliticsview.gui'
$tagAbs = Join-Path $ModRoot $tagRel
$gui2Abs = Join-Path $ModRoot $guiRel

if (-not (Test-Path $tagAbs)) { Fail "缺少 $tagRel（全局槽位表的唯一权威出处）" }
else {
    $tagTxt = [System.IO.File]::ReadAllText($tagAbs)
    $tagCode = [regex]::Replace($tagTxt, '(?m)^\s*#.*$', '')

    # 16a 槽位数：每写一行 = 一个槽（官方 wiki：Character slots are defined within
    #     /Hearts of Iron IV/common/idea_tags/*.txt）
    $slotWant = @{
        'character_slot = political_advisor' = 5
        'slot = industrial_concern'          = 3
        'character_slot = high_command'      = 5
    }
    $slotBad = @()
    foreach ($k in $slotWant.Keys) {
        $n = ([regex]::Matches($tagCode, '(?m)^\s*' + [regex]::Escape($k) + '\s*$')).Count
        if ($n -ne $slotWant[$k]) { $slotBad += "$k 实测 $n / 期望 $($slotWant[$k])" }
    }
    if ($slotBad.Count -eq 0) {
        Pass '槽位数正确：政治顾问 5 · 工业企业 3 · 总司令 5（每行一槽）'
    } else { Fail ("槽位数不符：" + ($slotBad -join ' · ')) }

    # ⚠️ theoryist 用户明说「不用动」＝ 保持 1（docs/94 §1.1）
    $nTheorist = ([regex]::Matches($tagCode, '(?m)^\s*character_slot = theorist\s*$')).Count
    if ($nTheorist -eq 1) { Pass 'theorist 保持 1 个槽（用户口径「不用动」）' }
    else { Fail "theorist 槽数 = $nTheorist（应为 1）" }
}

if (-not (Test-Path $gui2Abs)) { Fail "缺少 $guiRel" }
else {
    $guiRaw = [System.IO.File]::ReadAllBytes($gui2Abs)
    if ($guiRaw.Length -ge 3 -and $guiRaw[0] -eq 0xEF -and $guiRaw[1] -eq 0xBB -and $guiRaw[2] -eq 0xBF) {
        Fail "$guiRel 带了 BOM（.gui 不能带 BOM）"
    } else { Pass "$guiRel 无 BOM" }

    $guiTxt = [System.IO.File]::ReadAllText($gui2Abs)

    # 16b 类别横条那个 grid 必须还是【8 格】（三个类别改后都是 8）
    $gw = [regex]::Match($guiTxt, '(?s)name = "ideas_grid".*?max_slots = \{ x = (\d+) y = (\d+) \}')
    if (-not $gw.Success) {
        Fail 'countrypoliticsview.gui 里读不到 ideas_grid 的 max_slots'
    } else {
        $mx = [int]$gw.Groups[1].Value
        $my = [int]$gw.Groups[2].Value
        if ($mx -eq 8 -and $my -eq 1) { Pass "ideas_grid max_slots = 8 × 1（与槽位数一致）" }
        else { Fail "ideas_grid max_slots = $mx × $my（期望 8 × 1）" }

        # 16c 槽宽：2026-09-24 用户口径「50 改成 60」
        $sw = [regex]::Match($gw.Value, 'slotsize = \{ width = (\d+) height = (\d+) \}')
        if (-not $sw.Success) {
            Fail 'ideas_grid 里读不到 slotsize'
        } else {
            $w = [int]$sw.Groups[1].Value
            $h = [int]$sw.Groups[2].Value
            if ($w -eq 60) { Pass "ideas_grid slotsize width = 60（用户 2026-09-24 口径）" }
            else { Fail "ideas_grid slotsize width = $w（应为 60）" }

            # 16d 算术：窗口宽 550 · grid 左起 x = 17 ⇒ 可用宽 533
            $avail = 550 - 17
            if (($mx * $w) -le $avail) {
                Pass "宽度算术通过：$mx × $w = $($mx * $w) ≤ 可用宽 $avail（余 $($avail - $mx * $w) px）"
            } else {
                Fail "$mx × $w = $($mx * $w) 超过可用宽 $avail —— 最右那格会画到面板外"
            }
            Pass "槽高 $h（槽高 64 · grid 起点 y = 46 ⇒ 第二行会压到下一条横条，故 max_slots.y 必须为 1）"
        }
    }
}

# ---------- 17. 2026-09-24 的 12 处国策效果改造（宣称→核心 / 追加核心） ----------
# 为什么值得单独断言：这些改动【不在本 mod 自己的文件里】——它们由
# build/sync-from-r56.ps1 的 $FocusPatchMap / $ValuePatchMap 每次从 R56 重生成时
# 打进去。一旦哪次同步漏打（例如表被清空、国策 id 改名），游戏里【不报错】，
# 只是那一格没核心 —— 属于「静默失效」。
# 同时在【源脚本】里断言：表本身不能被清空（这是最容易发生的事故）。
Write-Output ''
Write-Output "=== 17. 国策效果改造（宣称→核心／追加核心，12 处）==="

$syncAbs = Join-Path (Split-Path -Parent $PSScriptRoot) 'build\sync-from-r56.ps1'
$sovAbs = Join-Path $ModRoot 'common\national_focus\soviet.txt'
$astAbs = Join-Path $ModRoot 'common\national_focus\australia_taog.txt'
$prcAbs = Join-Path $ModRoot 'common\national_focus\china_communist_sea.txt'
$honAbs = Join-Path $ModRoot 'common\national_focus\honduras.txt'

# 17a 源脚本：两张补丁表必须还在
if (-not (Test-Path $syncAbs)) { Fail '找不到 build\sync-from-r56.ps1' }
else {
    $syncTxt = [System.IO.File]::ReadAllText($syncAbs)
    if ($syncTxt.Contains("'sov_core' = @{") -and $syncTxt.Contains("'ast_std' = @{") -and $syncTxt.Contains("'prc_sino' = @{") -and $syncTxt.Contains("'hon_std' = @{")) {
        Pass 'sync-from-r56.ps1 的 $FocusPatchMap 已按挂载点分层（sov_core / ast_std / prc_sino / hon_std）'
    } else { Fail 'sync-from-r56.ps1 的 $FocusPatchMap 缺分层键' }
}

if (-not (Test-Path $sovAbs)) { Fail '找不到 mod 的 soviet.txt' }
if (-not (Test-Path $astAbs)) { Fail '找不到 mod 的 australia_taog.txt' }
if (-not (Test-Path $prcAbs)) { Fail '找不到 mod 的 china_communist_sea.txt' }
if (-not (Test-Path $honAbs)) { Fail '找不到 mod 的 honduras.txt' }
if ((Test-Path $sovAbs) -and (Test-Path $astAbs) -and (Test-Path $prcAbs) -and (Test-Path $honAbs)) {
    $sovT = [System.IO.File]::ReadAllText($sovAbs)
    $astT = [System.IO.File]::ReadAllText($astAbs)
    $prcT = [System.IO.File]::ReadAllText($prcAbs)
    $honT = [System.IO.File]::ReadAllText($honAbs)

    # 17b 12 个补丁的哨兵（只在补丁落地时才存在）
    $sent = @(
        @{ F = 'sov'; S = '# hof: 波罗的海全境（含梅梅尔 188）'; N = '宣称波罗的海 → 核心（全境 + 柯尼斯堡）' },
        @{ F = 'sov'; S = '# hof: 波兰 13 州 + 喀尔巴阡鲁塞尼亚 73 / 乌日霍罗德 996'; N = '宣称波兰 → 15 州核心' },
        @{ F = 'sov'; S = '# hof:focus-begin SOV_control_scandinavia'; N = '控制斯堪的纳维亚 → 加北欧三国核心' },
        @{ F = 'sov'; S = '# hof: 海峡与黑海沿岸七州核心'; N = '声索黑海出海口 → 7 州核心' },
        @{ F = 'sov'; S = '# hof: 爱琴群岛、十二群岛、克里特与塞浦路斯核心'; N = '对希腊的最后通牒 → 4 州核心' },
        @{ F = 'sov'; S = '# hof: 西藏 322/758/757/601 保持宣称'; N = '进入高原 → 不丹/尼泊尔核心（西藏不动）' },
        @{ F = 'sov'; S = '# hof:focus-begin SOV_recover_the_kuril_islands'; N = '收复千岛 → 加南萨哈林/千岛/北海道核心' },
        @{ F = 'sov'; S = '# hof:focus-begin SOV_recover_alaska'; N = '收复阿拉斯加 → 加核心' },
        @{ F = 'sov'; S = '# hof:focus-begin SOV_reinforce_eastern_naval_bases'; N = '增建东部海军基地 → 朝鲜半岛核心' },
        @{ F = 'sov'; S = '# hof:focus-begin SOV_the_southern_thrust'; N = '刺向南方 → 伊朗 11 州及阿富汗 2 州核心' },
        @{ F = 'sov'; S = '# hof:focus-begin SOV_interest_in_cuba'; N = '古巴基地 → 百慕大核心' },
        @{ F = 'sov'; S = '# hof: 芬兰全境 13 州核心'; N = '保障列宁格勒安全 → 芬兰全境核心' },
        @{ F = 'prc'; S = '# hof:focus-begin PRC_expel_the_occupiers'; N = '驱逐敌寇 → 日本 7 州核心' },
        @{ F = 'hon'; S = '# hof:focus-begin HON_liberate_mexico_again'; N = '向北进攻 → 墨西哥 15 州核心' },
        @{ F = 'ast'; S = '# hof:focus-begin AST_the_australian_commonwealth'; N = '澳大利亚联邦 → 新西兰全境核心' }
    )
    $miss = @()
    foreach ($s in $sent) {
        $hay = if ($s.F -eq 'sov') { $sovT } elseif ($s.F -eq 'prc') { $prcT } elseif ($s.F -eq 'hon') { $honT } else { $astT }
        if (-not $hay.Contains($s.S)) { $miss += $s.S }
    }
    if ($miss.Count -eq 0) { Pass '15 处补丁哨兵全部落地' }
    else { Fail ("缺少 " + $miss.Count + " 处补丁哨兵：" + ($miss -join ' | ')) }

    # 17c 关键核心行（每个改造至少抽一条）
    $needSov = @(536, 537, 555, 463, 650, 696, 525, 920, 419, 988, 417, 1008, 1011, 341, 797, 342, 354, 73, 996, 164, 182, 183, 10, 88, 324, 323, 1091, 110, 38, 37, 111, 146, 722, 1040, 282, 532, 534, 1106)
    $badCore = @()
    foreach ($id in $needSov) {
        $n = ([regex]::Matches($sovT, '(?m)^\s*add_state_core\s*=\s*' + $id + '\s*$')).Count
        if ($n -lt 1) { $badCore += $id }
    }
    if ($badCore.Count -eq 0) { Pass 'soviet.txt：38 个抽样核心行都在' }
    else { Fail ("缺核心行：" + ($badCore -join ',')) }
    $southernCore = [regex]::Match($sovT, '(?s)# hof:focus-begin SOV_the_southern_thrust(?<body>.*?)# hof:focus-end SOV_the_southern_thrust')
    if ($southernCore.Success -and
        $southernCore.Groups['body'].Value -match '(?m)^\s*add_state_core\s*=\s*1008\s*$' -and
        $southernCore.Groups['body'].Value -match '(?m)^\s*add_state_core\s*=\s*1011\s*$') {
        Pass '刺向南方的奖励块含法里亚布 1008 与巴达赫尚 1011 核心'
    } else {
        Fail '刺向南方奖励块缺法里亚布 1008 或巴达赫尚 1011 核心'
    }
    foreach ($id in @(284, 723, 1087, 1136, 1139, 1140)) {
        $n = ([regex]::Matches($astT, '(?m)^\s*add_state_core\s*=\s*' + $id + '\s*$')).Count
        if ($n -lt 1) { Fail "australia_taog.txt 缺 add_state_core = $id（新西兰）" }
    }
    foreach ($id in @(526, 528, 529, 530, 531, 1105, 1107)) {
        $n = ([regex]::Matches($prcT, '(?m)^\s*add_state_core\s*=\s*' + $id + '\s*$')).Count
        if ($n -lt 1) { Fail "china_communist_sea.txt 缺 add_state_core = $id（日本）" }
    }
    # 洪都拉斯：墨西哥 15 州（除尤卡坦 474 / 恰帕斯 475）
    foreach ($id in @(277, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 929, 930, 931, 932)) {
        $n = ([regex]::Matches($honT, '(?m)^\s*add_state_core\s*=\s*' + $id + '\s*$')).Count
        if ($n -ne 1) { Fail "honduras.txt 的 add_state_core = $id 命中 $n 次（应为 1）（墨西哥）" }
    }
    foreach ($id in @(474, 475)) {
        $n = ([regex]::Matches($honT, '(?m)^\s*add_state_core\s*=\s*' + $id + '\s*$')).Count
        if ($n -ne 0) { Fail "honduras.txt 不应给尤卡坦/恰帕斯（$id）核心 —— 用户明确排除" }
    }
    Pass 'honduras.txt：墨西哥 15 州核心在、尤卡坦 474 / 恰帕斯 475 确实没给'

    # 17d 负向：被「改成核心」的那几条，不许再留 add_state_claim
    $mustGone = @(341, 347, 340, 339, 187, 324, 323, 1091)
    $left = @()
    foreach ($id in $mustGone) {
        $n = ([regex]::Matches($sovT, '(?m)^\s*add_state_claim\s*=\s*' + $id + '\s*$')).Count
        if ($n -ne 0) { $left += "$id($n)" }
    }
    if ($left.Count -eq 0) { Pass '已改为核心的 8 个州不再留 add_state_claim' }
    else { Fail ("残留 add_state_claim：" + ($left -join ' ')) }

    # 17e 西藏必须【仍是宣称】（用户口径：西藏的不动）
    $tibMissing = @()
    foreach ($id in @(322, 758, 757, 601)) {
        $n = ([regex]::Matches($sovT, '(?m)^\s*add_state_claim\s*=\s*' + $id + '\s*$')).Count
        if ($n -lt 1) { $tibMissing += $id }
    }
    if ($tibMissing.Count -eq 0) { Pass '西藏 322/758/757/601 仍为宣称（未动）' }
    else { Fail ("西藏的宣称被误改：" + ($tibMissing -join ',')) }
}

# ---------- 18. 2026-09-25 苏联「整合加盟共和国」决议组（一国一条 · 8 条） ----------
# 为什么值得断言：
#   ① 决议与分类的关联方式是「同名顶层块」（分类文件与决议文件里的顶层块名必须逐字相同），
#      写错一个字母游戏里【不报错】，只是整个页签不出现 —— 属于「静默失效」。
#   ② 用户明确要求「**不是全部一起**」⇒ 每条决议只许挂 **一个** tag；
#      一旦有人图省事把几个 tag 塞回同一个块，本节的 tag 计数断言就会红。
#   ③ 天数（15 / 30）、特质过滤（只许出现在指定那几条里）串了也没人会发现。
#   ④ 本地化显示名必须避开原版 / R56 已占用的那四个「整合XX」（判据 K）。
Write-Output ''
Write-Output "=== 18. 苏联「整合加盟共和国」决议组（一国一条 · 8 条）==="

$intCatAbs = Join-Path $ModRoot 'common\decisions\categories\hof_sov_integrate_categories.txt'
$intDecAbs = Join-Path $ModRoot 'common\decisions\hof_sov_integrate_decisions.txt'
$intLocAbs = Join-Path $ModRoot 'localisation\simp_chinese\hof_sov_integrate_l_simp_chinese.yml'

# 期望表 —— 改决议时必须同步改这里（改错了本节会红，正是它的作用）
$intWant = @(
    @{ Id = 'estonia';   Tag = 'EST'; Days = 15; Trait = 'BALTIC_anti_bolshevik';     Name = '整合爱沙尼亚加盟共和国' },
    @{ Id = 'latvia';    Tag = 'LAT'; Days = 15; Trait = 'BALTIC_anti_bolshevik';     Name = '整合拉脱维亚加盟共和国' },
    @{ Id = 'lithuania'; Tag = 'LIT'; Days = 15; Trait = 'BALTIC_anti_bolshevik';     Name = '整合立陶宛加盟共和国' },
    @{ Id = 'norway';    Tag = 'NOR'; Days = 30; Trait = $null;                       Name = '整合挪威加盟共和国' },
    @{ Id = 'sweden';    Tag = 'SWE'; Days = 30; Trait = $null;                       Name = '整合瑞典加盟共和国' },
    @{ Id = 'finland';   Tag = 'FIN'; Days = 30; Trait = $null;                       Name = '整合芬兰加盟共和国' },
    @{ Id = 'turkey';    Tag = 'TUR'; Days = 30; Trait = $null;                       Name = '整合土耳其加盟共和国' },
    @{ Id = 'poland';    Tag = 'POL'; Days = 15; Trait = 'POL_sanation_right_leader'; Name = '整合波兰加盟共和国' }
)

$intMissing = @()
foreach ($f in @($intCatAbs, $intDecAbs, $intLocAbs)) { if (-not (Test-Path $f)) { $intMissing += (Split-Path $f -Leaf) } }
if ($intMissing.Count -gt 0) { Fail ("缺少文件：" + ($intMissing -join ', ')) }
else {
    Pass '三个文件都在（分类 / 决议 / 本地化）'

    # 18a 编码红线：脚本 .txt 无 BOM；本地化 .yml 有 BOM + 首行语言头
    $badBom = @()
    foreach ($f in @($intCatAbs, $intDecAbs)) {
        if (((Get-Content -LiteralPath $f -Encoding Byte -TotalCount 3) -join ',') -eq '239,187,191') { $badBom += (Split-Path $f -Leaf) }
    }
    if ($badBom.Count -gt 0) { Fail ("以下脚本文件不应带 BOM：" + ($badBom -join ', ')) }
    else { Pass '两个脚本 .txt 都是 UTF-8 无 BOM' }

    $lt = [System.IO.File]::ReadAllText($intLocAbs)
    if (((Get-Content -LiteralPath $intLocAbs -Encoding Byte -TotalCount 3) -join ',') -ne '239,187,191') { Fail 'hof_sov_integrate_l_simp_chinese.yml 缺 BOM' }
    elseif (-not $lt.StartsWith('l_simp_chinese:')) { Fail 'hof_sov_integrate_l_simp_chinese.yml 首行必须是 l_simp_chinese:' }
    else { Pass 'hof_sov_integrate_l_simp_chinese.yml：有 BOM + 首行语言头正确' }

    $ct = [System.IO.File]::ReadAllText($intCatAbs)
    $dt = [System.IO.File]::ReadAllText($intDecAbs)

    # ⚠️ 本节所有【计数 / 负向】断言一律跑在【剥掉注释】的文本上 ——
    #    文件头部的说明性注释里本身就写着 `has_trait` / `every_unit_leader` /
    #    `annex_country = { target = FROM transfer_troops = yes }` 这些字样，
    #    不剥注释会自己把自己判失败（本项目第三次踩同一个坑，见 docs/99 §51 五）。
    $dtNC = [regex]::Replace($dt, '(?m)#[^\r\n]*', '')
    $ctNC = [regex]::Replace($ct, '(?m)#[^\r\n]*', '')
    if ($dtNC -match '(?s)every_scientist\s*=\s*\{\s*include_invisible\s*=') {
        Fail 'every_scientist 中的 include_invisible 在本机引擎日志中被判为 Unknown effect-type'
    } else { Pass '8 条整合决议未在 every_scientist 中写无效的 include_invisible' }

    # 18b 分类 ↔ 决议 = 同名顶层块（写成字段会静默不挂分类）
    $catName = [regex]::Match($ctNC, '(?m)^\s*([a-z0-9_]+)\s*=\s*\{').Groups[1].Value
    if ($catName -ne 'hof_sov_integrate_category') {
        Fail "分类文件顶层块名 = $catName（应为 hof_sov_integrate_category）"
    } elseif (-not ([regex]::IsMatch($dtNC, '(?m)^' + [regex]::Escape($catName) + '\s*=\s*\{'))) {
        Fail "决议文件里没有同名顶层块 $catName —— 决议不会挂上分类（静默失效）"
    } else {
        Pass "分类 ↔ 决议 同名顶层块 = $catName"
    }
    if ($dtNC -match '(?m)^\s*decision_category\s*=') { Fail '决议文件里混进了 decision_category = 字段（原版 0 次，关联只靠同名块）' }
    else { Pass '决议文件未使用 decision_category 字段（关联方式正确）' }

    # 18c 用户口径：完成「宣称波罗的海」后可用（分类级）
    if ($ctNC -match '(?m)^\s*has_completed_focus\s*=\s*SOV_claims_in_baltic\s*$') { Pass '分类 visible 挂在 SOV_claims_in_baltic（宣称波罗的海）之后' }
    else { Fail '分类 visible 里没有 has_completed_focus = SOV_claims_in_baltic' }

    # 18d 切出 8 条决议块
    $blk = @{}
    $idx = @()
    foreach ($m in [regex]::Matches($dtNC, '(?m)^\thof_sov_integrate_([a-z]+)\s*=\s*\{')) {
        $idx += [pscustomobject]@{ Name = $m.Groups[1].Value; Start = $m.Index }
    }
    for ($i = 0; $i -lt $idx.Count; $i++) {
        $end2 = if ($i + 1 -lt $idx.Count) { $idx[$i + 1].Start } else { $dtNC.Length }
        $blk[$idx[$i].Name] = $dtNC.Substring($idx[$i].Start, $end2 - $idx[$i].Start)
    }
    if ($idx.Count -ne $intWant.Count) { Fail "决议块应 $($intWant.Count) 条（一国一条），实际 $($idx.Count) 条" }
    else { Pass "决议块 = $($idx.Count) 条（一国一条 —— 用户口径「不是全部一起」）" }

    # 18e 逐条：tag 唯一 / 天数 / 特质过滤 / 结构 / 顺序 / 解锁国策 / 双条件
    $badTag = @(); $badDays = @(); $badTrait = @(); $badStruct = @(); $badOrder = @(); $badGate = @(); $badCond = @()
    foreach ($w in $intWant) {
        $k = $w.Id
        if (-not $blk.ContainsKey($k)) { $badStruct += "$k(缺块)"; continue }
        $b = $blk[$k]

        # ⭐ 一条决议只许有一个 tag —— 这就是「不是全部一起」
        # ⚠️ 用 `\btag` 而不是 `^\s*tag` —— 本文件把 target_trigger 写在单行
        #    （`target_trigger = { FROM = { tag = EST } }`），行首匹配会一个也抓不到。
        #    `\b` 同时排除 `original_tag` / `set_cosmetic_tag`（`tag` 前面是下划线，无词边界）。
        $tags = @([regex]::Matches($b, '\btag\s*=\s*([A-Z]{3})\b') | ForEach-Object { $_.Groups[1].Value })
        if ($tags.Count -ne 1 -or $tags[0] -ne $w.Tag) { $badTag += "$k(实际 $($tags -join '/') 个，期望 $($w.Tag) 恰 1 个)" }

        $m = [regex]::Match($b, '(?m)^\s*days_remove\s*=\s*(\d+)')
        if (-not $m.Success) { $badDays += "$k(缺)" }
        elseif ([int]$m.Groups[1].Value -ne $w.Days) { $badDays += "$k($($m.Groups[1].Value)≠$($w.Days))" }

        $hasTrait = $b -match 'has_trait'
        if ($null -ne $w.Trait) {
            if (-not ($b -match ('NOT\s*=\s*\{\s*has_trait\s*=\s*' + [regex]::Escape($w.Trait) + '\s*\}'))) { $badTrait += "$k(缺 $($w.Trait))" }
        } elseif ($hasTrait) { $badTrait += "$k(不该有特质过滤)" }

        $sc = ([regex]::Matches($b, 'every_scientist\s*=\s*\{')).Count
        $ul = ([regex]::Matches($b, 'every_unit_leader\s*=\s*\{')).Count
        $sn = ([regex]::Matches($b, 'set_nationality\s*=\s*ROOT')).Count
        $an = ([regex]::Matches($b, 'annex_country\s*=\s*\{')).Count
        $tt = ([regex]::Matches($b, 'transfer_troops\s*=\s*yes')).Count
        $tf = ([regex]::Matches($b, 'target\s*=\s*FROM')).Count
        if ($sc -ne 1 -or $ul -ne 1 -or $sn -ne 2 -or $an -ne 1 -or $tt -ne 1 -or $tf -ne 1) {
            $badStruct += "$k(scientist=$sc leader=$ul set_nat=$sn annex=$an troops=$tt target_from=$tf)"
        }

        $pSn = $b.IndexOf('set_nationality'); $pAn = $b.IndexOf('annex_country')
        if ($pSn -lt 0 -or $pAn -lt 0 -or $pSn -gt $pAn) { $badOrder += $k }

        if (-not ($b -match 'has_completed_focus\s*=\s*SOV_claims_in_baltic')) { $badGate += $k }

        $ns = ([regex]::Matches($b, 'is_subject_of\s*=\s*ROOT')).Count
        $ng = ([regex]::Matches($b, 'has_government\s*=\s*communism')).Count
        if ($ns -lt 2 -or $ng -lt 2) { $badCond += "$k(subject=$ns comm=$ng)" }
    }
    if ($badTag.Count -eq 0) { Pass '8 条决议各自只挂 1 个 tag，且 tag 逐条对得上（EST / LAT / LIT / NOR / SWE / FIN / TUR / POL）' }
    else { Fail ("tag 不符（每条必须恰 1 个）：" + ($badTag -join ' ')) }
    if ($badDays.Count -eq 0) { Pass '天数正确：波罗的海三国与波兰各 15 天 · 挪威/瑞典/芬兰/土耳其各 30 天' }
    else { Fail ("days_remove 不符：" + ($badDays -join ' ')) }
    if ($badTrait.Count -eq 0) { Pass '特质过滤正确：三国波罗的海各排 BALTIC_anti_bolshevik · 波兰排 POL_sanation_right_leader · 北欧四国与土耳其无过滤' }
    else { Fail ("特质过滤不符：" + ($badTrait -join ' ')) }
    if ($badStruct.Count -eq 0) { Pass '8 条结构一致：转科学家 ×1 + 转将领 ×1 + set_nationality ×2 + annex_country ×1（transfer_troops = yes）' }
    else { Fail ("决议结构不符（期望 scientist=1 leader=1 set_nat=2 annex=1 troops=1 target_from=1）：" + ($badStruct -join ' ')) }
    if ($badOrder.Count -eq 0) { Pass '8 条都是先转角色、后 annex_country（顺序不能反）' }
    else { Fail ("角色转移写在吞并之后：" + ($badOrder -join ', ')) }
    if ($badGate.Count -eq 0) { Pass '8 条的 target_root_trigger 都判 SOV_claims_in_baltic' }
    else { Fail ("决议里缺解锁国策判断：" + ($badGate -join ', ')) }
    if ($badCond.Count -eq 0) { Pass '8 条的 visible 与 available 都判了「是苏联附庸 + 共产主义政体」' }
    else { Fail ("缺少附属/政体条件：" + ($badCond -join ' ')) }

    # 18f 特质不许串条：全文件 has_trait 恰好 4 处（三国波罗的海 + 波兰）
    $traitCnt = ([regex]::Matches($dtNC, 'has_trait')).Count
    if ($traitCnt -eq 4) { Pass '全文件 has_trait 恰好 4 处（EST/LAT/LIT 各 1 + POL 1）' }
    else { Fail "全文件 has_trait 应 4 处，实际 $traitCnt 处" }
    $traitPos = @{}
    foreach ($w in $intWant) { if ($blk.ContainsKey($w.Id)) { $traitPos[$w.Id] = ($blk[$w.Id] -match 'has_trait') } }
    if ($traitPos['norway'] -or $traitPos['sweden'] -or $traitPos['finland'] -or $traitPos['turkey']) { Fail '北欧四国 / 土耳其的块里串进了特质过滤' }
    else { Pass '北欧四国与土耳其的块里没有特质过滤' }

    # 18g 用户第二道口径：去掉丹麦与冰岛 · 旧的两条合并式决议必须消失
    $gone = @()
    foreach ($g in @('hof_sov_integrate_baltic', 'hof_sov_integrate_nordic')) {
        if ($dt.Contains($g)) { $gone += ($g + '(决议)') }
        if ($lt -match ('(?m)^\s*' + [regex]::Escape($g) + ':')) { $gone += ($g + '(本地化)') }
    }
    if ($gone.Count -gt 0) { Fail ("旧的合并式决议未清干净：" + ($gone -join ', ')) }
    else { Pass '旧的两条合并式决议（baltic / nordic）在决议与本地化里都已清除' }
    $denice = @()
    foreach ($tg in @('DEN', 'ICE')) {
        if ($dtNC -match ('\btag\s*=\s*' + $tg + '\b')) { $denice += $tg }
    }
    if ($denice.Count -gt 0) { Fail ("用户已剔除的国家还在 tag 里：" + ($denice -join ', ')) }
    else { Pass '丹麦 DEN / 冰岛 ICE 都不在目标 tag 里（用户 2026-09-25 口径）' }

    # 18h 本地化：8 条 × 2 键 + 分类 2 键 = 18 键；显示名逐个比对（判据 K）
    $keys = @('hof_sov_integrate_category', 'hof_sov_integrate_category_desc')
    foreach ($w in $intWant) { $keys += ('hof_sov_integrate_' + $w.Id); $keys += ('hof_sov_integrate_' + $w.Id + '_desc') }
    $mk = @()
    foreach ($k in $keys) { if (-not ($lt -match ('(?m)^\s*' + [regex]::Escape($k) + ':\s*0\s+"'))) { $mk += $k } }
    if ($mk.Count -eq 0) { Pass "本地化 $($keys.Count) 个键齐全（分类 2 + 8 条 × 2）" }
    else { Fail ("缺本地化键：" + ($mk -join ', ')) }

    $badName = @()
    foreach ($w in $intWant) {
        $nm = [regex]::Match($lt, '(?m)^\s*hof_sov_integrate_' + $w.Id + '\s*:\s*0\s+"([^"]*)"')
        if (-not $nm.Success) { $badName += "$($w.Id)(读不出)" }
        elseif ($nm.Groups[1].Value -ne $w.Name) { $badName += "$($w.Id)($($nm.Groups[1].Value)≠$($w.Name))" }
    }
    if ($badName.Count -eq 0) { Pass '8 个显示名逐个对得上「整合XX加盟共和国」（判据 K：与原版 4 个「整合XX」都不完全相同）' }
    else { Fail ("显示名不符：" + ($badName -join ' ')) }
    foreach ($bad in @('整合爱沙尼亚', '整合挪威', '整合芬兰', '整合波兰')) {
        if ($lt -match ('(?m)^\s*hof_sov_integrate_[a-z_]+\s*:\s*0\s+"' + $bad + '"')) { Fail "有决议的显示名 = 「$bad」，与原版 / R56 已占用的名字完全相同（判据 K 禁区）" }
    }
    $cm = [regex]::Match($lt, '(?m)^\s*hof_sov_integrate_category\s*:\s*0\s+"([^"]*)"')
    if ($cm.Success -and $cm.Groups[1].Value -eq '整合加盟共和国') { Pass '分类显示名 = 「整合加盟共和国」（用户指定）' }
    else { Fail '分类显示名不是用户指定的「整合加盟共和国」' }
}

# ---------- 19. 取消 6 组国策互斥（原版 / R56 苏联树） ----------
# 为什么值得断言：
#   ① soviet.txt 每次都从 R56 重新生成 ⇒ 取消互斥【只能】靠 sync-from-r56.ps1 的
#      $MutexRemovalMap 删；那张表一旦被人删掉或 id 打错，互斥会【静默复活】（游戏不报错）。
#   ② 互斥在原版 / R56 里是【两个方向各声明一次】⇒ 只删一边 = 没删（游戏里仍然互斥）。
#   ③ 删的必须是 `mutually_exclusive = { focus = X }` 这一行，不是国策本体
#      —— 本体删掉会静默少一个国策（比互斥更严重）。
#   ④ 互斥条数【不写死】：现场从 R56 源数一遍，再与生成物比对（本项目的通用纪律：
#      能现场算的不要写死 —— R56 更新过之后写死的数会变成假警报）。
Write-Output ''
Write-Output "=== 19. 取消 6 组苏联国策互斥（2026-09-25 / 27 用户口径）==="

# 期望表：6 组 × 两个方向 = 12 个 id（改这里就是改断言）
$mutexWant = @(
    'SOV_national_specialists', 'SOV_foreign_experts',
    'SOV_positive_heroism', 'SOV_collectivist_propaganda',
    'SOV_policy_of_collective_security', 'SOV_policy_of_individual_security',
    'SOV_the_builder_of_the_red_army', 'SOV_reigniting_the_revolutionary_spirit',
    'SOV_restore_cossack_units', 'SOV_cohesion_first',
    'SOV_the_molotov_line', 'SOV_improve_the_stalin_line'
)

# 19a / 19b 同步脚本侧：表在不在、id 全不全、函数在不在、管线上挂没挂
$syncAbs = Join-Path (Split-Path (Split-Path $ModRoot -Parent) -Parent) 'build\sync-from-r56.ps1'
if (-not (Test-Path $syncAbs)) { Fail "找不到同步脚本：$syncAbs" }
else {
    $syncNC = [regex]::Replace([System.IO.File]::ReadAllText($syncAbs), '(?m)#[^\r\n]*', '')

    if (-not $syncNC.Contains('$MutexRemovalMap')) { Fail '同步脚本里没有 $MutexRemovalMap —— 下次同步会把互斥静默加回来' }
    else {
        $miss = @($mutexWant | Where-Object { $syncNC -notmatch ("'" + [regex]::Escape($_) + "'") })
        if ($miss.Count -gt 0) { Fail ('$MutexRemovalMap 里缺 id：' + ($miss -join ', ')) }
        else { Pass ('$MutexRemovalMap 在位，6 组 × 2 方向共 ' + $mutexWant.Count + ' 个 id 齐全') }

        $hasFn   = [bool]($syncNC -match 'function\s+Remove-MutexLines')
        $hasCall = [bool]($syncNC -match '\$MutexRemovalMap\.ContainsKey')
        if ($hasFn -and $hasCall) { Pass 'Remove-MutexLines 函数在位，且已在管线（2d）里被调用' }
        else { Fail ("同步脚本不完整：函数=$hasFn / 管线调用=$hasCall") }
    }
}

# 19c 生成的 soviet.txt 里，这 12 个方向不许再出现在任何 mutually_exclusive 里
$sovNC = [regex]::Replace($sov, '(?m)#[^\r\n]*', '')
$still = @()
foreach ($fid in $mutexWant) {
    if ([regex]::IsMatch($sovNC, 'mutually_exclusive\s*=\s*\{[^}]*' + [regex]::Escape($fid) + '\s*\}')) { $still += $fid }
}
if ($still.Count -gt 0) { Fail ('互斥没删干净（仍在 mutually_exclusive 里）：' + ($still -join ', ')) }
else { Pass '6 组互斥的 12 个方向在 soviet.txt 里全部消失' }

# 19d 国策本体必须一个都没少 —— 删的是互斥行，不是国策
$noBody = @()
foreach ($fid in $mutexWant) {
    if (-not ([regex]::IsMatch($sovNC, '(?m)^\s*id\s*=\s*' + [regex]::Escape($fid) + '\s*$'))) { $noBody += $fid }
}
if ($noBody.Count -gt 0) { Fail ('以下国策的定义块被误删（只剩互斥行没删本体）：' + ($noBody -join ', ')) }
else { Pass '12 个国策本体都还在（只删了互斥行）' }

# 19e 条数核对：现场从 R56 源数一遍，生成物应恰好少 12 条
$r56Sov = Join-Path $R56Root 'common\national_focus\soviet.txt'
if (-not (Test-Path $r56Sov)) { Fail "找不到 R56 源文件：$r56Sov" }
else {
    $r56NC = [regex]::Replace([System.IO.File]::ReadAllText($r56Sov), '(?m)#[^\r\n]*', '')
    $r56Cnt = ([regex]::Matches($r56NC, 'mutually_exclusive\s*=\s*\{')).Count
    $nowCnt = ([regex]::Matches($sovNC, 'mutually_exclusive\s*=\s*\{')).Count
    # ⚠️ 我们自己的国策里也有互斥，那是本项目【自己】声明的，不在本次取消范围内 ⇒ 期望值要加回来：
    #    托洛茨基 4（劳动军 / 有限市场改革 / 国家建设者 / 永久革命）+ 布哈林 2（左翼共产主义 / 过渡经济学）
    #    + 季诺维也夫 2（群众性国际 / 铁板一块的国际）= 8 处（实测）。
    $ownCnt = ([regex]::Matches($sovNC, '(?s)mutually_exclusive\s*=\s*\{.{0,200}?hof_ic_')).Count
    $expect = $r56Cnt - $mutexWant.Count + $ownCnt
    if ($nowCnt -eq $expect) {
        Pass ("互斥条数 = $nowCnt（= R56 源 $r56Cnt − 本次删掉 $($mutexWant.Count) + 我们自己的 $ownCnt）")
    } else {
        Fail "互斥条数 = $nowCnt（期望 $expect = R56 的 $r56Cnt − $($mutexWant.Count) + 自有 $ownCnt）"
    }
}

# ---------- 20. 2026-09-25 「国家建筑设计局」升级链（4+3 任选） ----------
# 为什么值得断言：
#   ① 这条链的正确性完全建立在「22 个组合态 idea 的 visible 与名字对得上」上 ——
#      名字（hof_gos_c2_usa_eng）与 visible 里的 flag 一旦不一致，游戏里就会出现
#      「状态与 idea 不匹配」的静默错乱（没有报错，只是加成不对）。
#   ② common/decisions/SOV.txt 是【整文件覆盖 + 决议块替换】的产物 ⇒ 必须确认
#      4 个块被换掉了、而文件的【其余部分一个字节都没动】。
#   ③ 基础 idea SOV_gosproyektstroy_1 从 ideas/SOV.txt 搬到了 hof_gos_chain.txt，
#      两处都定义或两处都没有 = 静默失效。
Write-Output ''
Write-Output "=== 20. 国家建筑设计局升级链（4 国任意顺序 + 3 专精任意顺序）==="

$chainFile = Join-Path $ModRoot 'common\ideas\hof_gos_chain.txt'
$ideasSov  = Join-Path $ModRoot 'common\ideas\SOV.txt'
$decSovGen = Join-Path $ModRoot 'common\decisions\SOV.txt'
$r56DecSov = Join-Path $R56Root 'common\decisions\SOV.txt'
$injGos    = Join-Path $PSScriptRoot 'inject-dec-gos.txt'
$genPy     = Join-Path $PSScriptRoot 'gen-hof-gos-chain.py'

foreach ($f in @($chainFile, $ideasSov, $decSovGen, $r56DecSov, $injGos, $genPy)) {
    if (-not (Test-Path $f)) { Fail ("缺文件：" + (Split-Path $f -Leaf)); }
}

if ((Test-Path $chainFile) -and (Test-Path $ideasSov) -and (Test-Path $decSovGen)) {
    $chainRaw = [System.IO.File]::ReadAllBytes($chainFile)
    $chain = [System.IO.File]::ReadAllText($chainFile)
    $sovIdeas = [System.IO.File]::ReadAllText($ideasSov)
    $gen = [System.IO.File]::ReadAllText($decSovGen)

    # 20a 编码红线：脚本 .txt 必须 UTF-8 无 BOM
    $bomBad = @()
    foreach ($f in @($chainFile, $decSovGen)) {
        if (((Get-Content -LiteralPath $f -Encoding Byte -TotalCount 3) -join ',') -eq '239,187,191') { $bomBad += (Split-Path $f -Leaf) }
    }
    if ($bomBad.Count -gt 0) { Fail ("以下脚本文件不应带 BOM：" + ($bomBad -join ', ')) } else { Pass 'hof_gos_chain.txt 与 decisions/SOV.txt 都是 UTF-8 无 BOM' }

    # 20b 23 个 idea + 全部挂在 industrial_concern 类别
    $chainNC = [regex]::Replace($chain, '(?m)#[^\r\n]*', '')
    if (-not ($chainNC -match '(?m)^\tindustrial_concern\s*=\s*\{')) { Fail 'hof_gos_chain.txt 里没有 industrial_concern 类别块' }
    else { Pass 'hof_gos_chain.txt 挂在 industrial_concern 类别下（占我们扩出来 3 个工业企业槽）' }
    $ids = @([regex]::Matches($chainNC, '(?m)^\t\t(\w+)\s*=\s*\{') | ForEach-Object { $_.Groups[1].Value })
    $want = 23
    if ($ids.Count -ne $want) { Fail "chain 里的 idea 数 = $($ids.Count)（应为 $want）" } else { Pass "idea 数 = $($ids.Count)（基础 1 + 阶段 1 的 15 + 阶段 2 的 7）" }

    # 20c ⭐ 名字 ↔ visible 对齐（本节最重要的断言）
    $mis = @()
    foreach ($id in $ids) {
        $seg = [regex]::Match($chainNC, '(?ms)^\t\t' + [regex]::Escape($id) + '\s*=\s*\{.*?^\t\t\}')
        if (-not $seg.Success) { $mis += "$id(块读不出)"; continue }
        $b = $seg.Value
        if ($id -eq 'SOV_gosproyektstroy_1') {
            if (-not ($b -match 'has_completed_focus\s*=\s*SOV_foreign_experts')) { $mis += "$id(缺 available 门)" }
            continue
        }
        # 从名字推期望的 flag 集合
        $m = [regex]::Match($id, '^hof_gos_([cs])(\d)_(.+)$')
        if (-not $m.Success) { $mis += "$id(名字不合规)"; continue }
        $kind = $m.Groups[1].Value
        $body = $m.Groups[3].Value
        $wantOn = @()
        if ($kind -eq 'c') { $wantOn = @($body -split '_') }
        else {
            if ($body -eq 'all') { $wantOn = @('civ', 'mil', 'dock') }
            else { $wantOn = @($body -split '_') }
            # 阶段 2 一定含 4 国
            foreach ($c in @('usa', 'eng', 'ger', 'jap')) { if ($wantOn -notcontains $c) { $wantOn += $c } }
        }
        foreach ($x in @('usa', 'eng', 'ger', 'jap', 'civ', 'mil', 'dock')) {
            $on = ($b -match ('(?m)^\s*has_country_flag\s*=\s*hof_gos_' + $x + '\s*$'))
            $off = ($b -match ('(?m)^\s*NOT\s*=\s*\{\s*has_country_flag\s*=\s*hof_gos_' + $x + '\s*\}'))
            if ($wantOn -contains $x) { if (-not ($on -and -not $off)) { $mis += "$id(应含 $x 但 visible 不是)" } }
            else { if (-not ($off -and -not $on)) { $mis += "$id(应不含 $x 但 visible 不是)" } }
        }
    }
    if ($mis.Count -eq 0) { Pass "23 个 idea 的 visible 与名字（组合态）逐条对齐" }
    else { Fail ("visible 与名字不符：" + (($mis | Select-Object -First 6) -join ' ')) }

    # 20d 终态 idea 必须是「全收集」的完整加成表
    $lastId = 'hof_gos_s3_all'
    $seg = [regex]::Match($chainNC, '(?ms)^\t\t' + $lastId + '\s*=\s*\{.*?^\t\t\}')
    if (-not $seg.Success) { Fail "找不到终态 idea $lastId" }
    else {
        $need = @(
            'production_speed_industrial_complex_factor = 0.1',
            'production_speed_arms_factory_factor = 0.1',
            'production_speed_dockyard_factor = 0.1',
            'license_purchase_cost = -0.25',
            'production_factory_max_efficiency_factor = 0.1',
            'line_change_production_efficiency_factor = 0.1',
            'production_lack_of_resource_penalty_factor = -0.1',
            'production_factory_efficiency_gain_factor = 0.05',
            'production_factory_start_efficiency_factor = 0.1',
            'consumer_goods_factor = -0.15',
            'industrial_capacity_factory = 0.05',
            'industrial_capacity_dockyard = 0.05'
        )
        $missing = @($need | Where-Object { -not ($seg.Value -match [regex]::Escape($_)) })
        if ($missing.Count -gt 0) { Fail ("终态 idea 缺加成：" + ($missing -join ' / ')) }
        else { Pass "终态 idea = 12 条完整加成（4 国特性 + 3 专精 + 基础，全收集）" }
    }

    # 20e 基础 idea 只能定义一次（从 ideas/SOV.txt 搬走后不能再留着）
    if ($sovIdeas -match 'SOV_gosproyektstroy_\d') { Fail 'ideas/SOV.txt 里还留着 SOV_gosproyektstroy_* 定义（会与 hof_gos_chain.txt 重复）' }
    else { Pass 'SOV_gosproyektstroy_* 已从 ideas/SOV.txt 移出（只在 hof_gos_chain.txt 定义一次）' }

    # 20f 生成的 decisions/SOV.txt：4 个块被换掉、其余部分与 R56 源【逐字节一致】
    $genL = $gen
    $srcL = [System.IO.File]::ReadAllText($r56DecSov)
    $needMark = @('hof_gos_country_phase_done', 'hof_gos_started', 'fire_only_once = no', 'swap_ideas = {')
    $mk = @($needMark | Where-Object { -not $genL.Contains($_) })
    if ($mk.Count -gt 0) { Fail ("decisions/SOV.txt 里缺标记：" + ($mk -join ', ')) }
    else { Pass 'decisions/SOV.txt 含新链的全部标记（阶段 flag / 任意顺序门 / swap_ideas）' }
    $sw = ([regex]::Matches($genL, 'swap_ideas\s*=\s*\{')).Count
    if ($sw -eq 66) { Pass "swap_ideas 共 66 处（原版 38 − 16 + 新 44 = 66）" }
    else { Fail "swap_ideas 共 $sw 处（期望 66）" }

    # 20f-1 分类页签依赖阶段 1 的目标卡仍有可显示目标；外交条件不得在 target_trigger 把四国全筛光。
    $gosStart = $genL.IndexOf("`tSOV_gosproyektstroy_bring_foreign_experts = {")
    $gosEnd = $genL.IndexOf("`tSOV_gosproyektstroy_focus_civ = {", $gosStart)
    if ($gosStart -lt 0 -or $gosEnd -lt 0) { Fail '阶段 1 外国专家决议块未找到' }
    else {
        $gosBlock = $genL.Substring($gosStart, $gosEnd - $gosStart)
        $gosTarget = ($gosBlock -split 'days_remove\s*=', 2)[0]
        $gosAvailable = ($gosBlock -split 'available\s*=\s*\{', 2)[1]
        if ($gosTarget -notmatch 'has_opinion|SOV_is_valid_subject|has_war_with' -and
            $gosAvailable -match 'FROM\s*=\s*\{[\s\S]*?has_opinion[\s\S]*?SOV_is_valid_subject[\s\S]*?has_war_with') {
            Pass '阶段 1：四国目标先显示，外交条件沿用原版 available'
        } else { Fail '阶段 1：外交条件仍可能在 target_trigger 筛光目标，或 available 缺原版条件' }
    }

    # 挖掉 4 个决议块后必须与源逐行相同（证明「只改了这 4 块」）
    function Strip-4DecBlocks([string]$text) {
        $lines = ($text -replace "`r`n", "`n").Split("`n")
        $skip = @{}
        foreach ($iid in @('SOV_gosproyektstroy_bring_foreign_experts', 'SOV_gosproyektstroy_focus_civ', 'SOV_gosproyektstroy_focus_mil', 'SOV_gosproyektstroy_focus_dock')) {
            $hit = -1
            for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match ('^' + [char]9 + [regex]::Escape($iid) + '\s*=\s*\{$')) { $hit = $i; break } }
            if ($hit -lt 0) { continue }
            $d = 0
            for ($k = $hit; $k -lt $lines.Count; $k++) {
                $d += ([regex]::Matches($lines[$k], '\{')).Count - ([regex]::Matches($lines[$k], '\}')).Count
                $skip[$k] = $true
                if ($d -eq 0 -and $k -gt $hit) { break }
            }
        }
        $out = @()
        for ($i = 0; $i -lt $lines.Count; $i++) { if (-not $skip.ContainsKey($i)) { $out += $lines[$i] } }
        return ($out -join "`n")
    }
    if ((Strip-4DecBlocks $genL) -eq (Strip-4DecBlocks $srcL)) {
        Pass '挖掉这 4 个决议块之后，decisions/SOV.txt 与 R56 源【逐行相同】（改动的边界干净）'
    } else {
        Fail 'decisions/SOV.txt 在 4 个决议块之外还有差异 —— 改动越界了'
    }

    # 20g 同步链：生成器 / 注入文件 / 表 / 函数 / extraFiles 都在位
    $syncTxt = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'sync-from-r56.ps1'))
    $syncNC2 = [regex]::Replace($syncTxt, '(?m)#[^\r\n]*', '')
    $need2 = @{
        'Set-DecisionBlock 函数' = 'function\s+Set-DecisionBlock'
        'DecisionBlockMap 表'   = '\$DecisionBlockMap'
        'extraFiles 读取'        = '\$extraPoints\s*=\s*\$parsedList\.extraFiles'
        '读 inject-dec-gos.txt'  = 'inject-dec-gos\.txt'
    }
    $bad2 = @()
    foreach ($k in $need2.Keys) { if (-not ($syncNC2 -match $need2[$k])) { $bad2 += $k } }
    if ($bad2.Count -gt 0) { Fail ("同步脚本缺：" + ($bad2 -join ', ')) } else { Pass '同步脚本：Set-DecisionBlock + $DecisionBlockMap + extraFiles + inject-dec-gos.txt 全在位' }

    $ap = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'attach-points.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $extra = @($ap.extraFiles)
    $extraPaths = @($extra | ForEach-Object { $_.srcRelativePath })
    if ($extraPaths.Count -lt 2 -or $extraPaths -notcontains 'common/decisions/SOV.txt' -or $extraPaths -notcontains 'events/SovietUnion.txt') {
        Fail 'attach-points.json 的 extraFiles 缺少苏联决议或图瓦事件整文件覆盖点'
    } else { Pass 'attach-points.json：苏联决议与图瓦事件均纳入自动同步' }
}

# 21 图哈切夫斯基的国策、四家 MIO、旧档补发必须连成同一条链。
$mioOrgPath = Join-Path $modRoot 'common/military_industrial_organization/organizations/SOV_organization.txt'
$mioEffectPath = Join-Path $modRoot 'common/scripted_effects/hof_ic_mio_effects.txt'
$mioActionPath = Join-Path $modRoot 'common/on_actions/hof_ic_mio_on_actions.txt'
$mioFocusPath = Join-Path $modRoot 'common/national_focus/soviet.txt'
$mioLocPath = Join-Path $modRoot 'localisation/simp_chinese/hof_ic_mio_l_simp_chinese.yml'
$mioFiles = @($mioOrgPath, $mioEffectPath, $mioActionPath, $mioFocusPath, $mioLocPath)
if (@($mioFiles | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -gt 0) {
    Fail '空中机械化的 MIO 组织／效果／周钩子／国策／本地化文件缺失'
} else {
    $mioOrg = [System.IO.File]::ReadAllText($mioOrgPath)
    $mioEffect = [System.IO.File]::ReadAllText($mioEffectPath)
    $mioAction = [System.IO.File]::ReadAllText($mioActionPath)
    $mioFocus = [System.IO.File]::ReadAllText($mioFocusPath)
    $mioLoc = [System.IO.File]::ReadAllText($mioLocPath)
    $mioTraits = @('mobile_tanks', 'medium_tanks', 'heavy_tanks', 'air_mechanization')
    $mioBad = @($mioTraits | Where-Object {
        $token = 'hof_ic_mio_tukh_' + $_
        $mioOrg -notmatch [regex]::Escape('token = ' + $token) -or
        $mioEffect -notmatch [regex]::Escape('complete_mio_trait = ' + $token) -or
        $mioLoc -notmatch [regex]::Escape($token + ':0')
    })
    if ($mioBad.Count -eq 0 -and
        $mioFocus.Contains('hof_ic_tukh_mio_air_mechanization = yes') -and
        $mioAction.Contains('on_weekly') -and
        $mioAction.Contains('hof_ic_tukh_mio_air_mechanization = yes')) {
        Pass '空中机械化：四家 MIO 特质、国策授予及旧档周补发贯通'
    } else { Fail ('空中机械化 MIO 链路缺失：' + ($mioBad -join ', ')) }
}

# 22 匈牙利「重燃1848年精神」：原有 keep_all_characters 保科学家，
#    叛军生成后按 trait_HUN_fascist_sympathies 双向核对陆海军将领。
$hunFocusPath = Join-Path $modRoot 'common/national_focus/hungary_wuw.txt'
$hunText = [System.IO.File]::ReadAllText($hunFocusPath)
$hunMatch = [regex]::Match($hunText, '(?s)id\s*=\s*wuw_HUN_reviving_the_spirit_of_1848\s*.*?(?=\r?\n\t(?:focus|shared_focus)\s*=\s*\{|\z)')
if (-not $hunMatch.Success) {
    Fail '匈牙利「重燃1848年精神」国策未找到'
} else {
    $hun = $hunMatch.Value
    if ($hun.Contains('keep_all_characters = yes') -and
        $hun.Contains('limit = { original_tag = ROOT has_war_with = ROOT }') -and
        $hun.Contains('NOT = { has_trait = trait_HUN_fascist_sympathies }') -and
        $hun.Contains('limit = { has_trait = trait_HUN_fascist_sympathies }') -and
        ([regex]::Matches($hun, 'include_invisible\s*=\s*yes')).Count -eq 2 -and
        ([regex]::Matches($hun, 'every_unit_leader\s*=\s*\{')).Count -eq 2 -and
        $hun.Contains('set_nationality = ROOT') -and
        $hun.Contains('set_nationality = PREV.PREV')) {
        Pass '匈牙利内战：科学家留原国家；陆海军将领按法西斯主义支持者特质双向校验'
    } else { Fail '匈牙利内战的科学家保留或将领双向校验缺失' }
}

# 23 阿富汗「打倒国王！」：两种内战规模汇合后的角色归属。
$afgFocusPath = Join-Path $modRoot 'common/national_focus/r56_afghanistan.txt'
$afgText = [System.IO.File]::ReadAllText($afgFocusPath)
$afgMatch = [regex]::Match($afgText, '(?s)id\s*=\s*AFG_depose_the_king\s*.*?(?=\r?\n\t(?:focus|shared_focus)\s*=\s*\{|\z)')
if (-not $afgMatch.Success) {
    Fail '阿富汗「打倒国王！」国策未找到'
} else {
    $afg = $afgMatch.Value
    $afgMarker = '# hof: 内战生成后校验双方将领；科学家全部留在共产主义原国家'
    $afgTail = if ($afg.Contains($afgMarker)) { $afg.Substring($afg.IndexOf($afgMarker)) } else { '' }
    if ($afg.Contains($afgMarker) -and
        ([regex]::Matches($afg, 'keep_all_characters\s*=\s*yes')).Count -eq 2 -and
        $afgTail.Contains('original_tag = ROOT has_civil_war = yes has_war_with = ROOT') -and
        $afgTail.Contains('NOT = { has_trait = AFG_barakzai_royalist }') -and
        $afgTail.Contains('limit = { has_trait = AFG_barakzai_royalist }') -and
        ([regex]::Matches($afgTail, 'every_unit_leader\s*=\s*\{')).Count -eq 2 -and
        ([regex]::Matches($afgTail, 'every_scientist\s*=\s*\{')).Count -eq 1 -and
        ([regex]::Matches($afgTail, 'include_invisible\s*=\s*yes')).Count -eq 3 -and
        $afgTail.Contains('set_nationality = ROOT') -and
        $afgTail.Contains('set_nationality = PREV.PREV')) {
        Pass '阿富汗内战：效忠王室的将领归叛军，其余将领和科学家归共产主义方'
    } else { Fail '阿富汗内战的将领或科学家归属校验缺失' }
}

Write-Output ("==================== 失败项: {0} / 断言执行 {1} ====================" -f $fail, $checks)
if ($fail -eq 0) { Write-Output "全部通过，可以启动游戏验证了。" }

# 失败清单落盘（真 UTF-8，不受控制台编码影响；全绿时写出空文件）
$failPath = Join-Path $PSScriptRoot 'verify-s2-failures.txt'
[System.IO.File]::WriteAllLines($failPath, [string[]]$failMsgs, (New-Object System.Text.UTF8Encoding($false)))

exit $fail

# =============================================================================
# 核心圈 · 立绘接入前置核查
# -----------------------------------------------------------------------------
# 三件事：
#   1. 解析 7 名角色立绘的【贴图路径】—— 跨原版与 R56 的 .gfx 注册表
#      （注意：只有 GFX 名字不够，我们要的是 texturefile 那一行的实际路径）
#   2. 核查 scripted_localisation 里"无 trigger 的兜底 text"写法是否真实存在
#      （我们生成的 hof_ic_scripted_loc.txt 用了这个写法，必须确认合法）
#   3. 检查 gfx/interface/hof_ic/portraits/ 下美术是否已到位
#
# 为什么要写成脚本文件而不是命令行：这台机器的终端会在命令开头注入一个
# 杂散控制字符（^U），使第一条赋值语句被执行器当成命令名而失败，
# 后续循环因此拿到空集合，产生【假的"未找到"结果】。
# =============================================================================

$ErrorActionPreference = 'Continue'

$vanilla = 'F:\Hearts of Iron IV'
$r56     = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$ourMod  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'

Write-Output '################ 1. 立绘贴图路径解析 ################'

$targets = @(
    'GFX_portrait_SOV_lev_trotsky',
    'GFX_portrait_SOV_nikolay_bukharin',
    'GFX_portrait_SOV_aleksey_rykov',
    'GFX_portrait_SOV_grigory_zinovyev',
    'GFX_portrait_SOV_lev_kamenev',
    'GFX_portrait_SOV_ivan_smirnov',
    'GFX_portrait_SOV_leonid_serebryakov'
)

$found = @{}

foreach ($root in @($vanilla, $r56)) {

    $isVanilla = ($root -eq $vanilla)
    $label = if ($isVanilla) { '原版' } else { 'R56' }

    # 只扫 interface\ 下的 .gfx。
    # 领袖立绘的注册表就是 interface\_leader_portraits.gfx，
    # 不要对整个游戏目录做 -Recurse：那要爬几万个文件，慢到终端会先返回。
    $gfxDir = Join-Path $root 'interface'
    if (-not (Test-Path $gfxDir)) { continue }

    foreach ($f in (Get-ChildItem $gfxDir -Filter '*.gfx' -File -ErrorAction SilentlyContinue)) {

        $L = [System.IO.File]::ReadAllLines($f.FullName)

        for ($i = 0; $i -lt $L.Count; $i++) {

            foreach ($t in $targets) {

                if ($L[$i] -match ('^\s*name\s*=\s*"' + [regex]::Escape($t) + '"\s*$')) {

                    $tf = '(未找到 texturefile)'
                    for ($j = $i + 1; $j -le [Math]::Min($i + 4, $L.Count - 1); $j++) {
                        if ($L[$j] -match 'texturefile\s*=\s*"([^"]+)"') { $tf = $Matches[1]; break }
                    }

                    if (-not $found.ContainsKey($t)) {
                        $found[$t] = [pscustomobject]@{
                            Gfx   = $t
                            Path  = $tf
                            Root  = $label
                            Src   = $f.FullName.Replace($root + '\', '')
                        }
                    }
                }
            }
        }
    }
}

foreach ($t in $targets) {
    if ($found.ContainsKey($t)) {
        $e = $found[$t]
        Write-Output ("  {0,-42} => {1}" -f $t, $e.Path)
        Write-Output ("  {0,-42}    (来自 {1} : {2})" -f '', $e.Root, $e.Src)
    }
    else {
        Write-Output ("  {0,-42} => 未注册（需在 hof_ic.gfx 中用裸 .dds 路径自建 sprite）" -f $t)
    }
}

Write-Output ''
Write-Output '################ 2. 裸 .dds 立绘文件是否存在 ################'

$bareDds = @(
    @{ Who = '托洛茨基';         Rel = 'gfx/leaders/SOV/r56_portrait_SOV_Leon_Trotsky.dds' },
    @{ Who = '谢列布里亚科夫';   Rel = 'gfx/leaders/SOV/r56_portrait_SOV_Leonid_Serebryakov.dds' }
)

foreach ($b in $bareDds) {
    $hit = $null
    foreach ($root in @($r56, $vanilla)) {
        $p = Join-Path $root ($b.Rel -replace '/', '\')
        if (Test-Path $p) { $hit = $p; break }
    }
    if ($hit) {
        $sz = (Get-Item -LiteralPath $hit).Length
        Write-Output ("  [有] {0,-14} {1}  ({2:N0} 字节)" -f $b.Who, $b.Rel, $sz)
    }
    else {
        Write-Output ("  [缺] {0,-14} {1}  —— 两个库都没有！" -f $b.Who, $b.Rel)
    }
}

Write-Output ''
Write-Output '################ 3. 兜底 text（无 trigger）写法是否存在于官方文件 ################'

# 找形如   text = {  换行  localization_key = XXX  换行 }   的块，
# 中间【没有】 trigger 行 —— 这是"总是通过"的兜底写法。
$probeRoots = @(
    @{ Root = $vanilla; Label = '原版' },
    @{ Root = $r56;     Label = 'R56'  }
)

$hitCount = 0
$hitFiles = @()

foreach ($pr in $probeRoots) {

    $dir = Join-Path $pr.Root 'common\scripted_localisation'
    if (-not (Test-Path $dir)) { continue }

    foreach ($f in (Get-ChildItem $dir -Filter '*.txt' -File -ErrorAction SilentlyContinue)) {

        $L = [System.IO.File]::ReadAllLines($f.FullName)

        for ($i = 0; $i -lt $L.Count - 2; $i++) {

            if ($L[$i] -match '^\s*text\s*=\s*\{\s*$') {
                if ($L[$i + 1] -match '^\s*localization_key\s*=' -or $L[$i + 1] -match '^\s*\}') {
                    $hitCount++
                    $key = "{0} / {1}" -f $pr.Label, $f.Name
                    if ($hitFiles -notcontains $key) { $hitFiles += $key }
                    break
                }
            }
        }
    }
}

if ($hitCount -gt 0) {
    Write-Output "  [有] 找到 $hitCount 处样例，来自以下文件："
    foreach ($h in $hitFiles) { Write-Output "        $h" }
    Write-Output '  => 无 trigger 的兜底 text 是合法写法，我们的生成文件用法正确。'
}
else {
    Write-Output '  [未找到] 官方文件里没搜到这个写法。'
    Write-Output '  => 兜底项写法存疑，需要改设计（例如给兜底项加一个恒真 trigger）。'
}

Write-Output ''
Write-Output '################ 4. 美术是否已到位（gfx/interface/hof_ic/portraits/）################'

$artDir = Join-Path $ourMod 'gfx\interface\hof_ic\portraits'
if (Test-Path $artDir) {
    $arts = Get-ChildItem $artDir -File -ErrorAction SilentlyContinue
    if ($arts) {
        Write-Output "  [有] 目录内 $($arts.Count) 个文件："
        foreach ($a in $arts) { Write-Output ("        {0,-46} {1,10:N0} 字节" -f $a.Name, $a.Length) }
    }
    else {
        Write-Output '  [空] 目录存在但没有文件。'
    }
}
else {
    Write-Output '  [无] 目录尚不存在 —— 美术未交付，属预期（并行进行中）。'
}

Write-Output ''
Write-Output '################ 5. 现有 hof_ic 目录清单 ################'

foreach ($sub in @('gfx\interface\hof_ic', 'common\scripted_effects', 'common\scripted_triggers', 'common\scripted_localisation', 'common\focus_inlay_windows', 'interface', 'localisation\simp_chinese')) {
    $d = Join-Path $ourMod $sub
    if (Test-Path $d) {
        Write-Output "  $sub :"
        foreach ($x in (Get-ChildItem $d -File -ErrorAction SilentlyContinue)) {
            Write-Output ("        {0,-52} {1,10:N0} 字节" -f $x.Name, $x.Length)
        }
    }
    else {
        Write-Output "  $sub : (不存在)"
    }
}

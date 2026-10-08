# SOP 第 0 步：查现成内容（原版 + dlc 子目录 + R56）
# 目标人物：尼基塔·谢尔盖耶维奇·赫鲁晓夫（花名册 Idx 21，regime 营「部分回池」）
# 工具蓝本：build/s0-scan-malenkow.ps1（同一命名约定）
# 🚩 教训（docs/23 第 0 步）：必须扫 dlc\<name>\，漏扫曾导致「布哈林没有大立绘」错判。
# 🚩 性能：F: 盘逐文件 Select-String 跑不完 —— 必须【一次调用 + 路径数组】。
# 🚩 固定必扫项（docs/99 §18.5 + §28，共五处）：
#    ① common/national_focus/ —— 原版有没有为他单独写过国策
#    ② common/country_leader/00_traits.txt —— 有没有专属特质
#    ③ history/countries/SOV - Soviet union.txt —— 在押 / 放逐 / 招募标记
#    ④ common/scripted_guis + scripted_effects + decisions —— 其它专门机制
#    ⑤ **扫原版国策 id 全表找同 / 近名**（docs/99 §28 固定动作）
# ⚠️ 姓名拼法多：
#    英：Khrushchev / Khrushchyov（**本项目花名册 Key 用的是这个，德式转写**）/ Khruschev /
#        Krushchev / Khrushchov / Hrushchov / Chruschtschow / Chrushtchev
#    俄：Хрущёв / Хрущев / Хрушчов / Хрущёва / Хрущёву / Хрущёвым / Хрущева
#    中：赫鲁晓夫 / 赫魯曉夫 / 赫鲁雪夫（台译）
# ⚠️ 陷阱：他的「去斯大林化 / 秘密报告 / 垦荒 / 玉米 / 反党集团」在 R56 里比重极大，命中要逐条读上下文。
# ⚠️ 同营可同席：马林科夫（Idx 20，已实装）、伏罗希洛夫（Idx 22）→ 三条线之间也要避重。
$ErrorActionPreference = 'Continue'

$roots = @(
    @{ Name = '原版';     Path = 'F:\Hearts of Iron IV' },
    @{ Name = '原版-dlc'; Path = 'F:\Hearts of Iron IV\dlc' },
    @{ Name = 'R56';      Path = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)

$rx     = 'khrushchev|khrushchyov|khruschev|krushchev|khrushchov|hrushchov|chruschtschow|chrushtchev|khruschov|Khrushchev|Khrushchyov|Хрущёв|Хрущев|Хрушчов|Хрущёва|Хрущёву|赫鲁晓夫|赫魯曉夫|赫鲁雪夫'
$rxFile = 'khrushchev|khrushchyov|khruschev|krushchev|khrushchov|chruschtschow|Khrushchev|Khrushchyov|Хрущёв|Хрущев'

$subdirs = @('common', 'events', 'history', 'localisation', 'interface')

$out = @()
$out += '==== SOP 第 0 步 · 尼基塔·赫鲁晓夫（Idx 21）===='
$out += ''
foreach ($r in $roots) {
    if (-not (Test-Path $r.Path)) { $out += "[$($r.Name)] 路径不存在：$($r.Path)"; continue }
    $out += "==================== $($r.Name) ===================="

    # --- A. 内容命中（逐行）---
    foreach ($sd in $subdirs) {
        $d = Join-Path $r.Path $sd
        if (-not (Test-Path $d)) { continue }
        $files = @(Get-ChildItem -LiteralPath $d -Recurse -File -ErrorAction SilentlyContinue |
                   Where-Object { $_.Extension -in @('.txt', '.yml', '.gfx', '.gui') } |
                   Select-Object -ExpandProperty FullName)
        if ($files.Count -eq 0) { continue }
        $m = @(Select-String -Path $files -Pattern $rx -ErrorAction SilentlyContinue)
        if ($m.Count -gt 0) {
            $fc = @($m | Select-Object -ExpandProperty Path -Unique).Count
            $out += "  --- $sd （$($m.Count) 行命中 / $fc 个文件）---"
            foreach ($x in $m) {
                $out += ('    {0}:{1}' -f $x.Path.Replace($r.Path + '\', ''), $x.LineNumber)
                $out += ('        ' + $x.Line.Trim())
            }
        }
    }

    # --- B. 文件名命中（立绘 / 资产）---
    $gd = Join-Path $r.Path 'gfx'
    $fn = @()
    if (Test-Path $gd) {
        $fn = @(Get-ChildItem -LiteralPath $gd -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $rxFile } |
                Select-Object -ExpandProperty FullName)
    }
    $out += "  --- gfx 下文件名命中（$($fn.Count) 个）---"
    foreach ($f in $fn) { $out += ('    ' + $f.Replace($r.Path + '\', '')) }

    $out += ''
}

# --- C. 本项目内现况 ---
$wsRoot = Split-Path $PSScriptRoot -Parent
$out += '==================== 本项目内现况 ===================='
foreach ($rel in @('build\gen-hof-ic-s3.ps1',
                   'mod\heart_of_iron\common\national_focus\soviet.txt',
                   'mod\heart_of_iron\localisation\simp_chinese\hof_ic_roster_l_simp_chinese.yml')) {
    $p = Join-Path $wsRoot $rel
    if (-not (Test-Path $p)) { $out += "  （缺）$rel"; continue }
    $h = @(Select-String -Path $p -Pattern 'khrushchyov|khrushchev|赫鲁晓夫' -ErrorAction SilentlyContinue)
    $out += "  --- $rel （$($h.Count) 行）---"
    foreach ($x in $h) { $out += ('    {0}:  {1}' -f $x.LineNumber, $x.Line.Trim()) }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-khrushchev.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

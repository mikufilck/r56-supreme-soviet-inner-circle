# SOP 第 0 步（续）：命中点上下文展开
# 目标人物：米哈伊尔·加里宁（Idx 14）—— 工具蓝本 build/s0-shlyapnikov-ctx.ps1
$ErrorActionPreference = 'Continue'

$V = 'F:\Hearts of Iron IV'
$R = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

$specs = @(
    # ---- 原版 ----
    @{ Tag = '原版'; File = "$V\common\characters\SOV.txt";            From = 2125; To = 2165; Why = '⭐ 完整角色对象 SOV_mikhail_kalinin（看 roles）' },
    @{ Tag = '原版'; File = "$V\common\national_focus\soviet.txt";     From = 11200; To = 11245; Why = '🚩 SOV_mikhail_kalinin = { } 是什么' },
    @{ Tag = '原版'; File = "$V\common\national_focus\soviet.txt";     From = 9210; To = 9255; Why = '🚩 清洗线：retire_character（soviet.txt:9237）' },
    @{ Tag = '原版'; File = "$V\history\countries\SOV - Soviet union.txt"; From = 25; To = 40; Why = 'recruit_character（:31）' },
    @{ Tag = '原版'; File = "$V\history\countries\SOV - Soviet union.txt"; From = 160; To = 190; Why = '⭐ 历史角色块（:169）' },
    @{ Tag = '原版'; File = "$V\events\SovietUnion.txt";               From = 775; To = 815; Why = '⚠️ 被注释掉的 purged_kalinin 草稿（:795）' },
    @{ Tag = '原版'; File = "$V\events\SovietUnion.txt";               From = 1015; To = 1075; Why = '⚠️ 被注释掉的 remove_ideas / purged（:1030）' },
    @{ Tag = '原版'; File = "$V\localisation\simp_chinese\focus_l_simp_chinese.yml"; From = 1070; To = 1080; Why = '🚩 purged_kalinin 本地化' },
    @{ Tag = '原版'; File = "$V\localisation\simp_chinese\events_l_simp_chinese.yml"; From = 2225; To = 2245; Why = '🚩 soviet.25「加里宁的妻子也有嫌疑」事件' },
    @{ Tag = '原版'; File = "$V\common\characters\SOV.txt";            From = 1; To = 12;   Why = '（参考）文件头' },
    # ---- R56 ----
    @{ Tag = 'R56';  File = "$R\common\characters\SOV.txt";            From = 3650; To = 3692; Why = '⭐ R56 角色对象' },
    @{ Tag = 'R56';  File = "$R\common\national_focus\soviet.txt";     From = 13380; To = 13420; Why = '🚩 R56 SOV_mikhail_kalinin = { }' },
    @{ Tag = 'R56';  File = "$R\events\SovietUnion.txt";               From = 775; To = 815; Why = '🚩 R56 启用了 purged_kalinin（不再注释）' },
    @{ Tag = 'R56';  File = "$R\history\countries\SOV - Soviet union.txt"; From = 85; To = 100; Why = 'recruit_character（:93）' },
    @{ Tag = 'R56';  File = "$R\history\countries\SOV - Soviet union.txt"; From = 282; To = 310; Why = '⭐ R56 历史角色块（:291）' }
)

$out = @()
$out += '==== 第 0 步上下文展开 · 米哈伊尔·加里宁（Idx 14）===='
$out += ''

foreach ($s in $specs) {
    $out += ('=' * 100)
    $out += "[$($s.Tag)] $($s.File) : $($s.From)-$($s.To)"
    $out += "  WHY: $($s.Why)"
    $out += ('-' * 100)
    if (-not (Test-Path $s.File)) { $out += '  (文件不存在)'; $out += ''; continue }
    $lines = [System.IO.File]::ReadAllLines($s.File)
    $a = [Math]::Max(0, $s.From - 1)
    $b = [Math]::Min($lines.Count - 1, $s.To - 1)
    for ($i = $a; $i -le $b; $i++) {
        $out += ('{0,6}: {1}' -f ($i + 1), $lines[$i])
    }
    $out += ''
}

# ---- 追查：SOV_gain_support_from_party_members_tt 是哪个国策给的 ----
$out += ('=' * 100)
$out += '[追查] SOV_gain_support_from_party_members_tt 的施用点（原版 + R56）'
$out += ('-' * 100)
foreach ($root in @($V, $R)) {
    $nf = Join-Path $root 'common\national_focus'
    if (-not (Test-Path $nf)) { continue }
    $files = @(Get-ChildItem -LiteralPath $nf -Recurse -File -Filter *.txt | Select-Object -ExpandProperty FullName)
    $m = @(Select-String -Path $files -Pattern 'SOV_gain_support_from_party_members' -ErrorAction SilentlyContinue)
    $out += "  [$root] 命中 $($m.Count) 处"
    foreach ($x in $m) {
        $ln = $x.LineNumber
        $lines = [System.IO.File]::ReadAllLines($x.Path)
        $a = [Math]::Max(0, $ln - 6); $b = [Math]::Min($lines.Count - 1, $ln + 3)
        for ($i = $a; $i -le $b; $i++) { $out += ('    {0,6}: {1}' -f ($i + 1), $lines[$i]) }
        $out += '    ---'
    }
}
$out += ''

# ---- 追查：原版 idea `mikhail_kalinin` 的定义处 ----
$out += ('=' * 100)
$out += '[追查] idea mikhail_kalinin 的定义（原版 ideas/ 下）'
$out += ('-' * 100)
foreach ($root in @($V, $R)) {
    $id = Join-Path $root 'common\ideas'
    if (-not (Test-Path $id)) { continue }
    $m = @(Select-String -Path (Join-Path $id '*.txt') -Pattern 'mikhail_kalinin' -ErrorAction SilentlyContinue)
    $out += "  [$root] 命中 $($m.Count) 处"
    foreach ($x in $m) {
        $lines = [System.IO.File]::ReadAllLines($x.Path)
        $a = [Math]::Max(0, $x.LineNumber - 8); $b = [Math]::Min($lines.Count - 1, $x.LineNumber + 4)
        for ($i = $a; $i -le $b; $i++) { $out += ('    {0,6}: {1}' -f ($i + 1), $lines[$i]) }
        $out += '    ---'
    }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-kalinin-ctx.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

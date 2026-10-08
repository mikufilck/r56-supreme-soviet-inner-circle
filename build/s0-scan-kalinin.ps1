# SOP 第 0 步：查现成内容（原版 + dlc 子目录 + R56）
# 目标人物：米哈伊尔·伊万诺维奇·加里宁（花名册 Idx 14，neutral 营）
# 工具蓝本：build/s0-scan-shlyapnikov.ps1（同一命名约定）
# 🚩 教训（docs/23 第 0 步）：必须扫 dlc\<name>\，漏扫曾导致「布哈林没有大立绘」错判。
# 🚩 性能：F: 盘逐文件 Select-String 跑不完 —— 必须【一次调用 + 路径数组】。
# 🚩 固定必扫项（docs/99 §18.5，共四处）：
#    ① common/national_focus/ —— 原版有没有为他单独写过国策
#    ② common/country_leader/00_traits.txt —— 有没有专属特质
#    ③ history/countries/SOV - Soviet union.txt —— 在押 / 放逐标记
#    ④ common/scripted_guis + scripted_effects + decisions —— 其它专门机制
# ⚠️ 姓名拼法多：Kalinin / Калинин / 加里宁
# ⚠️ 陷阱：Калинин 也是地名（1931–1990 年特维尔市叫加里宁）→ 命中要逐条分人/分地。
# ⚠️ 他是「全俄中央执行委员会主席」（1919-03-30 – 1938-01-19），国家元首型（docs/10 §2.4.2）。
$ErrorActionPreference = 'Continue'

$roots = @(
    @{ Name = '原版';     Path = 'F:\Hearts of Iron IV' },
    @{ Name = '原版-dlc'; Path = 'F:\Hearts of Iron IV\dlc' },
    @{ Name = 'R56';      Path = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125' }
)

$rx     = 'kalinin|Kalinin|KALININ|Калинин|калинин|Калинина|Калинину|Калининым|加里宁'
$rxFile = 'kalinin|Kalinin|Калинин|калинин'

$subdirs = @('common', 'events', 'history', 'localisation', 'interface')

$out = @()
$out += '==== SOP 第 0 步 · 米哈伊尔·加里宁（Idx 14）===='
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
    $h = @(Select-String -Path $p -Pattern 'kalinin|加里宁' -ErrorAction SilentlyContinue)
    $out += "  --- $rel （$($h.Count) 行）---"
    foreach ($x in $h) { $out += ('    {0}:  {1}' -f $x.LineNumber, $x.Line.Trim()) }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-kalinin.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

# SOP 第 0 步（续）：把 s0-smilga.txt 里的命中点展开成上下文
# 目的：判断原版把他做成了什么 —— 角色对象 / 领袖线 / 清洗名单 / 派系对齐 / 集团动作
$ErrorActionPreference = 'Continue'
$out = @()
$out += '==== 斯米尔加（Idx 10）· 命中点上下文 ===='
$out += ''

# 语法：路径;起始行;结束行;说明
$jobs = @(
    'F:\Hearts of Iron IV\common\characters\SOV.txt;2755;2805;原版 角色对象定义',
    'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt;36;50;原版 recruit_character',
    'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt;265;300;原版 角色初始化 A',
    'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt;330;350;原版 角色初始化 B',
    'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt;960;980;原版 清洗',
    'F:\Hearts of Iron IV\common\decisions\SOV.txt;16800;16850;原版 决议',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;7515;7550;原版 国策 A',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;8735;8760;原版 派系对齐',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;10005;10030;原版 潜在目标',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;10380;10400;原版 retire',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;11490;11545;原版 释放',
    'F:\Hearts of Iron IV\common\country_leader\00_traits.txt;7965;8000;原版 特质',
    'F:\Hearts of Iron IV\common\scripted_triggers\00_scripted_triggers_FR_loc.txt;825;850;原版 FR 触发器',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet_old.txt;8725;8760;R56 旧版国策',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\characters\SOV.txt;4560;4600;R56 角色对象定义',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\history\countries\SOV - Soviet union.txt;480;500;R56 角色初始化 A',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\history\countries\SOV - Soviet union.txt;558;575;R56 角色初始化 B'
)

foreach ($j in $jobs) {
    $p, $a, $b, $why = $j -split ';'
    $out += "==================== $why ===================="
    $out += "  $p  ($a-$b)"
    if (-not (Test-Path $p)) { $out += '  [文件不存在]'; $out += ''; continue }
    $L = [System.IO.File]::ReadAllLines($p)
    $a = [int]$a; $b = [int]$b
    if ($b -gt $L.Count) { $b = $L.Count }
    for ($i = $a; $i -le $b; $i++) {
        $out += ('  {0,6}: {1}' -f $i, $L[$i - 1].TrimEnd())
    }
    $out += ''
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-smilga-ctx.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

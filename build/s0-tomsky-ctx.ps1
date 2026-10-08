# SOP 第 0 步（续）：把 s0-tomsky.txt 里的命中点展开成上下文
$ErrorActionPreference = 'Continue'
$out = @()
$out += '==== 托姆斯基（Idx 11）· 命中点上下文 ===='
$out += ''

$jobs = @(
    'F:\Hearts of Iron IV\common\characters\SOV.txt;3138;3200;原版 角色对象定义',
    'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt;46;54;原版 recruit_character',
    'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt;284;302;原版 角色初始化（派系对齐）',
    'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt;978;994;原版 清洗',
    'F:\Hearts of Iron IV\common\decisions\SOV.txt;17190;17225;原版 决议',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;7905;7940;原版 国策 A（用他）',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;8820;8845;原版 潜在目标',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;9215;9245;原版 retire',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;9865;9895;原版 show_ideas_tooltip',
    'F:\Hearts of Iron IV\common\national_focus\soviet.txt;10635;10680;原版 has_idea / 角色立绘切换',
    'F:\Hearts of Iron IV\common\country_leader\00_traits.txt;8025;8070;原版 专属特质（Default / Improved）',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\characters\SOV.txt;5015;5075;R56 角色对象定义',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\country_leader\00_traits.txt;8035;8065;R56 专属特质',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet.txt;9370;9400;R56 国策 A',
    'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet.txt;12815;12845;R56 角色立绘切换'
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

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-tomsky-ctx.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

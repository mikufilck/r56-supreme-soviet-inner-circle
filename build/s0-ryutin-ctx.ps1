# SOP 第 0 步（续）：命中点上下文展开
# 目标人物：马尔特米扬·里亚京（Idx 12）—— 工具蓝本 build/s0-tomsky-ctx.ps1
$ErrorActionPreference = 'Continue'

$specs = @(
    # ---- 原版 ----
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';      From = 11395; To = 11475; Why = '⭐ SOV_liberate_ryutin 完整国策块（原版为他专门做的）' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';      From = 7545;  To = 7600;  Why = '#Ryutin 国策（第一个）' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';      From = 9225;  To = 9245;  Why = 'retire_character 清洗线' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\characters\SOV.txt';             From = 3360;  To = 3420;  Why = '⭐ 完整角色对象 SOV_martemyan_ryutin' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\country_leader\00_traits.txt';   From = 8060;  To = 8110;  Why = '⭐ #Ryutin 特质' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\decisions\SOV.txt';              From = 16845; To = 16900; Why = '#Ryutin 决策' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt'; From = 340; To = 375;  Why = '历史角色块' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt'; From = 960; To = 985;  Why = '第 973 行 purge' },
    # ---- R56 ----
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet.txt'; From = 13575; To = 13655; Why = '⭐ R56 的 SOV_liberate_ryutin' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet.txt'; From = 8965;  To = 9010;  Why = '#Ryutin 国策（R56）' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\characters\SOV.txt';        From = 5245;  To = 5305;  Why = '⭐ R56 角色对象' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\country_leader\00_traits.txt'; From = 8065; To = 8115; Why = '#Ryutin 特质（R56）' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\decisions\SOV.txt';         From = 17515; To = 17570; Why = '#Ryutin 决策（R56）' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\history\countries\SOV - Soviet union.txt'; From = 565; To = 600; Why = '历史角色块（R56）' }
)

$out = @()
$out += '==== 第 0 步上下文展开 · 里亚京（Idx 12）===='
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

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-ryutin-ctx.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

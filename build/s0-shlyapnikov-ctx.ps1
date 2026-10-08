# SOP 第 0 步（续）：命中点上下文展开
# 目标人物：施利亚普尼科夫（Idx 13）—— 工具蓝本 build/s0-ryutin-ctx.ps1
$ErrorActionPreference = 'Continue'

$specs = @(
    # ---- 原版 ----
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\characters\SOV.txt';            From = 2955; To = 3020; Why = '⭐ 完整角色对象 SOV_aleksandr_shlyapnikov' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\country_leader\00_traits.txt';  From = 7990; To = 8040; Why = '⭐⭐ 专属特质 #Shlyapnikov' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';     From = 11475; To = 11560; Why = '⭐⭐ 疑似为他专门做的国策（11513-11536）' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';     From = 8725;  To = 8780;  Why = '「Already set as aligned to left oppo」' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';     From = 7275;  To = 7305;  Why = '第二次莫斯科审判目标' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\national_focus\soviet.txt';     From = 10380; To = 10405; Why = 'retire = yes' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\decisions\SOV.txt';             From = 16730; To = 16775; Why = '#Shlyapnikov 决策' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt'; From = 275; To = 300;  Why = '历史角色块 284' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt'; From = 330; To = 350;  Why = '在押 flag 342' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\history\countries\SOV - Soviet union.txt'; From = 960; To = 975;  Why = 'purge 969' },
    @{ Tag = '原版'; File = 'F:\Hearts of Iron IV\common\scripted_triggers\00_scripted_triggers_FR_loc.txt'; From = 825; To = 855; Why = '⚠️ 奇怪的 FR_loc 引用' },
    # ---- R56 ----
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\characters\SOV.txt';        From = 4805;  To = 4870;  Why = '⭐ R56 角色对象' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\country_leader\00_traits.txt'; From = 7995; To = 8045; Why = '专属特质（R56）' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet.txt'; From = 13660; To = 13700; Why = 'R56 引用处' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\common\national_focus\soviet_old.txt'; From = 8735; To = 8765; Why = '⭐ R56-old「stupid trait so actually hidden」' },
    @{ Tag = 'R56';  File = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125\history\countries\SOV - Soviet union.txt'; From = 555; To = 580; Why = 'R56 在押块' }
)

$out = @()
$out += '==== 第 0 步上下文展开 · 施利亚普尼科夫（Idx 13）===='
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

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 's0-shlyapnikov-ctx.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成，输出 ' + $out.Count + ' 行')

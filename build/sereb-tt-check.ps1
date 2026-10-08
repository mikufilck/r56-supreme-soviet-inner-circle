# 谢列布里亚科夫个人线 —— 候选修正词条的 *_tt 键实测
# 蓝本：build/smirnov-tt-check.txt 的做法（扫官方 simp_chinese 本地化）
# 🚩 目的：国策数值只用【官方确实有 tooltip 键】的词条，否则玩家看到的是裸键
$ErrorActionPreference = 'Continue'

$locDir = 'F:\Hearts of Iron IV\localisation\simp_chinese'
$mods = @(
    'army_morale_factor',
    'war_support_factor',
    'stability_factor',
    'political_power_factor',
    'production_speed_buildings_factor',
    'mobilization_speed',
    'research_speed_factor',
    'production_factory_max_efficiency_factor',
    'drift_defence_factor',
    'industrial_capacity_factory',
    'army_org_factor',
    'conscription'
)

$files = @(Get-ChildItem -LiteralPath $locDir -Recurse -File -Filter '*.yml' -ErrorAction SilentlyContinue |
           Select-Object -ExpandProperty FullName)
$out = @()
$out += ('扫描目录：' + $locDir)
$out += ('yml 文件数：' + $files.Count)
$out += ''
$out += ('{0,-46} {1,-6} {2}' -f '修饰词条', '有_tt', '出处文件:行')
$out += ('-' * 96)

foreach ($m in $mods) {
    $key = $m + '_tt'
    # 只匹配【键定义】那种写法：行首（可含空白与引号）后跟键名与冒号
    $rx = '^\s*"?[a-zA-Z0-9_\.]*' + [regex]::Escape($key) + '"?\s*:'
    $hit = @(Select-String -Path $files -Pattern $rx -ErrorAction SilentlyContinue |
             Where-Object { $_.Line -match [regex]::Escape($key) })
    if ($hit.Count -gt 0) {
        $h0 = $hit[0]
        $src = (Split-Path -Leaf $h0.Path) + ':' + $h0.LineNumber
        $out += ('{0,-46} {1,-6} {2}' -f $m, 'OK', $src)
    } else {
        $out += ('{0,-46} {1,-6} {2}' -f $m, '**缺**', '需要自造本地化')
    }
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'sereb-tt-check.txt'), $out, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('完成 -> build/sereb-tt-check.txt  共 ' + $mods.Count + ' 个词条')

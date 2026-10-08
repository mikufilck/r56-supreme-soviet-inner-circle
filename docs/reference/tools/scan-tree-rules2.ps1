# scan-tree-rules2.ps1
# 目的：完整摊开「国策树选用」机制，得出「每个国家默认加载哪棵树、在哪个文件」。
#       这是决定我们必须复制哪些文件的唯一依据。
# 用法：powershell -NoProfile -File scan-tree-rules2.ps1

$ErrorActionPreference = 'Stop'
$root = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$ruleFile = Join-Path $root 'common\game_rules\00_game_rules.txt'
$actFile  = Join-Path $root 'common\on_actions\r56_focus_tree_selection_on_actions.txt'

$want = @('SOV','PRC','MON','FIN','SWE','NOR','DEN','ICE','AFG','SAU','PHI','CUB','ARG','ETH','FRA','POL','HUN')

$rl = [System.IO.File]::ReadAllLines($ruleFile)
$al = [System.IO.File]::ReadAllLines($actFile)

Write-Output "############ A. 游戏规则：完整块（含全部选项与 default）############"
foreach ($tag in $want) {
    $key = $tag + '_focus_tree_selection'
    $hit = -1
    for ($i = 0; $i -lt $rl.Count; $i++) {
        if ($rl[$i] -match ('^\s*' + $key + '\s*=')) { $hit = $i; break }
    }
    Write-Output ""
    if ($hit -lt 0) { Write-Output ("--- {0}: 无规则（纯 MTTH 决定）---" -f $tag); continue }

    Write-Output ("--- {0}  (L{1}) ---" -f $key, ($hit + 1))
    $depth = 0
    for ($j = $hit; $j -lt [Math]::Min($hit + 90, $rl.Count); $j++) {
        $depth += ([regex]::Matches($rl[$j], '\{').Count) - ([regex]::Matches($rl[$j], '\}').Count)
        Write-Output ("    " + $rl[$j].Trim())
        if ($depth -le 0) { break }
    }
}

Write-Output ""
Write-Output "############ B. on_action：规则选项 -> 实际加载的树 ############"
Write-Output "（找 <TAG>_focus_tree_selection 的每个引用，向后取 16 行以捕获 load_focus_tree）"
foreach ($tag in $want) {
    $key = $tag + '_focus_tree_selection'
    $hits = @()
    for ($i = 0; $i -lt $al.Count; $i++) {
        if ($al[$i] -match $key) { $hits += $i }
    }
    Write-Output ""
    Write-Output ("--- {0}: {1} 处引用 ---" -f $tag, $hits.Count)
    if ($hits.Count -eq 0) { Write-Output "    （R56 未接管，走 MTTH）"; continue }

    foreach ($h in $hits) {
        Write-Output ("    >> 引用处 L{0}" -f ($h + 1))
        $opt = ''
        # 先抓 option = XXX
        for ($j = $h; $j -lt [Math]::Min($h + 8, $al.Count); $j++) {
            if ($al[$j] -match 'option\s*=\s*([A-Z0-9_]+)') { $opt = $Matches[1]; break }
        }
        $tree = ''
        for ($j = $h; $j -lt [Math]::Min($h + 60, $al.Count); $j++) {
            if ($al[$j] -match 'load_focus_tree\s*=\s*([A-Za-z0-9_]+)') { $tree = $Matches[1]; break }
        }
        Write-Output ("       option = {0}   ->   load_focus_tree = {1}" -f $opt, $tree)
    }
}

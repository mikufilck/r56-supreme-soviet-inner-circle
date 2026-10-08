# scan-modifier-tt.ps1
# ---------------------------------------------------------------------------
# 两件事一起做：
#   A) 我们个人线用到的 39 个词条，是否存在官方的 `<词条>_tt` tooltip 本地化键
#      —— Germany 的写法是 add_to_variable = { <var> = <v> tooltip = <词条>_tt }
#         键不存在就会显示原始键名，所以必须先核实
#   B) 把德国席位容器的原文抠出来（第③步重排布局的基准）
#
# 产出（建议）：docs/reference/reports/modifier-tt.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'
$MOD  = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron'

# ---------- A) 取我们实际用到的词条名（从生成的 DM 文件读，最可靠） ----------
$dmFile = Join-Path $MOD 'common\dynamic_modifiers\hof_ic_trotsky_dm.txt'
$mods = @()
if (Test-Path $dmFile) {
    foreach ($line in [System.IO.File]::ReadAllLines($dmFile)) {
        if ($line -match '^\t\t([a-z_0-9]+)\s*=\s*hof_ic_lev_trotsky_') { $mods += $Matches[1] }
    }
}
Write-Output ("我们从 hof_ic_trotsky_dm.txt 读到 {0} 个词条" -f $mods.Count)
Write-Output ''

# 收集所有本地化键（vanilla + R56 + 我们）
$keys = @{}
foreach ($root in @($HOI4, $R56, $MOD)) {
    $p = Join-Path $root 'localisation'
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -File -Filter '*.yml' -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($line in [System.IO.File]::ReadAllLines($_.FullName)) {
            if ($line -match '^\s*([A-Za-z_0-9]+)\s*:\s*\d*\s*"') { $keys[$Matches[1]] = 1 }
        }
    }
}
Write-Output ("本地化键总数（三处合计去重）：{0}" -f $keys.Count)
Write-Output ''

Write-Output '=== A) 词条 tooltip 键存在性 ==='
Write-Output ("{0,-58} {1,-8} {2,-8} {3}" -f '词条', '_tt 键', '裸键', '结论')
Write-Output ('-' * 100)
$haveTt = 0
$noTt = New-Object System.Collections.Generic.List[string]
foreach ($m in ($mods | Sort-Object -Unique)) {
    $tt = $m + '_tt'
    $k1 = $keys.ContainsKey($tt)
    $k2 = $keys.ContainsKey($m)
    if ($k1) { $haveTt++ ; $verdict = '有 _tt，直接可用' }
    elseif ($k2) { $verdict = '只有裸键（也许能当 tooltip 用，需实测）'; $noTt.Add($m) }
    else { $verdict = '两个都没有 —— 要自己写本地化'; $noTt.Add($m) }
    Write-Output ("{0,-58} {1,-8} {2,-8} {3}" -f $m, $k1, $k2, $verdict)
}
Write-Output ''
Write-Output ("小结：有 `<词条>_tt` 的 {0} 个 / 共 {1} 个" -f $haveTt, ($mods | Sort-Object -Unique).Count)

# ---------- B) 德国席位容器原文 ----------
Write-Output ''
Write-Output '################################################################################'
Write-Output '# B) 德国席位容器原文（第③步重排布局的基准）'
Write-Output '################################################################################'
$ger = Join-Path $HOI4 'interface\GER_inner_circle_scripted_gui.gui'
if (Test-Path $ger) {
    $ls = [System.IO.File]::ReadAllLines($ger)
    $hits = 0
    for ($i = 0; $i -lt $ls.Count; $i++) {
        if ($ls[$i] -match '@ASCENDED_ADVISOR_CONTAINER_POS_Y|@ASCENDED_ADVISOR_CONTAINER_WIDTH' -and $ls[$i] -notmatch '^\s*@') {
            # 往上找 containerWindowType 起点，打印整块
            $s = $i
            while ($s -gt 0 -and $ls[$s] -notmatch 'containerWindowType\s*=\s*\{') { $s-- }
            Write-Output ''
            Write-Output ("--- L{0} 起 ---" -f ($s + 1))
            $depth = 0
            for ($j = $s; $j -lt $ls.Count; $j++) {
                Write-Output $ls[$j]
                $depth += ([regex]::Matches($ls[$j], '\{')).Count - ([regex]::Matches($ls[$j], '\}')).Count
                if ($j -gt $s -and $depth -le 0) { break }
            }
            $hits++
            if ($hits -ge 2) { break }
        }
    }
    if ($hits -eq 0) {
        Write-Output '  （没找到用 @ASCENDED_ADVISOR_CONTAINER_* 的容器，改为搜 ascended_advisor 名字）'
        for ($i = 0; $i -lt $ls.Count; $i++) {
            if ($ls[$i] -match 'name\s*=\s*"[^"]*ascended') { Write-Output ("  L{0}: {1}" -f ($i + 1), $ls[$i].Trim()) }
        }
    }
} else {
    Write-Output '  （找不到德国 GUI）'
}

# scan-idea-tags.ps1
# ---------------------------------------------------------------------------
# 核实 idea 的【正确外层结构】：
#   1. common/idea_tags/ 里定义了哪些 category，hidden_ideas 是什么
#   2. hidden_ideas 的原文块
#   3. 对照：德国职务 idea 的外层 = ideas = { hidden_ideas = { ... } }
#
# 产出（建议）：docs/reference/reports/idea-tags.txt
# ---------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

$HOI4 = 'F:\Hearts of Iron IV'
$R56  = 'D:\Program Files (x86)\Steam\steamapps\workshop\content\394360\2129897125'

foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    $p = Join-Path $root 'common\idea_tags'
    Write-Output ''
    Write-Output ('=' * 90)
    Write-Output ("### [{0}] {1}" -f $label, $p)
    Write-Output ('=' * 90)
    if (-not (Test-Path $p)) { Write-Output '  （目录不存在）'; continue }
    Get-ChildItem $p -Recurse -File | ForEach-Object {
        Write-Output ("  · {0}" -f $_.Name)
    }
    Write-Output ''
    Write-Output '  --- 各文件里 category 名（缩进 1 个 Tab 的块头）---'
    Get-ChildItem $p -Recurse -File -Filter *.txt | ForEach-Object {
        $f = $_.FullName
        $lines = [System.IO.File]::ReadAllLines($f)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\t([A-Za-z_0-9]+)\s*=\s*\{') {
                Write-Output ("    {0,-40} L{1}  [{2}]" -f $Matches[1], ($i + 1), (Split-Path $f -Leaf))
            }
        }
    }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# hidden_ideas 原文块'
Write-Output '################################################################################'
foreach ($root in @($HOI4, $R56)) {
    $label = '原版'
    if ($root -eq $R56) { $label = 'R56' }
    $p = Join-Path $root 'common\idea_tags'
    if (-not (Test-Path $p)) { continue }
    Get-ChildItem $p -Recurse -File -Filter *.txt | ForEach-Object {
        $f = $_.FullName
        $lines = [System.IO.File]::ReadAllLines($f)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*hidden_ideas\s*=\s*\{\s*$') {
                Write-Output ''
                Write-Output ("--- [{0}] {1}  L{2}" -f $label, (Split-Path $f -Leaf), ($i + 1))
                $depth = 0
                for ($j = $i; $j -lt $lines.Count; $j++) {
                    Write-Output ('    ' + $lines[$j])
                    $depth += ([regex]::Matches($lines[$j], '\{')).Count - ([regex]::Matches($lines[$j], '\}')).Count
                    if ($j -gt $i -and $depth -le 0) { break }
                }
            }
        }
    }
}

Write-Output ''
Write-Output '################################################################################'
Write-Output '# 我自己 mod 的 idea 文件外层结构（检查有没有 ideas/{category} 包裹）'
Write-Output '################################################################################'
$mine = 'D:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\ideas\hof_ic_ideas.txt'
if (Test-Path $mine) {
    $lines = [System.IO.File]::ReadAllLines($mine)
    Write-Output ("  总行数 {0}" -f $lines.Count)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^(\t*)ideas\s*=\s*\{') { Write-Output ("  L{0}: {1}" -f ($i + 1), $lines[$i]) }
        if ($lines[$i] -match '^(\t*)([A-Za-z_0-9]+)\s*=\s*\{\s*$') {
            $ind = $Matches[1].Length
            if ($ind -le 1) { Write-Output ("  L{0} 缩进{1}: {2}" -f ($i + 1), $ind, $lines[$i].Trim()) }
        }
    }
} else {
    Write-Output '  （没找到 hof_ic_ideas.txt）'
}

# 核对新增文件的编码红线 + 括号配平
$ErrorActionPreference = 'Stop'

function Show-Enc([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Output "  ❌ 不存在: $p"; return }
    $b = [System.IO.File]::ReadAllBytes($p)
    $hasBom = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
    $txt = [System.IO.File]::ReadAllText($p)
    $open = ([regex]::Matches($txt, '\{')).Count
    $close = ([regex]::Matches($txt, '\}')).Count
    $name = Split-Path $p -Leaf
    Write-Output ("  {0,-38} BOM={1,-5} 行={2,-5} {{={3} }}={4} {5}" -f `
        $name, $hasBom, ([System.IO.File]::ReadAllLines($p)).Count, $open, $close,
        $(if ($open -eq $close) { 'OK' } else { '括号不平衡!' }))
}

Write-Output '===== 脚本 .txt（必须【无】BOM）====='
Show-Enc 'd:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\unit_leader\hof_ic_traits.txt'
Show-Enc 'd:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\common\opinion_modifiers\hof_ic_opinion_modifiers.txt'

Write-Output ''
Write-Output '===== 本地化 .yml（必须【有】BOM，且首行正确）====='
$yml = 'd:\Users\xuwei\PycharmProjects\heart_of_Iron\mod\heart_of_iron\localisation\simp_chinese\hof_ic_l_simp_chinese.yml'
Show-Enc $yml
$l1 = ([System.IO.File]::ReadAllLines($yml))[0]
Write-Output ("  首行: '{0}'  {1}" -f $l1, $(if ($l1 -eq 'l_simp_chinese:') { 'OK' } else { '❌ 应为 l_simp_chinese:' }))

Write-Output ''
Write-Output '===== 新加的本地化键是否就位 ====='
foreach ($k in @('trait_hof_ic_tsarist_officer', 'trait_hof_ic_tsarist_officer_desc', 'hof_ic_chinese_question')) {
    $t = [System.IO.File]::ReadAllText($yml)
    Write-Output ("  {0,-40} {1}" -f $k, $(if ($t.Contains($k + ':')) { 'OK' } else { '❌ 缺失' }))
}

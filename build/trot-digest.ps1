# 按关键词从已抓文本里抽出【可引段落】，一次性汇总成摘要文件
$ErrorActionPreference = 'Continue'
$txtDir = Join-Path $PSScriptRoot '..\tmp\trotsky\txt'

# key -> 关键词正则（只抽含这些词的段落）
$spec = [ordered]@{
    'ii2_permrev_review_60'        = '不断革命'
    'ii3_one_country_59'           = '一国|社会主义可能|建成社会主义'
    'iii1_last_stage_1929book44'   = '新方针|党内民主|派别|官僚'
    'ii3_bureaucratic_legend_58'   = '官僚'
    'iv1_nep_phase_1929book40'     = '新经济政策|市场|余粮|粮食税'
    'iv1_econ_theses_192512'       = '市场|新经济政策|计划'
    'v1_comintern_1921b'           = '我们向|任务|宣言'
    'v2_class_relations_01b'       = '国民党|工人阶级|土地革命|退出'
    'v3_workers_arms_10'           = '法西斯|武装|统一战线|工人'
    'e_october_lessons_1929book30' = '红军|军队|军事|起义'
}

$out = @()
foreach ($k in $spec.Keys) {
    $p = Join-Path $txtDir "$k.txt"
    if (-not (Test-Path $p)) { $out += "===== $k : 缺文件"; continue }
    $t = [System.IO.File]::ReadAllText($p)
    $paras = $t -split "(\r?\n){2,}" | Where-Object { $_.Trim().Length -gt 40 }
    $hits = @()
    $budget = 1400
    foreach ($para in $paras) {
        $clean = ($para -replace '\s+', ' ').Trim()
        if ($clean -match $spec[$k]) {
            if ($budget -le 0) { break }
            $take = [Math]::Min($clean.Length, 420)
            $snippet = $clean.Substring(0, $take)
            $hits += ('  * ' + $snippet)
            $budget -= $take
        }
    }
    $out += "===== $k （命中 $($hits.Count) 段）====="
    $out += $hits
    $out += ''
}
$out | Out-File -LiteralPath (Join-Path $PSScriptRoot 'trot-digest.txt') -Encoding utf8

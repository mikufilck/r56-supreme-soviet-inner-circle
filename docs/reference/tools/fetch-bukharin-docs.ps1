# fetch-bukharin-docs.ps1
# 下载布哈林关键文章 → GB18030 解码 → 去 HTML 标签 → 存 UTF-8 纯文本
# 目的：补齐 docs/25「待核实清单」+ 给国策描述提供**原文节选**
#
# ⚠️ 两个坑（都踩过）：
#   ① PS5.1 的 Invoke-WebRequest 因 TLS 失败 → 用 curl.exe **数组传参**
#   ② marxists.org/chinese 页面是 **GB 系编码**，用 UTF-8 读会全乱 → GB18030 解码
#   ③ 控制台管道中文必乱 → 一律 `[System.IO.File]::WriteAllText` 直接落盘
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$base = 'https://www.marxists.org/chinese/bukharin/'
$root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\tmp\bukharin'))
$htmlDir = Join-Path $root 'html'
$txtDir  = Join-Path $root 'txt'
foreach ($d in @($root, $htmlDir, $txtDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# 键 = 本地短名，值 = 远端文件名（+ 用途备注）
$docs = [ordered]@{
    '19250424' = @('mia-chinese-bukhrin-19250424.htm', '我党在农民政策方面的新任务 —— 「发财吧」出处')
    '1925econ' = @('mia-chinese-bukhrin-1925.htm',     '对反对派经济纲领的批判 —— 反超高速工业化')
    '1924b'    = @('mia-chinese-bukhrin-1924b.htm',    '苏维埃经济的新发现或如何毁灭工农联盟 —— 驳托洛茨基主义经济论据')
    '19280710' = @('mia-chinese-bukhrin-19280710.htm', '1928 年七月中央全会发言 —— 与斯大林决裂')
    '19251219' = @('mia-chinese-bukhrin-19251219.htm', '第十四次代表大会发言（摘录）—— 一国建成社会主义')
    '19250225' = @('mia-chinese-bukhrin-19250225.htm', '农民土地问题的意义')
    '19210806' = @('mia-chinese-bukhrin-19210806.htm', '经济政策的新方针（1921）—— NEP 起点')
    '19290418' = @('mia-chinese-bukhrin-19290418.htm', '1929 年四月中央全会发言')
    'last1936' = @('mia-chinese-bukhrin-1936.htm',     '致未来一代党的领导人的信')
    'court1938'= @('mia-chinese-bukhrin-19380312.htm', '在法庭上的最后陈述')
}

$gb = [System.Text.Encoding]::GetEncoding('GB18030')
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Output ('{0,-10} {1,-10} {2,-10} {3}' -f '键', 'HTML', 'TXT', '说明')
Write-Output ('-' * 100)

foreach ($k in $docs.Keys) {
    $remote = $docs[$k][0]
    $note   = $docs[$k][1]
    $hf = Join-Path $htmlDir ($k + '.htm')
    $tf = Join-Path $txtDir  ($k + '.txt')

    if (-not (Test-Path $hf) -or (Get-Item $hf).Length -lt 2000) {
        if (Test-Path $hf) { [System.IO.File]::Delete($hf) }
        $a = @('-s','-L','--max-time','50','--compressed',
               '-A','Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
               '-o',$hf,($base + $remote))
        & curl.exe @a
    }

    if (-not (Test-Path $hf)) {
        Write-Output ('{0,-10} 下载失败' -f $k)
        continue
    }

    $h = [System.IO.File]::ReadAllText($hf, $gb)
    # 去 script/style/注释
    $h = $h -replace '(?s)<script.*?</script>', ' '
    $h = $h -replace '(?s)<style.*?</style>', ' '
    $h = $h -replace '(?s)<!--.*?-->', ' '
    # 段落/换行标记 -> 真换行
    $h = $h -replace '(?i)</p\s*>', "`r`n"
    $h = $h -replace '(?i)<br\s*/?\s*>', "`r`n"
    $h = $h -replace '(?i)</div\s*>', "`r`n"
    $h = $h -replace '(?i)</h[1-6]\s*>', "`r`n"
    # 去剩余标签
    $h = $h -replace '(?s)<[^>]+>', ' '
    # 实体
    $h = $h -replace '&nbsp;|&#160;', ' '
    $h = $h -replace '&amp;', '&'
    $h = $h -replace '&lt;', '<'
    $h = $h -replace '&gt;', '>'
    $h = $h -replace '&quot;', '"'
    # 压缩空白（保留换行）
    $h = $h -replace '[ \t]+', ' '
    $h = $h -replace '(\r?\n){3,}', "`r`n`r`n"
    $h = $h.Trim()

    [System.IO.File]::WriteAllText($tf, $h, $utf8)
    Write-Output ('{0,-10} {1,-10} {2,-10} {3}' -f `
        $k, (Get-Item $hf).Length, (Get-Item $tf).Length, $note)
}

Write-Output ''
Write-Output ('输出目录：' + $txtDir)

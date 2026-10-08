# 谢列布里亚科夫 第 2 轮勘查
#  📌 记忆里的教训：查「历任 / 首任 / 任期」这类事实 → 去查【机构】条目，别查人物条目
#  目标：
#   ① ru〈中央书记处〉      —— 核 1920-04-05 ~ 1921-03-08 的「三书记」说法
#   ② ru〈交通人民委员部〉  —— 核 НКПС 历任（1920-21 是不是托洛茨基、他是不是【副】人民委员）
#   ③ ru〈第二次莫斯科审判〉—— 补判决/指控的准确日期
#   ④ ru 搜「Зоря Серебрякова」—— 女儿回忆录（「列宁称我的父亲为天才的工人」）
#   ⑤ zh 搜「谢列布里亚科夫」—— docs/24 说 404，复核并看有没有可用的中文表述
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\sereb\wiki2'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$script:log = @()

function Curl-To {
    param([string]$Url, [string]$File)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $File -w '%{http_code}' $Url 2>$null
    $l = if (Test-Path -LiteralPath $File) { (Get-Item -LiteralPath $File).Length } else { 0 }
    return @{ Code = "$c"; Len = $l }
}

function Wiki-Extract {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $r  = Curl-To -Url $u -File $jf
    if ($r.Code -ne '200' -or $r.Len -lt 200) { $script:log += ('    [{0}] HTTP {1} {2:N0}B 取不到' -f $Tag, $r.Code, $r.Len); return $null }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            if ($p.Value.extract) {
                [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                $script:log += ('    [{0}] OK  {1:N0} 字符  条目 = {2}' -f $Tag, $p.Value.extract.Length, $p.Value.title)
                return $p.Value.title
            }
        }
        $script:log += ('    [{0}] 条目存在但无内容' -f $Tag)
    } catch { $script:log += ('    [{0}] JSON 失败：{1}' -f $Tag, $_.Exception.Message) }
    return $null
}

function Wiki-Search-Top {
    param([string]$Lang, [string]$Query, [string]$Tag)
    $sf = Join-Path $outDir ($Tag + '-search.json')
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=8&srsearch=" +
          [uri]::EscapeDataString($Query)
    $r  = Curl-To -Url $u -File $sf
    if ($r.Len -lt 50) { $script:log += ('    [{0}] search 无结果 (HTTP {1})' -f $Tag, $r.Code); return $null }
    try {
        $j = [System.IO.File]::ReadAllText($sf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        $titles = @()
        foreach ($s in $j.query.search) { $titles += $s.title }
        $script:log += ('    [{0}] 命中：{1}' -f $Tag, ($titles -join ' | '))
        if ($titles.Count -gt 0) { return $titles[0] }
    } catch { $script:log += ('    [{0}] search JSON 失败：{1}' -f $Tag, $_.Exception.Message) }
    return $null
}

# ①..④ ru 条目（先搜再取，稳妥）
$targets = @(
    @{ Lang = 'ru'; Query = 'Секретариат ЦК КПСС';                    Tag = 'ru_secretariat' },
    @{ Lang = 'ru'; Query = 'Народный комиссариат путей сообщения';   Tag = 'ru_nkps' },
    @{ Lang = 'ru'; Query = 'Второй московский процесс';              Tag = 'ru_trial2' },
    @{ Lang = 'ru'; Query = 'Зоря Серебрякова дочь Троцкий';          Tag = 'ru_zorya' }
)
foreach ($t in $targets) {
    $script:log += ('=== {0}  <- 搜 {1}' -f $t.Tag, $t.Query)
    $title = Wiki-Search-Top -Lang $t.Lang -Query $t.Query -Tag $t.Tag
    if ($title) { $null = Wiki-Extract -Lang $t.Lang -Title $title -Tag $t.Tag }
}

# ⑤ zh 维基
$script:log += '=== zh 搜「谢列布里亚科夫」'
$title = Wiki-Search-Top -Lang 'zh' -Query '谢列布里亚科夫' -Tag 'zh_sereb'
if ($title) { $null = Wiki-Extract -Lang 'zh' -Title $title -Tag 'zh_sereb' }
$script:log += '=== zh 搜「莫斯科审判」'
$title = Wiki-Search-Top -Lang 'zh' -Query '莫斯科审判 1937' -Tag 'zh_trial'
if ($title) { $null = Wiki-Extract -Lang 'zh' -Title $title -Tag 'zh_trial' }

$all = @('=== 谢列布里亚科夫 第 2 轮勘查报告 ===') + $script:log
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-sereb2-report.txt'), $all, (New-Object System.Text.UTF8Encoding($false)))
Write-Host '报告 -> fetch-sereb2-report.txt'

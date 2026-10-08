# 斯米尔加（Idx 10）材料抓取 · 第 8 批 —— 最后两处事实核实
#  ① 〈Центробалт〉—— en 维基左翼反对派条目说他是 Tsentrobalt 主席（1917-1918）
#  ② 〈Гельсингфорсский совет〉/〈Финляндия〉—— 1917 芬兰区域委员会
#  ③ 〈Московский институт народного хозяйства〉的院长名单（确认 1924-1927 是他）
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smilga\src'
$script:log = @()

function Wiki-Extract {
    param([string]$Lang, [string]$Title, [string]$Tag)
    $u  = "https://$($Lang).wikipedia.org/w/api.php?action=query&prop=extracts&explaintext=1&format=json&redirects=1&titles=" +
          [uri]::EscapeDataString($Title)
    $jf = Join-Path $outDir ($Tag + '.json')
    $c  = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $jf -w '%{http_code}' $u 2>$null
    $script:log += ('  [{0}] HTTP {1}  <- {2}' -f $Tag, $c, $Title)
    if ("$c" -ne '200') { return }
    try {
        $j = [System.IO.File]::ReadAllText($jf, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        foreach ($p in $j.query.pages.PSObject.Properties) {
            if ($p.Value.extract) {
                [System.IO.File]::WriteAllText((Join-Path $outDir ($Tag + '.txt')), $p.Value.extract, (New-Object System.Text.UTF8Encoding($false)))
                $n = ([regex]::Matches($p.Value.extract, 'Смилга')).Count
                $script:log += ('      -> {0}.txt  {1:N0} 字符  斯米尔加 x{2}   条目 = {3}' -f $Tag, $p.Value.extract.Length, $n, $p.Value.title)
            } else { $script:log += '      条目存在但 extract 为空' }
        }
    } catch { $script:log += ('      JSON 解析失败：' + $_.Exception.Message) }
}

$script:log += '=== 事实核实 ==='
Wiki-Extract -Lang 'ru' -Title 'Центробалт'                                    -Tag 'inst-tsentrobalt'
Wiki-Extract -Lang 'ru' -Title 'Финляндский областной комитет'                  -Tag 'inst-finobl'
Wiki-Extract -Lang 'ru' -Title 'Московский институт народного хозяйства'        -Tag 'inst-minh2'
Wiki-Extract -Lang 'ru' -Title 'Гельсингфорсский совет депутатов армии, флота и рабочих' -Tag 'inst-gelsingfors'
Wiki-Extract -Lang 'ru' -Title 'Размещение производительных сил'                -Tag 'bg-rasmeshchenie'
Wiki-Extract -Lang 'en' -Title 'Tsentrobalt'                                    -Tag 'inst-tsentrobalt-en'

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga8-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

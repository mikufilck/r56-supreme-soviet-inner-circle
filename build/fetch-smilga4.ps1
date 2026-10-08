# 斯米尔加（Idx 10）材料抓取 · 第 4 批 —— 中文原文（中译本）
#  线索（来自 en 维基脚注）：
#   ① 托洛茨基《斯大林评传》vol.2（1919-07 六人革军委 / 1921 十大斯大林指控他）
#   ② 多伊彻《先知三部曲·被解除武装的先知》（1927-06 雅罗斯拉夫尔车站送行示威）
#   ③ 托洛茨基《俄国革命史》vol.3（1917 芬兰）
#  目标：中文马克思主义文库有没有这些书的中译本 -> 拿【中文原文】
$ErrorActionPreference = 'Continue'
$proxy  = 'http://127.0.0.1:7993'
$outDir = Join-Path $PSScriptRoot '..\tmp\smilga\src'
$null   = New-Item -ItemType Directory -Force -Path $outDir
$script:log = @()

function Curl-To {
    param([string]$Url, [string]$File)
    $c = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 90 -o $File -w '%{http_code}' $Url 2>$null
    $l = if (Test-Path -LiteralPath $File) { (Get-Item -LiteralPath $File).Length } else { 0 }
    return @{ Code = "$c"; Len = $l }
}

function Decode-Bytes {
    param([byte[]]$Bytes)
    try {
        $enc = [System.Text.Encoding]::GetEncoding('utf-8',
               [System.Text.EncoderFallback]::ExceptionFallback,
               [System.Text.DecoderFallback]::ExceptionFallback)
        return $enc.GetString($Bytes)
    } catch { return [System.Text.Encoding]::GetEncoding(936).GetString($Bytes) }
}

$script:log += '=== ① 中文马克思主义文库 · 各家索引 ==='
$probes = @(
    @{ U = 'https://www.marxists.org/chinese/trotsky/index.htm';      T = 'trotskyidx' },
    @{ U = 'https://www.marxists.org/chinese/deutscher/index.htm';    T = 'deutscheridx' },
    @{ U = 'https://www.marxists.org/chinese/trotsky/1940book/index.htm'; T = 'stalinbook' },
    @{ U = 'https://www.marxists.org/chinese/trotsky/1930book/index.htm'; T = 'revhist' }
)
foreach ($p in $probes) {
    $f = Join-Path $outDir ($p.T + '.html')
    $r = Curl-To -Url $p.U -File $f
    $script:log += ('  HTTP {0}  {1:N0} 字节  <- {2}' -f $r.Code, $r.Len, $p.U)
    if ($r.Code -eq '200' -and $r.Len -gt 500) {
        $txt = Decode-Bytes ([System.IO.File]::ReadAllBytes($f))
        [System.IO.File]::WriteAllText((Join-Path $outDir ($p.T + '.txt')), $txt, (New-Object System.Text.UTF8Encoding($false)))
        $script:log += ('      -> {0}.txt  {1:N0} 字符' -f $p.T, $txt.Length)
        # 命中「斯大林」「先知」「俄国革命史」相关链接
        $hits = @()
        foreach ($m in [regex]::Matches($txt, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+)"?[^>]*>(.*?)</a>')) {
            $t2 = ([regex]::Replace($m.Groups[2].Value, '<[^>]+>', '')).Trim()
            if ($t2 -match '斯大林|先知|俄国革命史|武装|被解除') { $hits += ('{0}  ->  {1}' -f $t2, $m.Groups[1].Value) }
        }
        if ($hits.Count -gt 0) {
            $script:log += ('      ⭐ 相关链接 {0} 条：' -f $hits.Count)
            foreach ($h in @($hits | Select-Object -First 25)) { $script:log += ('        ' + $h) }
        }
    }
}

$script:log += '=== ② 文库本站搜「斯米尔加」（若给了搜索入口）==='
$s = 'https://www.marxists.org/chinese/search.htm'
$f2 = Join-Path $outDir 'miasearch.html'
$r2 = Curl-To -Url $s -File $f2
$script:log += ('  HTTP {0}  {1:N0} 字节  <- {2}' -f $r2.Code, $r2.Len, $s)

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'fetch-smilga4-report.txt'), $script:log, (New-Object System.Text.UTF8Encoding($false)))
$script:log | ForEach-Object { Write-Host $_ }

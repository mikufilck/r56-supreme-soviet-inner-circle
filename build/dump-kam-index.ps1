# dump-kam-index.ps1 —— 把加米涅夫（中文马克思主义文库）索引页的正文与全部链接抽出来
# 用途：SOP 第 0 步「先探有没有他的篇目页」→ 确定他有哪些一手件可抓
# 🚩 三个已知坑（仓库记忆）：① 主 index 是 GB2312，子目录多为 UTF-8 → 自动探测
#                            ② 中文经控制台管道必乱 → 一律 WriteAllLines(UTF8 无 BOM) 落盘
#                            ③ TUN + 本地代理 → curl 必须显式 -x
$ErrorActionPreference = 'Continue'
$proxy = 'http://127.0.0.1:7993'
$dir   = Join-Path $PSScriptRoot '..\tmp\kamenev'
$null  = New-Item -ItemType Directory -Force -Path $dir

function Read-TextAuto([string]$path) {
    $b = [System.IO.File]::ReadAllBytes($path)
    try { $e = New-Object System.Text.UTF8Encoding($false, $true); return $e.GetString($b) }
    catch { return [System.Text.Encoding]::GetEncoding(936).GetString($b) }
}
function Convert-HtmlToText([string]$html) {
    $t = $html
    $t = [regex]::Replace($t, '(?is)<script.*?</script>', ''); $t = [regex]::Replace($t, '(?is)<style.*?</style>', '')
    $t = [regex]::Replace($t, '(?i)<br\s*/?>', "`n"); $t = [regex]::Replace($t, '(?i)</p>', "`n`n")
    $t = [regex]::Replace($t, '(?i)</h[1-6]>', "`n`n"); $t = [regex]::Replace($t, '(?i)</li>', "`n")
    $t = [regex]::Replace($t, '(?is)<[^>]+>', ''); $t = [System.Net.WebUtility]::HtmlDecode($t)
    $t = [regex]::Replace($t, '[ \t]+', ' '); return ([regex]::Replace($t, '(\r?\n){3,}', "`n`n")).Trim()
}

# 两个索引页都抓一遍（中文 index + 英文 archive）
$pages = [ordered]@{
    'cn' = 'https://www.marxists.org/chinese/kamenev/index.htm'
    'en' = 'https://www.marxists.org/archive/kamenev/index.htm'
}

$out = @()
foreach ($k in $pages.Keys) {
    $hp = Join-Path $dir ("$k-index.htm")
    if (-not (Test-Path -LiteralPath $hp)) {
        $code = & curl.exe -s -L -x $proxy -A 'Mozilla/5.0' --max-time 60 -o $hp -w '%{http_code}' $pages[$k] 2>$null
        $out += ("[$k] 下载 HTTP={0}  {1}" -f $code, $pages[$k])
    } else {
        $out += ("[$k] 已存在  {0}" -f $pages[$k])
    }
    if (-not (Test-Path -LiteralPath $hp)) { continue }
    $h = Read-TextAuto $hp
    $out += ''
    $out += ('=' * 90)
    $out += "[$k] 正文（$(($h.Length)) 字节 HTML）"
    $out += ('=' * 90)
    $out += (Convert-HtmlToText $h)
    $out += ''
    $out += "[$k] 全部链接："
    # 🚩 纯 href 抽取最稳（见仓库记忆：带 title 捕获的正则某些页只命中 1 条）
    $lr = [regex]::Matches($h, '(?i)<a\s+[^>]*href\s*=\s*"?([^"''\s>]+)"?')
    foreach ($m in $lr) { $out += ('   ' + $m.Groups[1].Value) }
    $out += ("   （共 {0} 条）" -f $lr.Count)
    $out += ''
}

[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'kam-index-dump.txt'), $out,
    (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("写出 build/kam-index-dump.txt  行数={0}" -f $out.Count)
